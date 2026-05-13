import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/market/market_models.dart';

void main() {
  group('MarketCoin.fromJson', () {
    test('parses canonical payload with sparkline', () {
      final coin = MarketCoin.fromJson({
        'id': 'ethereum',
        'symbol': 'eth',
        'name': 'Ethereum',
        'image': 'https://e.com/eth.png',
        'current_price': 3000.5,
        'market_cap_rank': 2,
        'price_change_percentage_24h': -1.25,
        'sparkline_in_7d': {
          'price': [10, 11, 12, 13, 14],
        },
      });
      expect(coin.id, 'ethereum');
      expect(coin.tickerUpper, 'ETH');
      expect(coin.name, 'Ethereum');
      expect(coin.priceUsd, closeTo(3000.5, 1e-9));
      expect(coin.marketCapRank, 2);
      expect(coin.priceChange24hPct, closeTo(-1.25, 1e-9));
      expect(coin.sparkline7d, equals([10.0, 11.0, 12.0, 13.0, 14.0]));
    });

    test('tolerates missing sparkline + numeric coercion', () {
      final coin = MarketCoin.fromJson({
        'id': 'bitcoin',
        'symbol': 'btc',
        'name': 'Bitcoin',
        'image': '',
        'current_price': 65000,
      });
      expect(coin.sparkline7d, isEmpty);
      expect(coin.priceChange24hPct, isNull);
      expect(coin.marketCapRank, isNull);
      expect(coin.priceUsd, closeTo(65000, 1e-9));
    });
  });

  group('CoinChartSeries.fromJson', () {
    test('parses prices array', () {
      final series = CoinChartSeries.fromJson({
        'prices': [
          [1715600000000, 3000.0],
          [1715603600000, 3100.0],
          [1715607200000, 2950.0],
        ],
      });
      expect(series.points.length, 3);
      expect(series.minPrice, closeTo(2950.0, 1e-9));
      expect(series.maxPrice, closeTo(3100.0, 1e-9));
    });

    test('returns empty series when prices missing', () {
      final series = CoinChartSeries.fromJson(const {});
      expect(series.isEmpty, isTrue);
    });
  });

  group('CoinSearchResult.fromJson', () {
    test('extracts id, symbol, name, thumb, rank', () {
      final r = CoinSearchResult.fromJson({
        'id': 'solana',
        'symbol': 'sol',
        'name': 'Solana',
        'thumb': 'https://e.com/sol.png',
        'market_cap_rank': 4,
      });
      expect(r.id, 'solana');
      expect(r.tickerUpper, 'SOL');
      expect(r.name, 'Solana');
      expect(r.marketCapRank, 4);
    });
  });
}
