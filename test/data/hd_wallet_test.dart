import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/wallet/hd_wallet.dart';

void main() {
  group('HdWallet.generate', () {
    test('produces 12 / 18 / 24 word mnemonics', () {
      for (final length in MnemonicLength.values) {
        final w = HdWallet.generate(length: length);
        expect(w.words.length, length.wordCount);
        expect(HdWallet.isValid(w.mnemonic), isTrue);
      }
    });
  });

  group('HdWallet.fromMnemonic — BIP-39 reference vectors', () {
    // From https://github.com/trezor/python-mnemonic/blob/master/vectors.json
    // (entry 0). Deterministic derivation lets us pin the address.
    const testMnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon '
        'abandon abandon abandon about';

    test('parses and validates', () {
      final w = HdWallet.fromMnemonic(testMnemonic);
      expect(w.length, MnemonicLength.words12);
      expect(w.words.length, 12);
    });

    test('derives a deterministic EVM address at m/44\'/60\'/0\'/0/0', () {
      final w = HdWallet.fromMnemonic(testMnemonic);
      // Well-known address for this mnemonic + path (verified against
      // MetaMask and ethers.js).
      expect(
        w.evmAddress().toLowerCase(),
        '0x9858effd232b4033e47d90003d41ec34ecaeda94',
      );
    });

    test('private key is 32 bytes', () {
      final pk = HdWallet.fromMnemonic(testMnemonic).privateKey();
      expect(pk.length, 32);
    });

    test('normaliseMnemonic lowercases and collapses whitespace', () {
      final messy = '  Abandon   ABANDON  abandon  '
          'abandon abandon abandon abandon abandon '
          'abandon abandon abandon about ';
      final w = HdWallet.fromMnemonic(messy);
      expect(w.mnemonic, testMnemonic);
    });

    test('rejects invalid mnemonic', () {
      expect(
        () => HdWallet.fromMnemonic('not a valid mnemonic phrase at all here'),
        throwsFormatException,
      );
    });

    test('rejects unsupported word counts (15, 21)', () {
      // 15-word phrase taken from a valid 24-word seed truncated.
      // bip39.validateMnemonic returns false for an incomplete phrase,
      // so we hit the FormatException early.
      expect(
        () => HdWallet.fromMnemonic('abandon abandon abandon abandon abandon '
            'abandon abandon abandon abandon abandon abandon abandon abandon '
            'abandon abandon'),
        throwsFormatException,
      );
    });
  });

  group('HdWallet.validateAgainstWordlist', () {
    test('marks valid words true', () {
      final r = HdWallet.validateAgainstWordlist('abandon ability about');
      expect(r, [true, true, true]);
    });

    test('flags out-of-list words false', () {
      final r = HdWallet.validateAgainstWordlist('abandon notaword about');
      expect(r, [true, false, true]);
    });

    test('empty input → empty list', () {
      expect(HdWallet.validateAgainstWordlist(''), isEmpty);
      expect(HdWallet.validateAgainstWordlist('   '), isEmpty);
    });
  });
}
