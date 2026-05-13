import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/auth/wallet_cipher.dart';

void main() {
  group('WalletCipher', () {
    test('roundtrip — decrypt with correct PIN returns original', () async {
      const plain = '{"mnemonic":"abandon abandon abandon"}';
      const pin = '123456';
      final blob = await WalletCipher.encrypt(plaintext: plain, pin: pin);
      expect(blob, isNotEmpty);
      expect(
        await WalletCipher.decrypt(b64: blob, pin: pin),
        equals(plain),
      );
    });

    test('different PIN returns null (auth-tag mismatch)', () async {
      const plain = 'secret payload';
      final blob = await WalletCipher.encrypt(plaintext: plain, pin: '123456');
      expect(await WalletCipher.decrypt(b64: blob, pin: '654321'), isNull);
    });

    test('two encrypts of the same payload produce distinct ciphertexts',
        () async {
      const plain = 'same payload';
      const pin = '999999';
      final a = await WalletCipher.encrypt(plaintext: plain, pin: pin);
      final b = await WalletCipher.encrypt(plaintext: plain, pin: pin);
      // Randomised salt + IV → different blob almost always.
      expect(a, isNot(equals(b)));
      expect(await WalletCipher.decrypt(b64: a, pin: pin), equals(plain));
      expect(await WalletCipher.decrypt(b64: b, pin: pin), equals(plain));
    });

    test('throws WalletDecryptError on structurally invalid blob', () async {
      await expectLater(
        WalletCipher.decrypt(b64: '!!!not-base64!!!', pin: '111111'),
        throwsA(isA<WalletDecryptError>()),
      );
    });

    test('handles longer payloads (multi-block ciphertext)', () async {
      final plain = 'x' * 4096;
      const pin = '888888';
      final blob = await WalletCipher.encrypt(plaintext: plain, pin: pin);
      expect(await WalletCipher.decrypt(b64: blob, pin: pin), equals(plain));
    });
  });
}
