import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallet/hd_wallet.dart';

/// Transient state for the create-wallet / import-wallet flow.
///
/// The PIN entered during initial setup is held here in memory so
/// the verify-seed step can encrypt the mnemonic without re-prompting
/// the user. Both fields are cleared as soon as the success screen
/// finishes — they never touch disk.
class OnboardingState {
  const OnboardingState({
    this.pendingPin,
    this.newMnemonic,
    this.length,
    this.walletName,
  });

  /// PIN typed during first-launch setup. Kept until the first
  /// wallet is committed, then wiped.
  final String? pendingPin;

  /// Mnemonic just generated (or pasted in the import flow).
  final String? newMnemonic;

  /// Word count selected on the create-wallet screen, or inferred
  /// from the imported phrase.
  final MnemonicLength? length;

  /// User-chosen wallet label (empty → repository assigns a default).
  final String? walletName;

  OnboardingState copyWith({
    String? pendingPin,
    String? newMnemonic,
    MnemonicLength? length,
    String? walletName,
  }) =>
      OnboardingState(
        pendingPin: pendingPin ?? this.pendingPin,
        newMnemonic: newMnemonic ?? this.newMnemonic,
        length: length ?? this.length,
        walletName: walletName ?? this.walletName,
      );
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  void setPendingPin(String pin) =>
      state = state.copyWith(pendingPin: pin);

  void setMnemonic(String mnemonic, MnemonicLength length) =>
      state = state.copyWith(newMnemonic: mnemonic, length: length);

  void setWalletName(String name) =>
      state = state.copyWith(walletName: name);

  /// Resets to an empty state. Called on success and on every "back
  /// to start" navigation.
  void clear() => state = const OnboardingState();
}

final onboardingProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
  (ref) => OnboardingController(),
);
