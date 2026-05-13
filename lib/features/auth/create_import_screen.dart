import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/primary_button.dart';

/// First-run hub. The Expo source uses a circuit-bg JPEG as a
/// full-bleed cover background — we mirror that here with
/// [BoxFit.cover] so the asset is never stretched on any device.
class CreateImportScreen extends StatelessWidget {
  const CreateImportScreen({super.key});

  static const String _bgAsset = 'assets/images/onboarding-circuit-bg.jpg';
  static const String _logoAsset = 'assets/images/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed cover background — never hardcoded to screen
          // height; BoxFit.cover handles the aspect ratio.
          Image.asset(_bgAsset, fit: BoxFit.cover, alignment: Alignment.center),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x99000000),
                  Color(0xEE000000),
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: PrimaryColumn(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        _logoAsset,
                        width: responsive.font(96, maxScale: 1.2),
                        height: responsive.font(96, maxScale: 1.2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Trust Green Wallet',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Multi-chain wallet for Trust Green and EVM networks. '
                      'Hold, send, and explore — all in one place.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Create a new wallet',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push(RoutePaths.createWallet),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => context.push(RoutePaths.importWallet),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('I already have a wallet'),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .moveY(begin: 16, end: 0, duration: 400.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
