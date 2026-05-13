import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/api.dart' as pc;
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';

import 'crypto_utils.dart';
import 'pin_service.dart';

/// Symmetric encryption for wallet secrets at rest.
///
/// Layout of the on-disk blob (base64-encoded as a single string):
///
/// ```
/// [ 1 byte version=1 ]
/// [ 16 bytes salt    ]
/// [ 12 bytes IV      ]
/// [ N bytes ciphertext + 16 bytes GCM auth tag ]
/// ```
///
/// The AES-256 key is derived from the user's PIN via the same
/// PBKDF2 parameters as [PinService] (200 000 iters,
/// HMAC-SHA-256). A wrong PIN produces an authentication-tag
/// mismatch and [decrypt] returns `null`.
class WalletCipher {
  WalletCipher._();

  static const int _version = 1;
  static const int _saltLength = 16;
  static const int _ivLength = 12;
  static const int _macBits = 128;
  static const int _keyLength = 32; // AES-256

  /// Encrypts [plaintext] with a freshly generated salt + IV.
  ///
  /// The PBKDF2 key-derivation step (200 000 iterations) runs in a
  /// background isolate so UI-thread callers don't freeze. AES-GCM
  /// on the small mnemonic payload finishes in milliseconds on the
  /// main isolate.
  static Future<String> encrypt({
    required String plaintext,
    required String pin,
  }) async {
    final salt = CryptoUtils.randomBytes(_saltLength);
    final iv = CryptoUtils.randomBytes(_ivLength);
    final key = await CryptoUtils.pbkdf2HmacSha256Async(
      password: Uint8List.fromList(utf8.encode(pin)),
      salt: salt,
      iterations: PinService.iterations,
      derivedKeyLength: _keyLength,
    );

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        pc.AEADParameters(pc.KeyParameter(key), _macBits, iv, Uint8List(0)),
      );
    final cipherAndTag =
        cipher.process(Uint8List.fromList(utf8.encode(plaintext)));

    final out = Uint8List(1 + _saltLength + _ivLength + cipherAndTag.length);
    out[0] = _version;
    out.setRange(1, 1 + _saltLength, salt);
    out.setRange(1 + _saltLength, 1 + _saltLength + _ivLength, iv);
    out.setRange(1 + _saltLength + _ivLength, out.length, cipherAndTag);
    return base64Encode(out);
  }

  /// Decrypts a blob produced by [encrypt]. Returns `null` if the
  /// PIN is wrong, the blob is corrupt, or the version is unknown —
  /// callers must distinguish the cases via the [WalletDecryptError]
  /// thrown for non-recoverable corruption. The expensive
  /// key-derivation step runs in a background isolate.
  static Future<String?> decrypt({
    required String b64,
    required String pin,
  }) async {
    final Uint8List combined;
    try {
      combined = base64Decode(b64);
    } on FormatException {
      throw const WalletDecryptError('Blob is not valid base64.');
    }

    if (combined.isEmpty) {
      throw const WalletDecryptError('Blob is empty.');
    }
    if (combined[0] != _version) {
      throw WalletDecryptError(
          'Unsupported wallet blob version: ${combined[0]}');
    }
    final minLen = 1 + _saltLength + _ivLength + 16; // tag is 16 bytes
    if (combined.length < minLen) {
      throw const WalletDecryptError('Wallet blob is truncated.');
    }

    final salt = combined.sublist(1, 1 + _saltLength);
    final iv = combined.sublist(1 + _saltLength, 1 + _saltLength + _ivLength);
    final cipherAndTag = combined.sublist(1 + _saltLength + _ivLength);

    final key = await CryptoUtils.pbkdf2HmacSha256Async(
      password: Uint8List.fromList(utf8.encode(pin)),
      salt: salt,
      iterations: PinService.iterations,
      derivedKeyLength: _keyLength,
    );

    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          pc.AEADParameters(
            pc.KeyParameter(key),
            _macBits,
            iv,
            Uint8List(0),
          ),
        );
      final plain = cipher.process(cipherAndTag);
      return utf8.decode(plain);
    } on pc.InvalidCipherTextException {
      // Most commonly: wrong PIN. Authentication tag mismatch.
      return null;
    }
  }
}

/// Thrown when a blob is *structurally* invalid (truncated, wrong
/// version, not base64). A wrong PIN does *not* throw — it returns
/// `null` from [WalletCipher.decrypt] so callers can prompt for
/// retry without distinguishing corruption from a bad PIN.
class WalletDecryptError implements Exception {
  const WalletDecryptError(this.message);
  final String message;
  @override
  String toString() => 'WalletDecryptError: $message';
}
