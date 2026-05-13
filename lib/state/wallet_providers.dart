import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallet/wallet_models.dart';
import 'providers.dart';

/// Full list of wallets stored on the device. Invalidate this after
/// every create / import / delete to force a re-read.
final walletsListProvider = FutureProvider<List<WalletMeta>>((ref) {
  return ref.watch(walletRepositoryProvider).listWallets();
});

/// Active wallet metadata. Returns `null` if no wallet has been
/// created yet or the user just deleted the last one.
final activeWalletProvider = FutureProvider<WalletMeta?>((ref) {
  return ref.watch(walletRepositoryProvider).activeWallet();
});

/// id-only stream — cheap, used by the dashboard to know which
/// wallet is selected without forcing a full read.
final activeWalletIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(walletRepositoryProvider).activeWalletId();
});
