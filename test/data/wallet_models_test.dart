import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/wallet/wallet_models.dart';

void main() {
  group('WalletMeta.listFromJsonString — mutability regression', () {
    // These tests guard a P0 bug where `const []` was returned on
    // the empty paths, causing `WalletRepository.createWallet` to
    // throw `UnsupportedError: Cannot add to an unmodifiable list`
    // when creating / importing the first wallet on a device.

    test('returns a growable list when raw is null', () {
      final list = WalletMeta.listFromJsonString(null);
      expect(list, isEmpty);
      expect(
        () => list.add(_dummy()),
        returnsNormally,
        reason: 'List must be mutable so the repository can add wallets',
      );
    });

    test('returns a growable list when raw is empty', () {
      final list = WalletMeta.listFromJsonString('');
      expect(list, isEmpty);
      expect(() => list.add(_dummy()), returnsNormally);
    });

    test('returns a growable list when raw is invalid JSON shape', () {
      final list = WalletMeta.listFromJsonString('{"not":"a list"}');
      expect(list, isEmpty);
      expect(() => list.add(_dummy()), returnsNormally);
    });

    test('returns a growable list when raw is a valid JSON list', () {
      final list = WalletMeta.listFromJsonString('[]');
      expect(list, isEmpty);
      expect(() => list.add(_dummy()), returnsNormally);
    });

    test('listToJsonString roundtrips a populated list', () {
      final original = [
        WalletMeta(
          id: 'w_aaa',
          name: 'Main wallet',
          addressEvm: '0x9858effd232b4033e47d90003d41ec34ecaeda94',
          createdAt: DateTime.utc(2026, 5, 13, 12, 0, 0),
          mnemonicWordCount: 12,
        ),
      ];
      final json = WalletMeta.listToJsonString(original);
      final parsed = WalletMeta.listFromJsonString(json);
      expect(parsed, hasLength(1));
      expect(parsed.first.id, 'w_aaa');
      expect(parsed.first.name, 'Main wallet');
      expect(parsed.first.mnemonicWordCount, 12);
      // Round-tripped list must still be mutable.
      expect(() => parsed.add(_dummy()), returnsNormally);
    });
  });
}

WalletMeta _dummy() => WalletMeta(
      id: 'w_dummy',
      name: 'dummy',
      addressEvm: '0x0000000000000000000000000000000000000000',
      createdAt: DateTime.utc(2026, 1, 1),
      mnemonicWordCount: 12,
    );
