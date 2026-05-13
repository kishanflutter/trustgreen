import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] so the rest of the app
/// can swap implementations without touching every call site.
///
/// On Android we explicitly opt into `EncryptedSharedPreferences`
/// (AES-256, Android Keystore). On iOS the platform default backs the
/// values with Keychain `kSecAttrAccessibleAfterFirstUnlock`.
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
  static const String _kWalletsIndex = 'tg_wallets_index';

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
  }

  // ── Wallets ─────────────────────────────────────────────────────
  Future<bool> hasAnyWallet() async {
    final v = await _delegate.read(key: _kWalletsIndex);
    return v != null && v.isNotEmpty && v != '[]';
  }

  Future<String?> readWalletsIndex() => _delegate.read(key: _kWalletsIndex);
  Future<void> writeWalletsIndex(String json) =>
      _delegate.write(key: _kWalletsIndex, value: json);

  // ── Generic ─────────────────────────────────────────────────────
  Future<String?> read(String key) => _delegate.read(key: key);
  Future<void> write(String key, String value) =>
      _delegate.write(key: key, value: value);
  Future<void> delete(String key) => _delegate.delete(key: key);
}
