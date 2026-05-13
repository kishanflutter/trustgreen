import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Full-width primary CTA. Pulls colors and min-height from
/// [FilledButtonThemeData] but adds a built-in loading state and a
/// leading icon slot.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    final child = loading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    final button = FilledButton(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background ?? AppColors.primary,
        foregroundColor: foreground ?? AppColors.onPrimary,
        disabledBackgroundColor: AppColors.surfaceElevated,
        disabledForegroundColor: AppColors.textTertiary,
        minimumSize: const Size.fromHeight(kPrimaryButtonHeight),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      child: child,
    );

    return expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
