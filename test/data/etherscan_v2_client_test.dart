import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/chains/chain_config.dart';
import 'package:trustgreen/data/history/etherscan_v2_client.dart';
import 'package:trustgreen/data/history/tx_history_models.dart';

/// Returns a JSON body for the requested `action=` query string.
class _EtherscanFakeAdapter implements HttpClientAdapter {
  _EtherscanFakeAdapter({
    required this.txlistJson,
    required this.tokentxJson,
  });

  final String txlistJson;
  final String tokentxJson;
  int callCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    callCount += 1;
    final action = options.uri.queryParameters['action'];
    final body = action == 'tokentx' ? tokentxJson : txlistJson;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '''
TRUSTGREEN_CHAIN_ID=97
TRUSTGREEN_RPC_URL=https://bsc-testnet-rpc.publicnode.com/
TRUSTGREEN_EXPLORER_URL=https://testnet.bscscan.com/
TRUSTGREEN_SYMBOL=TG
TRUSTGREEN_USDT=0x9Bd70586558a3D4Be7d38ed3d4E9EF23360ed7fa
TRUSTGREEN_USDT_DECIMALS=18
''');
  });

  group('EtherscanV2Client', () {
    test('returns empty list for unsupported chains', () async {
      // Default Trust Green entry has chainId 97 → IS supported.
      // Synthesise a chain not in the supportedChainIds set.
      const fakeChain = ChainDefinition(
        id: 'fake',
        chainId: 9001,
        name: 'Fake',
        rpcUrl: 'https://fake',
        symbol: 'FAKE',
        decimals: 18,
        explorerUrl: 'https://fake.io',
        logoKey: 'fake',
        usdt: UsdtDefinition(
          address: '0x0000000000000000000000000000000000000000',
          decimals: 18,
        ),
      );
      final client = EtherscanV2Client();
      final result = await client.fetchCombinedHistory(
        chain: fakeChain,
        address: '0x0000000000000000000000000000000000000000',
      );
      expect(result, isEmpty);
      expect(client.supportsChain(fakeChain), isFalse);
    });

    test('parses txlist + tokentx + merges by timestamp', () async {
      final adapter = _EtherscanFakeAdapter(
        txlistJson: '''
{
  "status": "1",
  "message": "OK",
  "result": [
    {
      "hash": "0xa",
      "from": "0xabc",
      "to": "0xdef",
      "value": "1000000000000000000",
      "timeStamp": "1715600000",
      "gas": "21000",
      "gasUsed": "21000",
      "gasPrice": "5000000000",
      "isError": "0",
      "txreceipt_status": "1",
      "input": "0x",
      "methodId": "0x"
    }
  ]
}
''',
        tokentxJson: '''
{
  "status": "1",
  "message": "OK",
  "result": [
    {
      "hash": "0xb",
      "from": "0xabc",
      "to": "0x123",
      "value": "5000000",
      "timeStamp": "1715700000",
      "tokenSymbol": "USDT",
      "tokenDecimal": "6",
      "contractAddress": "0xusdt"
    }
  ]
}
''',
      );

      final dio = Dio()..httpClientAdapter = adapter;
      final client = EtherscanV2Client(dio: dio);
      final eth = ChainCatalog.byId('eth')!;

      final result = await client.fetchCombinedHistory(
        chain: eth,
        address: '0xabc',
      );
      expect(adapter.callCount, 2);
      expect(result.length, 2);
      // Newest first: token tx (1715700000) before native (1715600000).
      expect(result.first.hash, '0xb');
      expect(result.first.assetKind, TxAssetKind.erc20);
      expect(result.first.assetSymbol, 'USDT');
      expect(result.first.assetDecimals, 6);
      expect(result.last.hash, '0xa');
      expect(result.last.assetKind, TxAssetKind.native);
    });

    test('flags failed native txs as success=false', () async {
      final adapter = _EtherscanFakeAdapter(
        txlistJson: '''
{"status":"1","message":"OK","result":[
  {"hash":"0xa","from":"0xabc","to":"0xdef","value":"0","timeStamp":"1715600000","gas":"21000","gasUsed":"21000","gasPrice":"5","isError":"1","txreceipt_status":"0","input":"0xdeadbeef","methodId":"0xdeadbeef"}
]}''',
        tokentxJson:
            '{"status":"0","message":"No transactions found","result":[]}',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final client = EtherscanV2Client(dio: dio);
      final items = await client.fetchCombinedHistory(
        chain: ChainCatalog.byId('eth')!,
        address: '0xabc',
      );
      expect(items.length, 1);
      expect(items.first.success, isFalse);
      // input != "0x" and value == 0 → contract call classification.
      expect(items.first.direction, TxDirection.contract);
    });

    test('rate-limit-style payload yields an empty list', () async {
      final adapter = _EtherscanFakeAdapter(
        txlistJson:
            '{"status":"0","message":"NOTOK","result":"Max rate limit reached"}',
        tokentxJson:
            '{"status":"0","message":"NOTOK","result":"Max rate limit reached"}',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final client = EtherscanV2Client(dio: dio);
      final items = await client.fetchCombinedHistory(
        chain: ChainCatalog.byId('eth')!,
        address: '0xabc',
      );
      expect(items, isEmpty);
    });

    test('direction classification: incoming vs outgoing', () async {
      final adapter = _EtherscanFakeAdapter(
        txlistJson: '''
{"status":"1","message":"OK","result":[
  {"hash":"0xa","from":"0xabc","to":"0xdef","value":"100","timeStamp":"1715600000","isError":"0","txreceipt_status":"1","input":"0x"},
  {"hash":"0xb","from":"0x111","to":"0xabc","value":"100","timeStamp":"1715600001","isError":"0","txreceipt_status":"1","input":"0x"}
]}''',
        tokentxJson:
            '{"status":"0","message":"No transactions found","result":[]}',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final client = EtherscanV2Client(dio: dio);
      final items = await client.fetchCombinedHistory(
        chain: ChainCatalog.byId('eth')!,
        address: '0xabc',
      );
      final outgoing = items.firstWhere((t) => t.hash == '0xa');
      final incoming = items.firstWhere((t) => t.hash == '0xb');
      expect(outgoing.direction, TxDirection.outgoing);
      expect(incoming.direction, TxDirection.incoming);
    });
  });
}
