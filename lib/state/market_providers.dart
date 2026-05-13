import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/market/coingecko_market.dart';
import '../data/market/market_models.dart';

/// Singleton client.
final marketServiceProvider =
    Provider<CoinGeckoMarket>((ref) => CoinGeckoMarket());

/// Top-50 markets by market cap. Cached at the provider level —
/// the screen refreshes by `ref.invalidate`-ing this.
final topMarketsProvider = FutureProvider<List<MarketCoin>>((ref) async {
  return ref.watch(marketServiceProvider).topCoins(perPage: 50);
});

/// Free-text search. Empty / blank queries short-circuit so we
/// never burn CoinGecko quota on a single keystroke.
final marketSearchProvider =
    FutureProvider.autoDispose.family<List<CoinSearchResult>, String>(
  (ref, query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <CoinSearchResult>[];
    return ref.watch(marketServiceProvider).search(trimmed);
  },
);

/// Identity key for the coin-chart provider — encodes both the
/// coin id and the chosen window so Riverpod dedupes per range.
class CoinChartKey {
  const CoinChartKey({required this.id, required this.range});
  final String id;
  final ChartRange range;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoinChartKey && other.id == id && other.range == range;

  @override
  int get hashCode => Object.hash(id, range);
}

/// Price series for a specific coin × range. AutoDispose so we
/// release memory when the detail screen pops.
final coinChartProvider = FutureProvider.autoDispose
    .family<CoinChartSeries, CoinChartKey>((ref, key) async {
  return ref.watch(marketServiceProvider).coinChart(key.id, days: key.range.days);
});
