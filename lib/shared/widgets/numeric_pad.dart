import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tokens.dart';

/// 3×4 numeric keypad used by the PIN screen. Layout:
///
/// ```
/// 1 2 3
/// 4 5 6
/// 7 8 9
///   0 ⌫
/// ```
///
/// Provides light haptic feedback on every press and disables input
/// while [enabled] is false (e.g. during PIN verification).
class NumericPad extends StatelessWidget {
  const NumericPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.maxWidth = 360,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row([_digit(1), _digit(2), _digit(3)]),
            _row([_digit(4), _digit(5), _digit(6)]),
            _row([_digit(7), _digit(8), _digit(9)]),
            _row([
              const _PadCellSpacer(),
              _digit(0),
              _PadKey(
                enabled: enabled,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onBackspace();
                },
                child: const Icon(
                  Icons.backspace_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _digit(int n) => _PadKey(
        enabled: enabled,
        onPressed: () {
          HapticFeedback.selectionClick();
          onDigit(n);
        },
        child: Text(
          '$n',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      );

  Widget _row(List<Widget> cells) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (final c in cells) Expanded(child: c)],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.onPressed,
    required this.enabled,
    required this.child,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Material(
          color: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: AppRadius.brMd,
            child: Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _PadCellSpacer extends StatelessWidget {
  const _PadCellSpacer();
  @override
  Widget build(BuildContext context) =>
      const AspectRatio(aspectRatio: 1.6, child: SizedBox.shrink());
}
