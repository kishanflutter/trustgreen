import 'package:dio/dio.dart';

import '../../core/env/app_env.dart';
import 'market_models.dart';

/// CoinGecko REST client for the Market tab.
///
/// One class for three endpoints:
/// - `GET /coins/markets`  → list of coins with sparkline_7d
/// - `GET /search`         → free-text search by name / symbol
/// - `GET /coins/{id}/market_chart` → time-series for the chart
///
/// Demo / Pro API key handling is shared with the price service.
class CoinGeckoMarket {
  CoinGeckoMarket({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const String _host = 'api.coingecko.com';

  Map<String, dynamic> _withKey(Map<String, dynamic> qp) {
    final key = AppEnv.coingeckoApiKey;
    if (key == null) return qp;
    final isDemo = key.startsWith('CG-');
    return {
      ...qp,
      isDemo ? 'x_cg_demo_api_key' : 'x_cg_pro_api_key': key,
    };
  }

  /// Top [perPage] coins by market cap. Includes 7d sparkline and
  /// 24h price change %. Returns an empty list on network errors so
  /// callers can show an "Unavailable" state instead of crashing.
  Future<List<MarketCoin>> topCoins({
    int perPage = 50,
    int page = 1,
  }) async {
    final uri = Uri.https(_host, '/api/v3/coins/markets', _withKey({
      'vs_currency': 'usd',
      'order': 'market_cap_desc',
      'per_page': '$perPage',
      'page': '$page',
      'sparkline': 'true',
      'price_change_percentage': '24h',
    }));
    try {
      final res = await _dio.getUri<List<dynamic>>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final data = res.data ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(MarketCoin.fromJson)
          .toList();
    } on DioException {
      return const <MarketCoin>[];
    }
  }

  /// Free-text search across CoinGecko's coin database. Strips out
  /// non-coin result categories (exchanges, NFTs, …).
  Future<List<CoinSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return const <CoinSearchResult>[];
    final uri = Uri.https(_host, '/api/v3/search', _withKey({
      'query': query.trim(),
    }));
    try {
      final res = await _dio.getUri<Map<String, dynamic>>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final data = res.data ?? const {};
      final coins = data['coins'];
      if (coins is! List) return const <CoinSearchResult>[];
      return coins
          .whereType<Map<String, dynamic>>()
          .take(20)
          .map(CoinSearchResult.fromJson)
          .toList();
    } on DioException {
      return const <CoinSearchResult>[];
    }
  }

  /// Time-series for the coin-detail chart. Defaults to a 7-day
  /// window which CoinGecko serves as hourly bars on the free tier.
  Future<CoinChartSeries> coinChart(
    String id, {
    int days = 7,
  }) async {
    final uri = Uri.https(_host, '/api/v3/coins/$id/market_chart', _withKey({
      'vs_currency': 'usd',
      'days': '$days',
    }));
    try {
      final res = await _dio.getUri<Map<String, dynamic>>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final data = res.data ?? const {};
      return CoinChartSeries.fromJson(data);
    } on DioException {
      return const CoinChartSeries(points: []);
    }
  }
}
