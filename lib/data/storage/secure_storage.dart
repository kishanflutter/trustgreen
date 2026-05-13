import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage].
///
/// On Android we explicitly opt into `EncryptedSharedPreferences`
/// (AES-256, Android Keystore). On iOS values are backed by Keychain
/// with `kSecAttrAccessibleAfterFirstUnlock` so the app can read
/// them after a device reboot once the user has unlocked.
///
/// PIN-protected payloads (the wallet mnemonics) get an *extra*
/// layer of encryption via [WalletCipher] on top of the platform
/// keystore — defence in depth, and a hard requirement so that the
/// secrets are useless without the user's PIN.
class SecureStorage {
  SecureStorage()
      : _delegate = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  final FlutterSecureStorage _delegate;

  // ── Keys ────────────────────────────────────────────────────────
  static const String _kPinHash = 'tg_pin_hash';
  static const String _kPinSalt = 'tg_pin_salt';
  static const String _kPinAttempts = 'tg_pin_attempts';
  static const String _kWalletsIndex = 'tg_wallets_index';
  static const String _kActiveWallet = 'tg_active_wallet';
  static String _walletBlobKey(String walletId) => 'tg_wallet_${walletId}_blob';

  // ── PIN ─────────────────────────────────────────────────────────
  Future<bool> hasPin() async {
    final h = await _delegate.read(key: _kPinHash);
    return h != null && h.isNotEmpty;
  }

  Future<void> writePinHash(String hash, String salt) async {
    await _delegate.write(key: _kPinHash, value: hash);
    await _delegate.write(key: _kPinSalt, value: salt);
  }

  Future<({String? hash, String? salt})> readPinHash() async {
    final hash = await _delegate.read(key: _kPinHash);
    final salt = await _delegate.read(key: _kPinSalt);
    return (hash: hash, salt: salt);
  }

  Future<void> deletePin() async {
    await _delegate.delete(key: _kPinHash);
    await _delegate.delete(key: _kPinSalt);
    await _delegate.delete(key: _kPinAttempts);
  }

  /// Failed-unlock counter. Reset on a successful unlock or on PIN
  /// re-set. The UI uses this to throttle / wipe after N failures.
  Future<int> readPinAttempts() async {
    final raw = await _delegate.read(key: _kPinAttempts);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> writePinAttempts(int value) async {
    await _delegate.write(key: _kPinAttempts, value: value.toString());
  }

  Future<void> resetPinAttempts() => _delegate.delete(key: _kPinAttempts);

  // ── Wallets ─────────────────────────────────────────────────────
  Future<bool> hasAnyWallet() async {
    final v = await _delegate.read(key: _kWalletsIndex);
    return v != null && v.isNotEmpty && v != '[]';
  }

  Future<String?> readWalletsIndex() => _delegate.read(key: _kWalletsIndex);
  Future<void> writeWalletsIndex(String json) =>
      _delegate.write(key: _kWalletsIndex, value: json);

  Future<String?> readActiveWalletId() => _delegate.read(key: _kActiveWallet);
  Future<void> writeActiveWalletId(String id) =>
      _delegate.write(key: _kActiveWallet, value: id);
  Future<void> deleteActiveWalletId() => _delegate.delete(key: _kActiveWallet);

  Future<String?> readWalletBlob(String walletId) =>
      _delegate.read(key: _walletBlobKey(walletId));
  Future<void> writeWalletBlob(String walletId, String blob) =>
      _delegate.write(key: _walletBlobKey(walletId), value: blob);
  Future<void> deleteWalletBlob(String walletId) =>
      _delegate.delete(key: _walletBlobKey(walletId));

  /// Wipes everything — PIN, attempts counter, wallet index, every
  /// per-wallet blob, and the active-wallet pointer. Used by
  /// "Reset wallet" in Settings (Phase 5) and as a panic button.
  Future<void> wipeAll() async {
    final indexRaw = await _delegate.read(key: _kWalletsIndex);
    if (indexRaw != null && indexRaw.isNotEmpty) {
      // Cheapest way to find the per-wallet keys without parsing JSON:
      // pull all entries and delete blob keys we recognise.
      final all = await _delegate.readAll();
      for (final key in all.keys) {
        if (key.startsWith('tg_wallet_') && key.endsWith('_blob')) {
          await _delegate.delete(key: key);
        }
      }
    }
    await _delegate.delete(key: _kWalletsIndex);
    await _delegate.delete(key: _kActiveWallet);
    await deletePin();
  }

  // ── Generic escape hatch ────────────────────────────────────────
  Future<String?> read(String key) => _delegate.read(key: key);
  Future<void> write(String key, String value) =>
      _delegate.write(key: key, value: value);
  Future<void> delete(String key) => _delegate.delete(key: key);
}
