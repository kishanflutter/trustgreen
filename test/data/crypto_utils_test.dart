import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/auth/crypto_utils.dart';

/// Source: RFC 6070 — PBKDF2 HMAC-SHA-2 test vectors (only the
/// SHA-256 variants we care about) cross-checked against
/// well-known reference values.
void main() {
  group('CryptoUtils.pbkdf2HmacSha256', () {
    test('matches RFC 6070-style vector: password / salt / 1 iter', () {
      final out = CryptoUtils.pbkdf2HmacSha256(
        password: Uint8List.fromList(utf8.encode('password')),
        salt: Uint8List.fromList(utf8.encode('salt')),
        iterations: 1,
        derivedKeyLength: 32,
      );
      expect(
        CryptoUtils.toHex(out),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('matches RFC vector: 4096 iterations', () {
      final out = CryptoUtils.pbkdf2HmacSha256(
        password: Uint8List.fromList(utf8.encode('password')),
        salt: Uint8List.fromList(utf8.encode('salt')),
        iterations: 4096,
        derivedKeyLength: 32,
      );
      expect(
        CryptoUtils.toHex(out),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('derivedKeyLength shorter than hashLen is truncated', () {
      final out = CryptoUtils.pbkdf2HmacSha256(
        password: Uint8List.fromList(utf8.encode('password')),
        salt: Uint8List.fromList(utf8.encode('salt')),
        iterations: 1,
        derivedKeyLength: 16,
      );
      expect(out.length, 16);
      expect(
        CryptoUtils.toHex(out),
        '120fb6cffcf8b32c43e7225256c4f837',
      );
    });

    test('rejects invalid arguments', () {
      expect(
        () => CryptoUtils.pbkdf2HmacSha256(
          password: Uint8List(0),
          salt: Uint8List(0),
          iterations: 0,
          derivedKeyLength: 32,
        ),
        throwsArgumentError,
      );
      expect(
        () => CryptoUtils.pbkdf2HmacSha256(
          password: Uint8List(0),
          salt: Uint8List(0),
          iterations: 1,
          derivedKeyLength: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('CryptoUtils.constantTimeEquals', () {
    test('returns true for identical sequences', () {
      expect(CryptoUtils.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('returns false for different sequences', () {
      expect(CryptoUtils.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    });

    test('returns false for different lengths', () {
      expect(CryptoUtils.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });

  group('CryptoUtils hex round-trip', () {
    test('toHex / fromHex are inverses', () {
      final bytes = Uint8List.fromList(List.generate(64, (i) => i));
      expect(CryptoUtils.fromHex(CryptoUtils.toHex(bytes)), equals(bytes));
    });

    test('fromHex accepts 0x prefix', () {
      expect(
        CryptoUtils.fromHex('0xdeadbeef'),
        Uint8List.fromList([0xde, 0xad, 0xbe, 0xef]),
      );
    });

    test('fromHex rejects odd-length input', () {
      expect(() => CryptoUtils.fromHex('abc'), throwsFormatException);
    });
  });

  group('CryptoUtils.randomBytes', () {
    test('returns the requested length', () {
      expect(CryptoUtils.randomBytes(16).length, 16);
      expect(CryptoUtils.randomBytes(32).length, 32);
    });

    test('produces distinct values across calls', () {
      final a = CryptoUtils.randomBytes(32);
      final b = CryptoUtils.randomBytes(32);
      // Two 32-byte samples colliding has probability ~2^-256.
      expect(a, isNot(equals(b)));
    });
  });
}
