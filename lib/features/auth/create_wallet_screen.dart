import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/wallet/hd_wallet.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/onboarding_provider.dart';

/// Step 1 of the create flow: pick word count, generate mnemonic,
/// let the user copy / write it down, then push to verify-seed.
class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  MnemonicLength _length = MnemonicLength.words12;
  HdWallet? _wallet;
  bool _confirmed = false;
  bool _revealed = true;
  String _walletName = '';

  void _generate() {
    setState(() {
      _wallet = HdWallet.generate(length: _length);
      _confirmed = false;
    });
  }

  void _changeLength(MnemonicLength next) {
    if (next == _length) return;
    setState(() {
      _length = next;
      // Drop the existing mnemonic — the user must explicitly press
      // Generate again so they can't accidentally proceed with a
      // mnemonic of the wrong length.
      _wallet = null;
      _confirmed = false;
    });
  }

  Future<void> _copy() async {
    final m = _wallet?.mnemonic;
    if (m == null) return;
    await Clipboard.setData(ClipboardData(text: m));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery phrase copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _continueToVerify() {
    final w = _wallet;
    if (w == null) return;
    final onboarding = ref.read(onboardingProvider.notifier);
    onboarding.setMnemonic(w.mnemonic, w.length);
    if (_walletName.trim().isNotEmpty) {
      onboarding.setWalletName(_walletName.trim());
    }
    context.push(RoutePaths.verifySeed);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SafeScaffold(
      title: 'Create wallet',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: PrimaryColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('Recovery phrase length'),
              const SizedBox(height: AppSpacing.sm),
              _LengthSelector(value: _length, onChanged: _changeLength),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Wallet name (optional)'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Main wallet',
                ),
                maxLength: 40,
                onChanged: (v) => _walletName = v,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_wallet == null) ...[
                _SecurityCallout(length: _length),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Generate recovery phrase',
                  icon: Icons.auto_awesome,
                  onPressed: _generate,
                ),
              ] else ...[
                _SectionLabel(
                  'Your ${_wallet!.length.wordCount}-word recovery phrase',
                ),
                const SizedBox(height: AppSpacing.sm),
                _MnemonicGrid(
                  words: _wallet!.words,
                  revealed: _revealed,
                  onToggleReveal: () =>
                      setState(() => _revealed = !_revealed),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('New phrase'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SecurityCallout(length: _wallet!.length),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _confirmed,
                  onChanged: (v) => setState(() => _confirmed = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  checkColor: AppColors.onPrimary,
                  title: const Text(
                    'I have written down or safely stored my recovery phrase',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                SizedBox(height: responsive.font(16)),
                PrimaryButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _confirmed ? _continueToVerify : null,
                ),
              ],
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

class _LengthSelector extends StatelessWidget {
  const _LengthSelector({required this.value, required this.onChanged});

  final MnemonicLength value;
  final ValueChanged<MnemonicLength> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final v in MnemonicLength.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: v == value
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: AppRadius.brSm,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${v.wordCount} words',
                    style: TextStyle(
                      color: v == value
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MnemonicGrid extends StatelessWidget {
  const _MnemonicGrid({
    required this.words,
    required this.revealed,
    required this.onToggleReveal,
  });

  final List<String> words;
  final bool revealed;
  final VoidCallback onToggleReveal;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3.2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: words.length,
            itemBuilder: (context, i) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.brSm,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${i + 1}.',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      revealed ? words[i] : '•••',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: AppColors.surfaceElevated,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: revealed ? 'Hide phrase' : 'Show phrase',
              icon: Icon(
                revealed ? Icons.visibility_off_outlined : Icons.visibility,
                size: 18,
                color: AppColors.textPrimary,
              ),
              onPressed: onToggleReveal,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityCallout extends StatelessWidget {
  const _SecurityCallout({required this.length});
  final MnemonicLength length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text:
                        'Your ${length.wordCount}-word recovery phrase is the only way to ',
                  ),
                  const TextSpan(
                    text: 'restore your wallet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text:
                      '. Write it down, store it offline, and never share it with anyone. '
                      'Trust Green can never recover it for you.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
