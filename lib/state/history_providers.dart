import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/history/etherscan_v2_client.dart';
import '../data/history/tx_history_models.dart';
import 'balance_providers.dart';
import 'chain_providers.dart';

/// Singleton Etherscan V2 client.
final etherscanClientProvider = Provider<EtherscanV2Client>(
  (ref) => EtherscanV2Client(),
);

/// `true` if the active chain is covered by Etherscan V2 — the UI
/// uses this to swap between the list view and the "Only available
/// on the chain explorer" fallback.
final activeChainSupportsHistoryProvider = Provider<bool>((ref) {
  final chain = ref.watch(activeChainProvider);
  final client = ref.watch(etherscanClientProvider);
  return client.supportsChain(chain);
});

/// History for a single (chain, address) pair.
///
/// `autoDispose` so we don't keep stale lists for every wallet the
/// user has ever opened. The dashboard / history screen keep the
/// provider alive while mounted; pull-to-refresh issues an
/// `invalidate`.
final txHistoryProvider = FutureProvider.autoDispose
    .family<List<TxHistoryItem>, BalanceKey>((ref, key) async {
  final client = ref.watch(etherscanClientProvider);
  final chainList = ref.watch(chainListProvider);
  final chain = chainList.firstWhere(
    (c) => c.id == key.chainId,
    orElse: () => chainList.first,
  );
  return client.fetchCombinedHistory(
    chain: chain,
    address: key.address,
  );
});
