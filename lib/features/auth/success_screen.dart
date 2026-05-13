import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/primary_button.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  static const String _bgAsset = 'assets/images/wallet-success-circuit-bg.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(48),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x6600E676),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.onPrimary,
                          size: 56,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.6, 0.6),
                          end: const Offset(1, 1),
                          duration: 360.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 240.ms),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'You\'re all set',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your wallet is ready. Keep your seed phrase safe — '
                      'we cannot recover it for you.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Open wallet',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.go(RoutePaths.wallet),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
