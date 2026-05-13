import '../../core/env/app_env.dart';

/// Single, immutable description of a supported chain. Mirrors the
/// shape of `config/chains.ts` in the Expo source.
class ChainDefinition {
  const ChainDefinition({
    required this.id,
    required this.chainId,
    required this.name,
    required this.rpcUrl,
    required this.symbol,
    required this.decimals,
    required this.explorerUrl,
    required this.logoKey,
    required this.usdt,
    this.coingeckoId,
    this.testnet = false,
  });

  final String id;
  final int chainId;
  final String name;
  final String rpcUrl;
  final String symbol;
  final int decimals;
  final String explorerUrl;
  final String logoKey;
  final UsdtDefinition usdt;

  /// CoinGecko coin id for the native token (e.g. `ethereum`,
  /// `binancecoin`). `null` means the chain's native token has no
  /// public USD price (testnets, custom chains).
  final String? coingeckoId;

  /// `true` for chains whose RPC + USDT contract are on a test
  /// network. UI may render a small badge.
  final bool testnet;

  /// Asset path for the chain logo (matches `assets/chains/*.png`).
  String get logoAsset => 'assets/chains/$logoKey.png';

  /// Returns the address tx URL on the chain's block explorer.
  String addressExplorerUrl(String address) {
    final base = explorerUrl.endsWith('/')
        ? explorerUrl.substring(0, explorerUrl.length - 1)
        : explorerUrl;
    return '$base/address/$address';
  }

  /// Returns the tx hash URL on the chain's block explorer.
  String txExplorerUrl(String hash) {
    final base = explorerUrl.endsWith('/')
        ? explorerUrl.substring(0, explorerUrl.length - 1)
        : explorerUrl;
    return '$base/tx/$hash';
  }
}

class UsdtDefinition {
  const UsdtDefinition({
    required this.address,
    required this.decimals,
    this.symbol = 'USDT',
    this.coingeckoId = 'tether',
  });

  final String address;
  final int decimals;
  final String symbol;

  /// CoinGecko id for the stablecoin (usually `tether`).
  final String coingeckoId;
}

/// Curated chain defaults. **Verify contracts before mainnet use.**
class ChainCatalog {
  ChainCatalog._();

  static List<ChainDefinition> defaults() => [
        ChainDefinition(
          id: 'trustgreen',
          chainId: AppEnv.trustGreenChainId,
          name: 'Trust Green',
          rpcUrl: AppEnv.trustGreenRpcUrl,
          symbol: AppEnv.trustGreenSymbol,
          decimals: 18,
          explorerUrl: AppEnv.trustGreenExplorerUrl,
          logoKey: 'trustgreen',
          // The Trust Green network is BSC-testnet-backed today; the
          // native "TG" token has no public USD price.
          coingeckoId: null,
          testnet: true,
          usdt: UsdtDefinition(
            address: AppEnv.trustGreenUsdt,
            decimals: AppEnv.trustGreenUsdtDecimals,
          ),
        ),
        const ChainDefinition(
          id: 'bnb',
          chainId: 56,
          name: 'BNB Smart Chain',
          rpcUrl: 'https://bsc-dataseed.binance.org',
          symbol: 'BNB',
          decimals: 18,
          explorerUrl: 'https://bscscan.com',
          logoKey: 'bnb',
          coingeckoId: 'binancecoin',
          usdt: UsdtDefinition(
            address: '0x55d398326f99059fF775485246999027B3197955',
            decimals: 18,
          ),
        ),
        const ChainDefinition(
          id: 'eth',
          chainId: 1,
          name: 'Ethereum',
          rpcUrl: 'https://cloudflare-eth.com',
          symbol: 'ETH',
          decimals: 18,
          explorerUrl: 'https://etherscan.io',
          logoKey: 'eth',
          coingeckoId: 'ethereum',
          usdt: UsdtDefinition(
            address: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
            decimals: 6,
          ),
        ),
        const ChainDefinition(
          id: 'avax',
          chainId: 43114,
          name: 'Avalanche C-Chain',
          rpcUrl: 'https://api.avax.network/ext/bc/C/rpc',
          symbol: 'AVAX',
          decimals: 18,
          explorerUrl: 'https://snowtrace.io',
          logoKey: 'avax',
          coingeckoId: 'avalanche-2',
          usdt: UsdtDefinition(
            address: '0x9702230A8Ea53601f5cD2dc00fDBC13d4dF4A8c7',
            decimals: 6,
          ),
        ),
        const ChainDefinition(
          id: 'polygon',
          chainId: 137,
          name: 'Polygon',
          rpcUrl: 'https://polygon-rpc.com',
          symbol: 'MATIC',
          decimals: 18,
          explorerUrl: 'https://polygonscan.com',
          logoKey: 'polygon',
          coingeckoId: 'matic-network',
          usdt: UsdtDefinition(
            address: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
            decimals: 6,
          ),
        ),
        const ChainDefinition(
          id: 'arbitrum',
          chainId: 42161,
          name: 'Arbitrum One',
          rpcUrl: 'https://arb1.arbitrum.io/rpc',
          symbol: 'ETH',
          decimals: 18,
          explorerUrl: 'https://arbiscan.io',
          logoKey: 'arbitrum',
          coingeckoId: 'ethereum',
          usdt: UsdtDefinition(
            address: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
            decimals: 6,
          ),
        ),
        const ChainDefinition(
          id: 'optimism',
          chainId: 10,
          name: 'Optimism',
          rpcUrl: 'https://mainnet.optimism.io',
          symbol: 'ETH',
          decimals: 18,
          explorerUrl: 'https://optimistic.etherscan.io',
          logoKey: 'optimism',
          coingeckoId: 'ethereum',
          usdt: UsdtDefinition(
            address: '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58',
            decimals: 6,
          ),
        ),
      ];

  static ChainDefinition defaultChain() => defaults().first;

  static ChainDefinition? byChainId(int chainId) {
    for (final c in defaults()) {
      if (c.chainId == chainId) return c;
    }
    return null;
  }

  /// Looks up a chain by its internal id string (`'trustgreen'`,
  /// `'bnb'`, …). Returns `null` for unknown ids.
  static ChainDefinition? byId(String id) {
    for (final c in defaults()) {
      if (c.id == id) return c;
    }
    return null;
  }
}
