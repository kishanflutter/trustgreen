import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/chains/chain_config.dart';
import '../data/prices/price_service.dart';
import '../data/rpc/rpc_service.dart';
import '../data/tx/send_pipeline.dart';
import 'providers.dart';

/// All chains that ship with the build. Identity-stable (used as the
/// id-source for chain switching, asset rows, send-token picker).
final chainListProvider = Provider<List<ChainDefinition>>((ref) {
  return ChainCatalog.defaults();
});

/// Singleton RPC pool — disposed when the [ProviderContainer] is
/// torn down.
final rpcServiceProvider = Provider<RpcService>((ref) {
  final svc = RpcService.instance;
  ref.onDispose(svc.dispose);
  return svc;
});

/// Singleton CoinGecko client.
final priceServiceProvider = Provider<PriceService>((ref) => PriceService());

/// Sign-and-broadcast pipeline. Each call decrypts the wallet
/// secret with the user-provided PIN, signs the transaction, and
/// broadcasts via [RpcService].
final txPipelineProvider = Provider<TxPipeline>((ref) {
  return TxPipeline(
    walletRepo: ref.watch(walletRepositoryProvider),
    rpc: ref.watch(rpcServiceProvider),
  );
});

const String _kActiveChainPref = 'tg_active_chain_id';

/// Persisted "active chain" selector. Backed by [SharedPreferences]
/// so the user's choice survives app restarts.
class ActiveChainController extends StateNotifier<String> {
  ActiveChainController(this._prefs, String initialId) : super(initialId);

  final SharedPreferences _prefs;

  Future<void> setActive(String chainId) async {
    if (state == chainId) return;
    state = chainId;
    await _prefs.setString(_kActiveChainPref, chainId);
  }
}

/// Provider for the persisted active chain id. The async version is
/// used during boot — UI code should prefer [activeChainProvider]
/// (sync, derived) which falls back to the default chain.
final activeChainControllerProvider =
    StateNotifierProvider<ActiveChainController, String>((ref) {
  throw StateError(
    'activeChainControllerProvider must be overridden in main() after '
    'SharedPreferences is initialised.',
  );
});

/// Fully resolved active chain. Returns the default chain if the
/// stored id no longer matches any chain in the catalog (e.g. after a
/// build that removed a chain).
final activeChainProvider = Provider<ChainDefinition>((ref) {
  final id = ref.watch(activeChainControllerProvider);
  return ChainCatalog.byId(id) ?? ChainCatalog.defaultChain();
});

/// One-shot loader used by `main.dart` to read the persisted id
/// before the [ProviderContainer] is built.
Future<String> loadInitialActiveChainId() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_kActiveChainPref);
  if (stored == null || ChainCatalog.byId(stored) == null) {
    return ChainCatalog.defaultChain().id;
  }
  return stored;
}
