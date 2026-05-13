import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/wallet/hd_wallet.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/onboarding_provider.dart';
import '../../state/providers.dart';
import '../../state/wallet_providers.dart';

/// Imports an existing 12 / 18 / 24-word mnemonic. Live validation
/// against the BIP-39 English wordlist colours each word as the
/// user types.
class ImportWalletScreen extends ConsumerStatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  ConsumerState<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen> {
  final _controller = TextEditingController();
  final _nameController = TextEditingController();

  List<bool> _perWordValid = const [];
  bool _checksumValid = false;
  bool _busy = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _perWordValid = HdWallet.validateAgainstWordlist(value);
      _checksumValid = HdWallet.isValid(value);
      _errorText = null;
    });
  }

  String? _lengthHint() {
    final n = _perWordValid.length;
    if (n == 0) return null;
    final mnemonicLength = MnemonicLength.tryFromWordCount(n);
    if (mnemonicLength == null && (n == 15 || n == 21)) {
      return '$n words — Trust Green supports 12 / 18 / 24 only.';
    }
    if (mnemonicLength == null) {
      return '$n / 12, 18, or 24 words';
    }
    if (!_checksumValid) {
      return '$n words — checksum or wordlist mismatch';
    }
    return '$n words — valid';
  }

  Future<void> _import() async {
    if (_busy) return;
    final mnemonic = HdWallet.normaliseMnemonic(_controller.text);

    if (!HdWallet.isValid(mnemonic)) {
      setState(() =>
          _errorText = 'Recovery phrase is invalid. Check spelling and order.');
      return;
    }
    final length =
        MnemonicLength.tryFromWordCount(mnemonic.split(' ').length);
    if (length == null) {
      setState(() => _errorText = 'Only 12 / 18 / 24-word phrases are supported.');
      return;
    }

    final onboarding = ref.read(onboardingProvider);
    final pin = onboarding.pendingPin;
    if (pin == null) {
      setState(() =>
          _errorText = 'Onboarding state was lost. Please start again.');
      return;
    }

    setState(() {
      _busy = true;
      _errorText = null;
    });

    try {
      final repo = ref.read(walletRepositoryProvider);
      await repo.createWallet(
        name: _nameController.text,
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
        _errorText = 'Could not import wallet: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final hint = _lengthHint();

    return SafeScaffold(
      title: 'Import wallet',
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
                'Paste or type your 12 / 18 / 24-word recovery phrase. '
                'Words are validated against the BIP-39 list as you type.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              SizedBox(height: responsive.font(20)),
              const _SectionLabel('Recovery phrase'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                maxLines: 5,
                minLines: 4,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'rocket abandon hint zone… (separate words by spaces)',
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hint,
                  style: TextStyle(
                    color: _checksumValid
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              if (_perWordValid.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _WordValidityRow(perWordValid: _perWordValid),
              ],
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel('Wallet name (optional)'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameController,
                maxLength: 40,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Imported wallet',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_errorText != null) ...[
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              PrimaryButton(
                label: 'Import wallet',
                icon: Icons.download_rounded,
                loading: _busy,
                onPressed: (_checksumValid && !_busy) ? _import : null,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _WordValidityRow extends StatelessWidget {
  const _WordValidityRow({required this.perWordValid});
  final List<bool> perWordValid;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < perWordValid.length; i++)
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: perWordValid[i]
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.error.withValues(alpha: 0.18),
              border: Border.all(
                color: perWordValid[i] ? AppColors.primary : AppColors.error,
              ),
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: perWordValid[i] ? AppColors.primary : AppColors.error,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
