import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/rpc/rpc_service.dart';

void main() {
  group('TokenAmount.format', () {
    test('zero formats as "0" regardless of decimals', () {
      expect(TokenAmount(raw: BigInt.zero, decimals: 18).format(), '0');
      expect(TokenAmount(raw: BigInt.zero, decimals: 6).format(), '0');
    });

    test('whole number with no fraction trims trailing zeros', () {
      final amount = TokenAmount(
        raw: BigInt.parse('1000000000000000000'),
        decimals: 18,
      );
      expect(amount.format(), '1');
    });

    test('fractional value is shown to maxFraction digits', () {
      final amount = TokenAmount(
        raw: BigInt.parse('1234567890123456789'),
        decimals: 18,
      );
      expect(amount.format(maxFraction: 6), '1.234567');
      expect(amount.format(maxFraction: 2), '1.23');
    });

    test('USDT (6 decimals) round-trip', () {
      // 12.34 USDT = 12_340_000 base units
      final amount = TokenAmount(
        raw: BigInt.from(12340000),
        decimals: 6,
      );
      expect(amount.format(), '12.34');
    });

    test('toDoubleUnits is reasonably accurate for typical balances', () {
      final wei = BigInt.parse('1500000000000000000'); // 1.5 ETH
      final amount = TokenAmount(raw: wei, decimals: 18);
      expect(amount.toDoubleUnits(), closeTo(1.5, 1e-9));
    });
  });

  group('TokenAmount.tryParseDecimal', () {
    test('parses integer input', () {
      final a = TokenAmount.tryParseDecimal('5', 18)!;
      expect(a.raw, BigInt.parse('5000000000000000000'));
    });

    test('parses decimal input', () {
      final a = TokenAmount.tryParseDecimal('0.5', 18)!;
      expect(a.raw, BigInt.parse('500000000000000000'));
    });

    test('rejects too-many decimal places', () {
      // 7 decimal places with 6-decimal token → null.
      expect(TokenAmount.tryParseDecimal('1.1234567', 6), isNull);
    });

    test('rejects malformed strings', () {
      expect(TokenAmount.tryParseDecimal('abc', 18), isNull);
      expect(TokenAmount.tryParseDecimal('1.2.3', 18), isNull);
      expect(TokenAmount.tryParseDecimal('', 18), isNull);
      expect(TokenAmount.tryParseDecimal('-1', 18), isNull);
    });
  });
}
