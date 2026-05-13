import 'package:dio/dio.dart';

import '../../core/env/app_env.dart';

/// Tiny CoinGecko REST client.
///
/// CoinGecko's free / Demo tier is rate-limited (~30 req/min) so we
/// memoise responses for [_cacheTtl]. The wallet only needs USD
/// price for a handful of coin ids, so we use the `simple/price`
/// endpoint with comma-joined ids.
class PriceService {
  PriceService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Cache TTL — short enough to feel "live" but long enough to
  /// avoid burning Demo-key quota during quick refresh cycles.
  static const Duration _cacheTtl = Duration(seconds: 60);

  /// Per-coin-id last-fetched USD price + timestamp.
  final Map<String, _PriceCacheEntry> _cache = {};

  /// Pending in-flight fetches keyed by sorted-comma-joined ids;
  /// prevents duplicate concurrent requests from hammering the API
  /// when the dashboard mounts 5 widgets at once.
  final Map<String, Future<Map<String, double>>> _inflight = {};

  static const String _baseHost = 'api.coingecko.com';

  /// Returns `usd` prices for [ids]. Caches each id individually so
  /// future overlapping requests can serve from the cache.
  ///
  /// Empty / null / "trustgreen-native (no coingecko id)" entries
  /// are filtered out before the request — saving one round-trip
  /// for testnet-only wallets.
  Future<Map<String, double>> usdPrices(Iterable<String?> ids) async {
    final unique = <String>{};
    for (final id in ids) {
      if (id == null || id.isEmpty) continue;
      unique.add(id);
    }
    if (unique.isEmpty) return const {};

    final now = DateTime.now();
    final fresh = <String, double>{};
    final stale = <String>[];

    for (final id in unique) {
      final entry = _cache[id];
      if (entry != null && now.difference(entry.fetchedAt) < _cacheTtl) {
        fresh[id] = entry.usd;
      } else {
        stale.add(id);
      }
    }
    if (stale.isEmpty) return fresh;

    stale.sort();
    final key = stale.join(',');

    final pending = _inflight[key];
    if (pending != null) {
      final fetched = await pending;
      return {...fresh, ...fetched};
    }

    final future = _fetch(stale);
    _inflight[key] = future;
    try {
      final fetched = await future;
      return {...fresh, ...fetched};
    } finally {
      _inflight.remove(key);
    }
  }

  /// Single-id convenience wrapper. Returns `null` if the coin id is
  /// missing or the upstream response had no `usd` field.
  Future<double?> usdPrice(String? id) async {
    if (id == null || id.isEmpty) return null;
    final map = await usdPrices([id]);
    return map[id];
  }

  Future<Map<String, double>> _fetch(List<String> ids) async {
    final key = AppEnv.coingeckoApiKey;
    final isDemo = key != null && key.startsWith('CG-');

    final qp = <String, dynamic>{
      'ids': ids.join(','),
      'vs_currencies': 'usd',
    };
    if (key != null) {
      qp[isDemo ? 'x_cg_demo_api_key' : 'x_cg_pro_api_key'] = key;
    }

    final uri = Uri.https(_baseHost, '/api/v3/simple/price', qp);

    try {
      final res = await _dio.getUri<Map<String, dynamic>>(
        uri,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final data = res.data ?? const {};
      final result = <String, double>{};
      final now = DateTime.now();
      for (final id in ids) {
        final entry = data[id];
        if (entry is Map && entry['usd'] != null) {
          final usd = (entry['usd'] as num).toDouble();
          result[id] = usd;
          _cache[id] = _PriceCacheEntry(usd: usd, fetchedAt: now);
        }
      }
      return result;
    } on DioException {
      // Surface a partial result rather than a hard failure — the UI
      // can show "—" for missing coin ids and try again on refresh.
      return const {};
    }
  }

  /// Test-only hook to clear the in-memory cache.
  void clearCache() => _cache.clear();
}

class _PriceCacheEntry {
  const _PriceCacheEntry({required this.usd, required this.fetchedAt});
  final double usd;
  final DateTime fetchedAt;
}
