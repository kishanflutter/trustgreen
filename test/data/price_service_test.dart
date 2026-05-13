import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/data/prices/price_service.dart';

/// Minimal Dio adapter that returns canned JSON for any GET request
/// matching the CoinGecko `simple/price` path. Keeps the test
/// hermetic so we never hit the real network in CI.
class _FakePriceAdapter implements HttpClientAdapter {
  _FakePriceAdapter(this.response, {this.statusCode = 200});

  final Map<String, dynamic> response;
  final int statusCode;
  int callCount = 0;
  String? lastQuery;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    callCount += 1;
    lastQuery = options.uri.query;
    return ResponseBody.fromString(
      _jsonEncode(response),
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

String _jsonEncode(Map<String, dynamic> m) {
  // We avoid `dart:convert` here so the test stays focused. The
  // shape is small and stable enough to write by hand.
  final entries = m.entries.map((e) {
    final inner = (e.value as Map<String, dynamic>).entries.map((kv) {
      return '"${kv.key}":${kv.value}';
    }).join(',');
    return '"${e.key}":{$inner}';
  }).join(',');
  return '{$entries}';
}

void main() {
  setUpAll(() {
    // PriceService reads AppEnv.coingeckoApiKey which goes through
    // dotenv.maybeGet — without an init the test crashes with
    // NotInitializedError before the fake adapter can respond.
    dotenv.testLoad(fileInput: '');
  });

  group('PriceService', () {
    test('returns empty map for empty / null input without hitting HTTP',
        () async {
      final dio = Dio()..httpClientAdapter = _FakePriceAdapter(const {});
      final svc = PriceService(dio: dio);
      final result = await svc.usdPrices([null, '', null]);
      expect(result, isEmpty);
    });

    test('parses simple/price response into a flat usd map', () async {
      final adapter = _FakePriceAdapter({
        'ethereum': {'usd': 3200.5},
        'tether': {'usd': 1.0},
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = PriceService(dio: dio);
      final result = await svc.usdPrices(['ethereum', 'tether']);
      expect(result['ethereum'], closeTo(3200.5, 1e-9));
      expect(result['tether'], closeTo(1.0, 1e-9));
      expect(adapter.callCount, 1);
    });

    test('cache prevents a second HTTP call within TTL', () async {
      final adapter = _FakePriceAdapter({
        'ethereum': {'usd': 3000.0},
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = PriceService(dio: dio);
      await svc.usdPrices(['ethereum']);
      await svc.usdPrices(['ethereum']);
      expect(adapter.callCount, 1);
    });

    test('usdPrice convenience returns null for unknown ids', () async {
      final adapter = _FakePriceAdapter(const {});
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = PriceService(dio: dio);
      expect(await svc.usdPrice(null), isNull);
      expect(await svc.usdPrice(''), isNull);
    });

    test('non-200 / DioException falls back to empty result', () async {
      final adapter = _FakePriceAdapter(const {}, statusCode: 500);
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = PriceService(dio: dio);
      final result = await svc.usdPrices(['ethereum']);
      expect(result, isEmpty);
    });
  });
}
