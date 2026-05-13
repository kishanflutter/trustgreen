import 'package:dio/dio.dart';

import '../../core/env/app_env.dart';
import '../chains/chain_config.dart';
import 'tx_history_models.dart';

/// Wraps Etherscan's unified V2 API (`api.etherscan.io/v2/api`).
///
/// One endpoint, one base URL, every supported `chainid`. We use it
/// for `account/txlist` (native transfers + contract calls) and
/// `account/tokentx` (ERC-20 transfers), then merge the two streams
/// by timestamp.
///
/// **Rate limits**:
/// - No key: ~1 req / 5 s (we de-dupe via the provider cache).
/// - With key: 5 req / s, plenty for an interactive UI.
class EtherscanV2Client {
  EtherscanV2Client({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _host = 'api.etherscan.io';

  /// Chains we trust Etherscan V2 to cover. `byChainId` returns
  /// `null` for testnets / Trust Green so the UI can skip the
  /// network call gracefully.
  static const Set<int> supportedChainIds = {
    1, // Ethereum
    10, // Optimism
    56, // BSC
    97, // BSC testnet (Trust Green)
    137, // Polygon
    42161, // Arbitrum
    43114, // Avalanche C-Chain
  };

  bool supportsChain(ChainDefinition chain) =>
      supportedChainIds.contains(chain.chainId);

  /// Fetches **combined** history (native txs + ERC-20 transfers)
  /// for [address] on [chain], merged into a single chronologically
  /// sorted list. Up to `offset` items per stream are fetched.
  ///
  /// Returns an **empty list** (never throws) for:
  /// - rate-limit errors
  /// - HTTP failures
  /// - chains not in [supportedChainIds]
  ///
  /// Real errors (parse failures) surface as an empty list too —
  /// the UI shows a neutral empty state plus an explorer link.
  Future<List<TxHistoryItem>> fetchCombinedHistory({
    required ChainDefinition chain,
    required String address,
    int offset = 25,
  }) async {
    if (!supportsChain(chain)) return const <TxHistoryItem>[];

    final results = await Future.wait([
      _fetchNative(chain: chain, address: address, offset: offset),
      _fetchTokens(chain: chain, address: address, offset: offset),
    ]);

    final native = results[0];
    final tokens = results[1];

    final merged = <TxHistoryItem>[...native, ...tokens];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  Future<List<TxHistoryItem>> _fetchNative({
    required ChainDefinition chain,
    required String address,
    required int offset,
  }) async {
    final raw = await _get(
      chain: chain,
      params: {
        'module': 'account',
        'action': 'txlist',
        'address': address,
        'startblock': '0',
        'endblock': '99999999',
        'page': '1',
        'offset': '$offset',
        'sort': 'desc',
      },
    );
    if (raw == null) return const <TxHistoryItem>[];
    return raw.map((row) => _parseNative(row, chain, address)).toList();
  }

  Future<List<TxHistoryItem>> _fetchTokens({
    required ChainDefinition chain,
    required String address,
    required int offset,
  }) async {
    final raw = await _get(
      chain: chain,
      params: {
        'module': 'account',
        'action': 'tokentx',
        'address': address,
        'startblock': '0',
        'endblock': '99999999',
        'page': '1',
        'offset': '$offset',
        'sort': 'desc',
      },
    );
    if (raw == null) return const <TxHistoryItem>[];
    return raw.map((row) => _parseToken(row, address)).toList();
  }

  /// Returns the parsed `result` array, or `null` on any failure
  /// (rate limit, network, unexpected payload). Errors are
  /// intentionally swallowed — callers render an empty state.
  Future<List<Map<String, dynamic>>?> _get({
    required ChainDefinition chain,
    required Map<String, String> params,
  }) async {
    final qp = <String, dynamic>{
      'chainid': '${chain.chainId}',
      ...params,
    };
    final key = AppEnv.etherscanApiKey;
    if (key != null) qp['apikey'] = key;

    final uri = Uri.https(_host, '/v2/api', qp);
    try {
      final res = await _dio.getUri<Map<String, dynamic>>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 12),
          // Etherscan returns 200 for "no transactions found" and
          // rate-limit responses too — we filter by `result` shape.
        ),
      );
      final data = res.data ?? const {};
      final result = data['result'];
      if (result is List) {
        return result.whereType<Map<String, dynamic>>().toList();
      }
      // Rate limit or "No transactions found" — both safe to treat
      // as empty.
      return const <Map<String, dynamic>>[];
    } on DioException {
      return null;
    }
  }

  TxHistoryItem _parseNative(
    Map<String, dynamic> row,
    ChainDefinition chain,
    String self,
  ) {
    final from = (row['from'] ?? '').toString();
    final to = (row['to'] ?? '').toString();
    final value = BigInt.tryParse((row['value'] ?? '0').toString()) ??
        BigInt.zero;
    final ts = int.tryParse((row['timeStamp'] ?? '0').toString()) ?? 0;
    final isError = (row['isError'] ?? '0').toString() == '1';
    final receiptOk = (row['txreceipt_status'] ?? '1').toString() != '0';
    final gasUsed = BigInt.tryParse((row['gasUsed'] ?? '').toString());
    final gasPrice = BigInt.tryParse((row['gasPrice'] ?? '').toString());
    final methodIdRaw = (row['methodId'] ?? '').toString();
    final methodId =
        (methodIdRaw.isEmpty || methodIdRaw == '0x') ? null : methodIdRaw;
    final input = (row['input'] ?? '0x').toString();

    final direction = _direction(self: self, from: from, to: to);
    final isContractCall = input.length > 2 && value == BigInt.zero;

    return TxHistoryItem(
      hash: (row['hash'] ?? '').toString(),
      from: from,
      to: to,
      valueRaw: value,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
      success: !isError && receiptOk,
      direction: isContractCall ? TxDirection.contract : direction,
      assetKind:
          isContractCall ? TxAssetKind.unknown : TxAssetKind.native,
      assetSymbol: chain.symbol,
      assetDecimals: chain.decimals,
      tokenAddress: null,
      gasUsed: gasUsed,
      gasPriceWei: gasPrice,
      methodId: methodId,
    );
  }

  TxHistoryItem _parseToken(
    Map<String, dynamic> row,
    String self,
  ) {
    final from = (row['from'] ?? '').toString();
    final to = (row['to'] ?? '').toString();
    final value = BigInt.tryParse((row['value'] ?? '0').toString()) ??
        BigInt.zero;
    final ts = int.tryParse((row['timeStamp'] ?? '0').toString()) ?? 0;
    final decimals =
        int.tryParse((row['tokenDecimal'] ?? '18').toString()) ?? 18;
    final symbol = (row['tokenSymbol'] ?? 'TOKEN').toString();
    final contract = (row['contractAddress'] ?? '').toString();
    final gasUsed = BigInt.tryParse((row['gasUsed'] ?? '').toString());
    final gasPrice = BigInt.tryParse((row['gasPrice'] ?? '').toString());

    return TxHistoryItem(
      hash: (row['hash'] ?? '').toString(),
      from: from,
      to: to,
      valueRaw: value,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
      // Token transfers in `tokentx` are always successful — failed
      // contract calls don't emit Transfer events.
      success: true,
      direction: _direction(self: self, from: from, to: to),
      assetKind: TxAssetKind.erc20,
      assetSymbol: symbol,
      assetDecimals: decimals,
      tokenAddress: contract,
      gasUsed: gasUsed,
      gasPriceWei: gasPrice,
      methodId: null,
    );
  }

  TxDirection _direction({
    required String self,
    required String from,
    required String to,
  }) {
    final s = self.toLowerCase();
    final f = from.toLowerCase();
    final t = to.toLowerCase();
    if (f == s && t == s) return TxDirection.selfSelf;
    if (f == s) return TxDirection.outgoing;
    if (t == s) return TxDirection.incoming;
    return TxDirection.outgoing;
  }
}
