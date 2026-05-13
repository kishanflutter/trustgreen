import 'dart:math';

import '../auth/wallet_cipher.dart';
import '../storage/secure_storage.dart';
import 'hd_wallet.dart';
import 'wallet_models.dart';

/// CRUD over the multi-wallet store. All mutating methods accept the
/// caller's PIN so the encrypted blob can be created or re-read.
///
/// Storage layout (managed by [SecureStorage]):
///
/// ```
/// tg_wallets_index   = JSON list<WalletMeta>
/// tg_active_wallet   = wallet id
/// tg_wallet_<id>_blob = base64( WalletCipher.encrypt(secret, pin) )
/// ```
class WalletRepository {
  WalletRepository(this._storage);

  final SecureStorage _storage;

  /// Returns every wallet's metadata, ordered by creation date.
  Future<List<WalletMeta>> listWallets() async {
    final raw = await _storage.readWalletsIndex();
    return WalletMeta.listFromJsonString(raw);
  }

  /// id of the wallet the user last opened, or `null` if unset.
  Future<String?> activeWalletId() => _storage.readActiveWalletId();

  /// Convenience getter: meta for the currently active wallet, or
  /// `null` if none is set / it has been deleted.
  Future<WalletMeta?> activeWallet() async {
    final id = await _storage.readActiveWalletId();
    if (id == null) return null;
    final list = await listWallets();
    for (final w in list) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Persists [id] as the active wallet.
  Future<void> setActiveWallet(String id) =>
      _storage.writeActiveWalletId(id);

  /// Generates a fresh HD wallet of [length] words, derives its EVM
  /// address, encrypts the mnemonic with [pin], and stores both the
  /// metadata and the encrypted blob. Returns the new metadata.
  ///
  /// The newly created wallet becomes the active one if it is the
  /// first wallet on the device. Otherwise the active selection is
  /// left untouched.
  Future<WalletMeta> createWallet({
    required String name,
    required String mnemonic,
    required MnemonicLength length,
    required String pin,
  }) async {
    final hd = HdWallet.fromMnemonic(mnemonic);
    if (hd.length != length) {
      throw ArgumentError(
        'Mnemonic length (${hd.length.wordCount}) does not match '
        'declared length (${length.wordCount}).',
      );
    }
    final address = hd.evmAddress();
    final id = _newWalletId();
    final secret = WalletSecret(
      mnemonic: hd.mnemonic,
      mnemonicWordCount: hd.length.wordCount,
    );
    final blob = await WalletCipher.encrypt(
      plaintext: secret.encodeJson(),
      pin: pin,
    );

    // Read existing index BEFORE persisting anything so a failure
    // here doesn't leave an orphan blob on disk.
    final list = await listWallets();
    final resolvedName = name.trim().isEmpty
        ? _defaultWalletName(list.length)
        : name.trim();

    final meta = WalletMeta(
      id: id,
      name: resolvedName,
      addressEvm: address,
      createdAt: DateTime.now(),
      mnemonicWordCount: hd.length.wordCount,
    );
    list.add(meta);

    // Write the blob first (largest payload, more likely to fail
    // due to storage pressure), then the small index pointer.
    await _storage.writeWalletBlob(id, blob);
    try {
      await _storage.writeWalletsIndex(WalletMeta.listToJsonString(list));
    } catch (e) {
      // Index write failed — roll back the orphan blob so retries
      // start from a clean state.
      await _storage.deleteWalletBlob(id);
      rethrow;
    }

    if (list.length == 1) await _storage.writeActiveWalletId(id);
    return meta;
  }

  /// Convenience for `createWallet(mnemonic: HdWallet.generate(...))`.
  Future<({WalletMeta meta, String mnemonic})> createNewRandomWallet({
    required String name,
    required MnemonicLength length,
    required String pin,
  }) async {
    final hd = HdWallet.generate(length: length);
    final meta = await createWallet(
      name: name,
      mnemonic: hd.mnemonic,
      length: hd.length,
      pin: pin,
    );
    return (meta: meta, mnemonic: hd.mnemonic);
  }

  /// Returns the decrypted mnemonic for [walletId]. Returns `null`
  /// if the PIN is wrong or the blob is missing. Throws
  /// [WalletDecryptError] if the blob is structurally corrupt.
  Future<WalletSecret?> readSecret({
    required String walletId,
    required String pin,
  }) async {
    final blob = await _storage.readWalletBlob(walletId);
    if (blob == null) return null;
    final plain = await WalletCipher.decrypt(b64: blob, pin: pin);
    if (plain == null) return null;
    return WalletSecret.decodeJson(plain);
  }

  /// Renames a wallet by id. No-op if the id is unknown.
  Future<void> rename({required String id, required String name}) async {
    final list = await listWallets();
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == id) {
        list[i] = list[i].copyWith(name: name.trim());
        changed = true;
        break;
      }
    }
    if (changed) {
      await _storage.writeWalletsIndex(WalletMeta.listToJsonString(list));
    }
  }

  /// Deletes wallet [id]: its encrypted blob, its index entry, and
  /// any "active wallet" pointer that referred to it. If another
  /// wallet remains, the *first* one becomes active.
  Future<void> delete(String id) async {
    await _storage.deleteWalletBlob(id);
    final list = await listWallets();
    list.removeWhere((w) => w.id == id);
    await _storage.writeWalletsIndex(WalletMeta.listToJsonString(list));

    final active = await _storage.readActiveWalletId();
    if (active == id) {
      if (list.isEmpty) {
        await _storage.deleteActiveWalletId();
      } else {
        await _storage.writeActiveWalletId(list.first.id);
      }
    }
  }

  // ── internals ────────────────────────────────────────────────────
  static final Random _rng = Random.secure();

  String _newWalletId() {
    // 8 random hex chars + timestamp millis for uniqueness without
    // pulling in `uuid` for one identifier.
    const chars = '0123456789abcdef';
    final buf = StringBuffer('w_');
    for (var i = 0; i < 8; i++) {
      buf.write(chars[_rng.nextInt(16)]);
    }
    buf.write('_');
    buf.write(DateTime.now().millisecondsSinceEpoch.toRadixString(36));
    return buf.toString();
  }

  String _defaultWalletName(int existingCount) =>
      existingCount == 0 ? 'Main wallet' : 'Wallet ${existingCount + 1}';
}
