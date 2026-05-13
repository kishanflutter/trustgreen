/// Top-level coin model returned by CoinGecko's `/coins/markets`
/// endpoint. We only keep the fields the Market tab actually
/// renders so future API additions don't break parsing.
class MarketCoin {
  const MarketCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.imageUrl,
    required this.priceUsd,
    required this.marketCapRank,
    required this.priceChange24hPct,
    required this.sparkline7d,
  });

  /// CoinGecko coin id (`ethereum`, `bitcoin`, …) — used as the
  /// coin-detail screen's route key.
  final String id;

  /// Lowercase ticker (`eth`, `btc`).
  final String symbol;

  /// Full name (`Ethereum`).
  final String name;

  /// URL of the small logo on CoinGecko's CDN.
  final String imageUrl;

  final double priceUsd;
  final int? marketCapRank;
  final double? priceChange24hPct;

  /// 168-entry hourly price array from CoinGecko's
  /// `sparkline_in_7d`. Empty when the API omits it.
  final List<double> sparkline7d;

  /// Display ticker uppercased (`ETH`, `BTC`).
  String get tickerUpper => symbol.toUpperCase();

  factory MarketCoin.fromJson(Map<String, dynamic> json) {
    final spark = <double>[];
    final s = json['sparkline_in_7d'];
    if (s is Map && s['price'] is List) {
      for (final p in s['price'] as List) {
        if (p is num) spark.add(p.toDouble());
      }
    }
    return MarketCoin(
      id: (json['id'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      priceUsd: (json['current_price'] as num?)?.toDouble() ?? 0,
      marketCapRank: (json['market_cap_rank'] as num?)?.toInt(),
      priceChange24hPct:
          (json['price_change_percentage_24h'] as num?)?.toDouble(),
      sparkline7d: spark,
    );
  }
}

/// Short-form coin returned by `/search?query=`. Has just enough to
/// hop to the detail screen.
class CoinSearchResult {
  const CoinSearchResult({
    required this.id,
    required this.symbol,
    required this.name,
    required this.thumbUrl,
    this.marketCapRank,
  });

  final String id;
  final String symbol;
  final String name;
  final String thumbUrl;
  final int? marketCapRank;

  String get tickerUpper => symbol.toUpperCase();

  factory CoinSearchResult.fromJson(Map<String, dynamic> json) {
    return CoinSearchResult(
      id: (json['id'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      thumbUrl: (json['thumb'] ?? '').toString(),
      marketCapRank: (json['market_cap_rank'] as num?)?.toInt(),
    );
  }
}

/// Time-series chart data for `CoinDetailScreen`. Returned by
/// CoinGecko's `/market_chart?vs_currency=usd&days={n}` endpoint.
class CoinChartSeries {
  const CoinChartSeries({required this.points});

  /// `(epochMillis, priceUsd)` pairs, ordered oldest → newest.
  final List<(int, double)> points;

  bool get isEmpty => points.isEmpty;

  double get minPrice =>
      points.isEmpty ? 0 : points.map((e) => e.$2).reduce((a, b) => a < b ? a : b);

  double get maxPrice =>
      points.isEmpty ? 0 : points.map((e) => e.$2).reduce((a, b) => a > b ? a : b);

  factory CoinChartSeries.fromJson(Map<String, dynamic> json) {
    final raw = json['prices'];
    final out = <(int, double)>[];
    if (raw is List) {
      for (final p in raw) {
        if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
          out.add(((p[0] as num).toInt(), (p[1] as num).toDouble()));
        }
      }
    }
    return CoinChartSeries(points: out);
  }
}

/// Supported chart windows shown in the coin detail screen.
enum ChartRange { day(1, '24h'), week(7, '7d'), month(30, '30d'), year(365, '1y');

  const ChartRange(this.days, this.label);

  final int days;
  final String label;
}
