import 'dart:convert';
import 'dart:typed_data';

import '../storage/secure_storage.dart';
import 'crypto_utils.dart';

/// PIN hashing + verification. Uses pure-Dart PBKDF2-HMAC-SHA256 —
/// no third-party PIN packages. The same KDF is reused by
/// [WalletCipher] to derive the AES key that encrypts mnemonics
/// at rest.
class PinService {
  PinService(this._storage);

  final SecureStorage _storage;

  /// Work factor. 200 000 iterations gives ~150–250 ms on a typical
  /// mid-range device — high enough to slow brute force, low enough
  /// that a legitimate unlock feels instant.
  static const int iterations = 200000;

  /// 16-byte random salt per record.
  static const int _saltLength = 16;

  /// 32-byte PBKDF2 output → SHA-256-sized hash.
  static const int _hashLength = 32;

  /// PIN length policy. The numeric pad UI enforces this too.
  static const int minPinLength = 4;
  static const int maxPinLength = 8;
  static const int defaultPinLength = 6;

  Future<bool> hasPin() => _storage.hasPin();

  /// Hashes [pin] with a fresh random salt and persists both. Any
  /// previously stored PIN is overwritten.
  ///
  /// The 200 000-iter PBKDF2 hash runs in a background isolate via
  /// [CryptoUtils.pbkdf2HmacSha256Async] so the UI thread stays
  /// responsive during the ~500 ms – 2 s of work.
  Future<void> setPin(String pin) async {
    _assertValid(pin);
    final salt = CryptoUtils.randomBytes(_saltLength);
    final hash = await CryptoUtils.pbkdf2HmacSha256Async(
      password: _passwordBytes(pin),
      salt: salt,
      iterations: iterations,
      derivedKeyLength: _hashLength,
    );
    await _storage.writePinHash(
      CryptoUtils.toHex(hash),
      CryptoUtils.toHex(salt),
    );
  }

  /// Returns `true` iff [pin] matches the stored hash. Constant-time
  /// comparison so timing attacks reveal nothing. Runs PBKDF2 in a
  /// background isolate so the UI thread doesn't freeze during
  /// unlock.
  Future<bool> verifyPin(String pin) async {
    if (pin.isEmpty) return false;
    final stored = await _storage.readPinHash();
    final storedHashHex = stored.hash;
    final storedSaltHex = stored.salt;
    if (storedHashHex == null || storedSaltHex == null) return false;

    final salt = CryptoUtils.fromHex(storedSaltHex);
    final candidate = await CryptoUtils.pbkdf2HmacSha256Async(
      password: _passwordBytes(pin),
      salt: salt,
      iterations: iterations,
      derivedKeyLength: _hashLength,
    );
    final expected = CryptoUtils.fromHex(storedHashHex);
    return CryptoUtils.constantTimeEquals(candidate, expected);
  }

  /// Removes PIN credentials. Caller is responsible for deleting any
  /// wallets encrypted with the old PIN — they become unreadable
  /// after a reset.
  Future<void> resetPin() => _storage.deletePin();

  // ── internals ────────────────────────────────────────────────────
  Uint8List _passwordBytes(String pin) =>
      Uint8List.fromList(utf8.encode(pin));

  void _assertValid(String pin) {
    if (pin.length < minPinLength || pin.length > maxPinLength) {
      throw ArgumentError(
        'PIN must be between $minPinLength and $maxPinLength characters.',
      );
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw ArgumentError('PIN must contain digits only.');
    }
  }
}
