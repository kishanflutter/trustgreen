import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed accessor for the .env file shipped as an asset.
///
/// Mirrors the `expo.extra` keys from the Expo source so the two
/// projects stay aligned. Missing values fall back to safe defaults.
class AppEnv {
  AppEnv._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String _get(String key, String fallback) {
    final v = dotenv.maybeGet(key);
    if (v == null || v.isEmpty) return fallback;
    return v;
  }

  // ── Trust Green chain ────────────────────────────────────────────
  static int get trustGreenChainId =>
      int.tryParse(_get('TRUSTGREEN_CHAIN_ID', '888888')) ?? 888888;

  static String get trustGreenRpcUrl =>
      _get('TRUSTGREEN_RPC_URL', 'https://rpc.trustgreen.local');

  static String get trustGreenExplorerUrl =>
      _get('TRUSTGREEN_EXPLORER_URL', 'https://explorer.trustgreen.local');

  static String get trustGreenSymbol => _get('TRUSTGREEN_SYMBOL', 'TG');

  static String get trustGreenUsdt => _get(
        'TRUSTGREEN_USDT',
        '0x0000000000000000000000000000000000000001',
      );

  static int get trustGreenUsdtDecimals {
    final parsed = int.tryParse(_get('TRUSTGREEN_USDT_DECIMALS', '18')) ?? 18;
    return parsed.clamp(0, 18);
  }

  // ── Third-party APIs ─────────────────────────────────────────────
  static String? get coingeckoApiKey {
    final v = dotenv.maybeGet('COINGECKO_API_KEY');
    return (v == null || v.isEmpty) ? null : v;
  }

  static String get newsApiUrl =>
      _get('NEWS_API_URL', 'https://cryptonews-api.com');

  static String? get newsApiKey {
    final v = dotenv.maybeGet('NEWS_API_KEY');
    return (v == null || v.isEmpty) ? null : v;
  }

  static String get newsSection => _get('NEWS_SECTION', 'general');

  /// Etherscan V2 API key. Optional — the free tier allows
  /// 1 request / 5 seconds without a key.
  static String? get etherscanApiKey {
    final v = dotenv.maybeGet('ETHERSCAN_API_KEY');
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Default URL for the in-app browser. Falls back to CoinGecko.
  static String get browserHomeUrl =>
      _get('BROWSER_HOME_URL', 'https://www.coingecko.com');
}
