import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth/pin_service.dart';
import '../data/storage/secure_storage.dart';
import '../data/wallet/wallet_repository.dart';

// ── Core singletons ───────────────────────────────────────────────
final secureStorageProvider = Provider<SecureStorage>(
  (ref) => SecureStorage(),
);

final pinServiceProvider = Provider<PinService>(
  (ref) => PinService(ref.watch(secureStorageProvider)),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(secureStorageProvider)),
);

// ── Onboarding readiness ──────────────────────────────────────────
/// Hook for any future hydration step (DB warm-up, migrations).
/// Currently returns immediately so the BootController routes on
/// the next frame.
final appBootProvider = FutureProvider<void>((ref) async {});

/// `true` if a PIN has been set. Read by [BootController] and after
/// every onboarding mutation via `ref.invalidate`.
final hasPinProvider = FutureProvider<bool>((ref) {
  return ref.watch(pinServiceProvider).hasPin();
});

/// `true` if at least one wallet exists. Invalidated after wallet
/// creation / deletion.
final hasAnyWalletProvider = FutureProvider<bool>((ref) {
  return ref.watch(secureStorageProvider).hasAnyWallet();
});

// ── Session ───────────────────────────────────────────────────────
class SessionState {
  const SessionState({this.unlocked = false, this.lastUnlockAt});

  final bool unlocked;
  final DateTime? lastUnlockAt;

  SessionState copyWith({bool? unlocked, DateTime? lastUnlockAt}) =>
      SessionState(
        unlocked: unlocked ?? this.unlocked,
        lastUnlockAt: lastUnlockAt ?? this.lastUnlockAt,
      );
}

class SessionController extends StateNotifier<SessionState> {
  SessionController() : super(const SessionState());

  void unlock() => state = state.copyWith(
        unlocked: true,
        lastUnlockAt: DateTime.now(),
      );

  void lock() => state = const SessionState();

  void touch() {
    if (state.unlocked) {
      state = state.copyWith(lastUnlockAt: DateTime.now());
    }
  }
}

final sessionProvider =
    StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(),
);
