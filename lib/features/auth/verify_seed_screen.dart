import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/wallet/hd_wallet.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/onboarding_provider.dart';
import '../../state/providers.dart';
import '../../state/wallet_providers.dart';

/// Step 2: prove the user wrote down the mnemonic by picking the
/// correct word at three random positions.
class VerifySeedScreen extends ConsumerStatefulWidget {
  const VerifySeedScreen({super.key});

  @override
  ConsumerState<VerifySeedScreen> createState() => _VerifySeedScreenState();
}

class _Challenge {
  _Challenge({required this.position, required this.options});

  /// 1-based position of the word to verify.
  final int position;
  final List<String> options;
  String? picked;
}

class _VerifySeedScreenState extends ConsumerState<VerifySeedScreen> {
  static const int _challengeCount = 3;
  final _rng = Random.secure();

  List<_Challenge> _challenges = [];
  late List<String> _words;
  bool _busy = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromOnboarding());
  }

  void _initFromOnboarding() {
    final mnemonic = ref.read(onboardingProvider).newMnemonic;
    if (mnemonic == null) {
      // No mnemonic in state — user reached us via deep link or
      // refresh. Send them back to start.
      context.go(RoutePaths.createImport);
      return;
    }
    final words = mnemonic.split(' ');
    setState(() {
      _words = words;
      _challenges = _buildChallenges(words);
    });
  }

  List<_Challenge> _buildChallenges(List<String> words) {
    // Pick `_challengeCount` distinct positions in [0, words.length).
    final positions = <int>{};
    while (positions.length < _challengeCount) {
      positions.add(_rng.nextInt(words.length));
    }
    final sorted = positions.toList()..sort();
    final wordlist = HdWallet.englishWordlist;
    return sorted.map((i) {
      final correct = words[i];
      final distractors = <String>{};
      while (distractors.length < 3) {
        final candidate = wordlist[_rng.nextInt(wordlist.length)];
        if (candidate != correct) distractors.add(candidate);
      }
      final options = [correct, ...distractors]..shuffle(_rng);
      return _Challenge(position: i + 1, options: options);
    }).toList();
  }

  bool get _allAnswered =>
      _challenges.isNotEmpty &&
      _challenges.every((c) => c.picked != null);

  bool get _allCorrect =>
      _allAnswered &&
      _challenges.every((c) => c.picked == _words[c.position - 1]);

  void _pick(_Challenge c, String value) {
    setState(() {
      c.picked = value;
      _errorText = null;
    });
  }

  Future<void> _commit() async {
    if (!_allAnswered) return;
    if (!_allCorrect) {
      setState(() {
        _errorText = 'Some answers are wrong — review your phrase and retry.';
        for (final c in _challenges) {
          c.picked = null;
        }
      });
      return;
    }

    final onboarding = ref.read(onboardingProvider);
    final pin = onboarding.pendingPin;
    final mnemonic = onboarding.newMnemonic;
    final length = onboarding.length;
    if (pin == null || mnemonic == null || length == null) {
      setState(() => _errorText = 'Onboarding state was lost. Please start again.');
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      await repo.createWallet(
        name: onboarding.walletName ?? '',
        mnemonic: mnemonic,
        length: length,
        pin: pin,
      );

      ref.read(onboardingProvider.notifier).clear();
      ref.invalidate(hasAnyWalletProvider);
      ref.invalidate(walletsListProvider);
      ref.invalidate(activeWalletProvider);
      ref.invalidate(activeWalletIdProvider);
      ref.read(sessionProvider.notifier).unlock();

      if (!mounted) return;
      context.go(RoutePaths.success);
    } catch (e) {
      setState(() {
        _busy = false;
        _errorText = 'Could not save wallet: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_challenges.isEmpty) {
      return const PlaceholderScreen(title: 'Verify recovery phrase');
    }
    final responsive = Responsive.of(context);
    return SafeScaffold(
      title: 'Verify recovery phrase',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: PrimaryColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pick the correct word for each position to prove you '
                'wrote down your phrase.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              SizedBox(height: responsive.font(20)),
              for (final c in _challenges) ...[
                _ChallengeCard(
                  challenge: c,
                  onPick: (v) => _pick(c, v),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_errorText != null) ...[
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              PrimaryButton(
                label: 'Confirm',
                loading: _busy,
                onPressed: (_allAnswered && !_busy) ? _commit : null,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge, required this.onPick});

  final _Challenge challenge;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Word #${challenge.position}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in challenge.options)
                _WordChip(
                  label: option,
                  selected: challenge.picked == option,
                  onTap: () => onPick(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceElevated,
      borderRadius: AppRadius.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
