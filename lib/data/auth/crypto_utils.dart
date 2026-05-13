import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show compute;

/// Pure-Dart cryptographic primitives used by PIN + wallet storage.
///
/// We deliberately avoid third-party PIN libraries — only
/// `package:crypto` (dart-lang official) is used. The PBKDF2
/// implementation follows RFC 2898 § 5.2.
class CryptoUtils {
  CryptoUtils._();

  /// Cryptographically-secure random byte vector of [length] bytes.
  static Uint8List randomBytes(int length) {
    final rng = Random.secure();
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }

  /// Async variant of [pbkdf2HmacSha256] that runs the work in a
  /// background isolate via [compute] so it doesn't block the UI
  /// thread. Use this from anywhere on the call path of a user-
  /// visible interaction (PIN verify, wallet encrypt, etc.). The
  /// synchronous version remains for use inside isolates or in
  /// places where the caller has already moved work off the main
  /// isolate.
  static Future<Uint8List> pbkdf2HmacSha256Async({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int derivedKeyLength,
  }) {
    return compute(
      _pbkdf2Entrypoint,
      _Pbkdf2Args(
        password: password,
        salt: salt,
        iterations: iterations,
        derivedKeyLength: derivedKeyLength,
      ),
    );
  }

  /// PBKDF2 with HMAC-SHA-256 (RFC 2898 § 5.2).
  ///
  /// * [password] — raw key bytes (caller is responsible for encoding).
  /// * [salt] — random per-record salt (≥ 16 bytes recommended).
  /// * [iterations] — work factor (≥ 100 000 recommended in 2025+).
  /// * [derivedKeyLength] — number of output bytes (32 for AES-256).
  ///
  /// Note: 200 000 iterations takes roughly 500 ms – 2 s on a typical
  /// mobile device. Prefer [pbkdf2HmacSha256Async] from UI code so
  /// the work runs in a background isolate.
  static Uint8List pbkdf2HmacSha256({
    required Uint8List password,
    required Uint8List salt,
    required int iterations,
    required int derivedKeyLength,
  }) {
    if (iterations < 1) {
      throw ArgumentError.value(iterations, 'iterations', 'must be >= 1');
    }
    if (derivedKeyLength < 1) {
      throw ArgumentError.value(
          derivedKeyLength, 'derivedKeyLength', 'must be >= 1');
    }

    const hashLen = 32; // SHA-256 output size
    final blocks = (derivedKeyLength + hashLen - 1) ~/ hashLen;
    final out = Uint8List(blocks * hashLen);

    final hmac = crypto.Hmac(crypto.sha256, password);

    // saltBlock = salt || INT32_BE(i), reused across iterations.
    final saltBlock = Uint8List(salt.length + 4);
    saltBlock.setRange(0, salt.length, salt);

    for (var block = 1; block <= blocks; block++) {
      saltBlock[salt.length] = (block >> 24) & 0xff;
      saltBlock[salt.length + 1] = (block >> 16) & 0xff;
      saltBlock[salt.length + 2] = (block >> 8) & 0xff;
      saltBlock[salt.length + 3] = block & 0xff;

      var u = Uint8List.fromList(hmac.convert(saltBlock).bytes);
      final f = Uint8List.fromList(u);

      for (var iter = 1; iter < iterations; iter++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var k = 0; k < hashLen; k++) {
          f[k] ^= u[k];
        }
      }
      out.setRange((block - 1) * hashLen, block * hashLen, f);
    }
    return Uint8List.sublistView(out, 0, derivedKeyLength);
  }

  /// Timing-safe equality check. Returns false immediately for
  /// different lengths (length is not secret).
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Lowercase hex encoding (no `0x` prefix).
  static String toHex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Hex → bytes. Accepts an optional `0x` prefix.
  static Uint8List fromHex(String hex) {
    var s = hex;
    if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);
    if (s.length.isOdd) {
      throw FormatException('Odd-length hex string', hex);
    }
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}

// ── `compute` plumbing ──────────────────────────────────────────────
// Top-level types/functions are required by `compute`; the worker
// must be entry-point reachable from a fresh isolate.

class _Pbkdf2Args {
  const _Pbkdf2Args({
    required this.password,
    required this.salt,
    required this.iterations,
    required this.derivedKeyLength,
  });

  final Uint8List password;
  final Uint8List salt;
  final int iterations;
  final int derivedKeyLength;
}

Uint8List _pbkdf2Entrypoint(_Pbkdf2Args args) =>
    CryptoUtils.pbkdf2HmacSha256(
      password: args.password,
      salt: args.salt,
      iterations: args.iterations,
      derivedKeyLength: args.derivedKeyLength,
    );
