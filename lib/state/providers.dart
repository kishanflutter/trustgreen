import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/storage/secure_storage.dart';

// ── Core singletons ───────────────────────────────────────────────
final secureStorageProvider = Provider<SecureStorage>(
  (ref) => SecureStorage(),
);

// ── Onboarding readiness ──────────────────────────────────────────
/// `true` when the local stores have hydrated and the app can make
/// routing decisions. Phase-1 stub: always immediately ready.
final appBootProvider = FutureProvider<void>((ref) async {
  // Hook here later to await preference / wallet hydration.
});

/// `true` if a PIN has been set up. Re-read on demand by the router
/// redirect guard.
final hasPinProvider = FutureProvider<bool>((ref) {
  return ref.watch(secureStorageProvider).hasPin();
});

/// `true` if at least one wallet exists in secure storage.
final hasAnyWalletProvider = FutureProvider<bool>((ref) {
  return ref.watch(secureStorageProvider).hasAnyWallet();
});

// ── Session ───────────────────────────────────────────────────────
/// In-memory unlock flag. The Expo source persists `lockAfterMinutes`
/// but `unlocked` is intentionally non-persisted so a cold start
/// always re-prompts for the PIN.
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
