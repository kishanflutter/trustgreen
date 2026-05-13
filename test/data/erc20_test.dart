import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/rpc/erc20.dart';

String _toHex(List<int> bytes) {
  final buf = StringBuffer();
  for (final b in bytes) {
    buf.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}

void main() {
  group('Erc20Contract', () {
    test('encodeTransfer produces the canonical 0xa9059cbb selector', () {
      final token = Erc20Contract(
        '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      );
      final data = token.encodeTransfer(
        to: '0x1111111111111111111111111111111111111111',
        value: BigInt.from(1000000),
      );
      final hex = _toHex(data);
      // 4-byte selector for transfer(address,uint256).
      expect(hex.substring(0, 8), equals('a9059cbb'));
      // 4 bytes selector + 32 bytes address-padded + 32 bytes value = 68 bytes
      expect(data.length, equals(4 + 32 + 32));
    });

    test('to-address is left-padded with zeros to 32 bytes', () {
      final token = Erc20Contract(
        '0x0000000000000000000000000000000000000000',
      );
      final data = token.encodeTransfer(
        to: '0x1234567890abcdef1234567890abcdef12345678',
        value: BigInt.zero,
      );
      final hex = _toHex(data);
      // address slot: 24 leading zero bytes + 20 address bytes.
      expect(
        hex.substring(8, 8 + 64),
        equals('0' * 24 + '1234567890abcdef1234567890abcdef12345678'),
      );
    });

    test('value slot encodes the uint256 big-endian', () {
      final token = Erc20Contract(
        '0x0000000000000000000000000000000000000000',
      );
      final data = token.encodeTransfer(
        to: '0x1111111111111111111111111111111111111111',
        value: BigInt.from(0xdeadbeef),
      );
      final hex = _toHex(data);
      final valueSlot = hex.substring(8 + 64); // last 32 bytes
      // 0xdeadbeef padded to 32 bytes.
      expect(
        valueSlot,
        equals(
          '0' * (64 - 8) + 'deadbeef',
        ),
      );
    });

    test('large value (>2^64) does not overflow', () {
      final token = Erc20Contract(
        '0x0000000000000000000000000000000000000000',
      );
      // 100 * 1e18 (100 ETH worth of wei) — well beyond uint64 range.
      final huge = BigInt.parse('100000000000000000000');
      final data = token.encodeTransfer(
        to: '0x1111111111111111111111111111111111111111',
        value: huge,
      );
      expect(data.length, equals(68));
      final hex = _toHex(data);
      // Round-trip-decode the value slot back to BigInt.
      final valueHex = hex.substring(hex.length - 64);
      expect(BigInt.parse(valueHex, radix: 16), equals(huge));
    });
  });
}
