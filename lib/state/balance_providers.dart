import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chains/chain_config.dart';
import '../data/rpc/rpc_service.dart';
import 'chain_providers.dart';

/// Identity key for balance lookups. Equality matters here so
/// Riverpod can deduplicate concurrent requests for the same
/// (chain, address) pair.
class BalanceKey {
  const BalanceKey({required this.chainId, required this.address});

  /// Internal chain id (`'eth'`, `'bnb'`, …) — matches
  /// [ChainDefinition.id].
  final String chainId;

  /// EIP-55 wallet address (`0xAbC…`).
  final String address;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceKey &&
          other.chainId == chainId &&
          other.address.toLowerCase() == address.toLowerCase();

  @override
  int get hashCode => Object.hash(chainId, address.toLowerCase());
}

ChainDefinition _resolveChainRef(Ref ref, String chainId) {
  for (final c in ref.read(chainListProvider)) {
    if (c.id == chainId) return c;
  }
  return ChainCatalog.defaultChain();
}

/// Native coin balance for (chain, address). Refetches every time
/// the family arg changes; the dashboard explicitly invalidates this
/// on pull-to-refresh.
final nativeBalanceProvider =
    FutureProvider.family<TokenAmount, BalanceKey>((ref, key) async {
  final rpc = ref.watch(rpcServiceProvider);
  final chain = _resolveChainRef(ref, key.chainId);
  return rpc.getNativeBalance(chain: chain, address: key.address);
});

/// USDT (chain-specific) balance for (chain, address).
final usdtBalanceProvider =
    FutureProvider.family<TokenAmount, BalanceKey>((ref, key) async {
  final rpc = ref.watch(rpcServiceProvider);
  final chain = _resolveChainRef(ref, key.chainId);
  return rpc.getTokenBalance(
    chain: chain,
    tokenAddress: chain.usdt.address,
    tokenDecimals: chain.usdt.decimals,
    address: key.address,
  );
});

/// USD prices keyed by a sorted set of CoinGecko ids. Always returns
/// a `Map<id, usd>` — missing ids are simply absent.
final usdPricesProvider =
    FutureProvider.family<Map<String, double>, List<String>>(
  (ref, ids) async {
    if (ids.isEmpty) return const <String, double>{};
    final service = ref.watch(priceServiceProvider);
    return service.usdPrices(ids);
  },
);

/// Convenience for code that already has a [WidgetRef]: invalidates
/// every balance + price family entry. Used by pull-to-refresh.
void invalidateAllBalances(WidgetRef ref) {
  ref.invalidate(nativeBalanceProvider);
  ref.invalidate(usdtBalanceProvider);
  ref.invalidate(usdPricesProvider);
}
