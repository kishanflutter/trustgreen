import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/chains/chain_config.dart';

void main() {
  setUpAll(() {
    // ChainCatalog reads .env via AppEnv for the Trust Green entry.
    // Initialise dotenv with a fixed in-memory blob so the tests
    // never depend on the local filesystem.
    dotenv.testLoad(fileInput: '''
TRUSTGREEN_CHAIN_ID=97
TRUSTGREEN_RPC_URL=https://bsc-testnet-rpc.publicnode.com/
TRUSTGREEN_EXPLORER_URL=https://testnet.bscscan.com/
TRUSTGREEN_SYMBOL=TG
TRUSTGREEN_USDT=0x9Bd70586558a3D4Be7d38ed3d4E9EF23360ed7fa
TRUSTGREEN_USDT_DECIMALS=18
''');
  });

  group('ChainCatalog', () {
    test('defaults() returns Trust Green as the first entry', () {
      final list = ChainCatalog.defaults();
      expect(list.first.id, 'trustgreen');
    });

    test('every chain has a non-empty rpcUrl and USDT address', () {
      for (final c in ChainCatalog.defaults()) {
        expect(c.rpcUrl.isNotEmpty, isTrue, reason: 'rpcUrl for ${c.id}');
        expect(c.usdt.address.startsWith('0x'), isTrue,
            reason: 'usdt address for ${c.id}');
        expect(c.usdt.address.length, equals(42),
            reason: 'usdt address length for ${c.id}');
      }
    });

    test('mainnet chains carry a coingecko id; testnet does not', () {
      for (final c in ChainCatalog.defaults()) {
        if (c.testnet) {
          expect(c.coingeckoId, isNull, reason: '${c.id} is a testnet');
        } else {
          expect(c.coingeckoId, isNotNull, reason: '${c.id} needs coingeckoId');
          expect(c.coingeckoId!.isNotEmpty, isTrue);
        }
      }
    });

    test('byChainId finds known chains', () {
      expect(ChainCatalog.byChainId(1)?.id, 'eth');
      expect(ChainCatalog.byChainId(56)?.id, 'bnb');
      expect(ChainCatalog.byChainId(137)?.id, 'polygon');
      expect(ChainCatalog.byChainId(43114)?.id, 'avax');
      expect(ChainCatalog.byChainId(42161)?.id, 'arbitrum');
      expect(ChainCatalog.byChainId(10)?.id, 'optimism');
      expect(ChainCatalog.byChainId(99999), isNull);
    });

    test('byId mirrors byChainId', () {
      expect(ChainCatalog.byId('eth')?.chainId, 1);
      expect(ChainCatalog.byId('bnb')?.chainId, 56);
      expect(ChainCatalog.byId('not-a-chain'), isNull);
    });

    test('explorer helpers strip trailing slashes', () {
      final eth = ChainCatalog.byId('eth')!;
      final url = eth.txExplorerUrl('0xabc');
      expect(url, 'https://etherscan.io/tx/0xabc');
      expect(eth.addressExplorerUrl('0xdef'),
          'https://etherscan.io/address/0xdef');
    });
  });
}
