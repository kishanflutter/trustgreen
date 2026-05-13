import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Row of PIN dots. Empty positions are outlined; filled positions
/// are solid [AppColors.primary]. Animates each dot in / out, and
/// shakes the whole row when [error] flips to `true`.
class PinBoxes extends StatefulWidget {
  const PinBoxes({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
    this.dotSize = 18,
    this.spacing = 18,
  });

  /// Total number of dot positions (e.g. 6 for a 6-digit PIN).
  final int length;

  /// Number of currently filled positions (0..length).
  final int filled;

  /// When toggled to `true` triggers a one-shot shake.
  final bool error;

  final double dotSize;
  final double spacing;

  @override
  State<PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<PinBoxes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(PinBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error && !oldWidget.error) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedFilled = widget.filled.clamp(0, widget.length);
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // Damped sine: 3 oscillations, amplitude tapers to 0.
        final t = _shake.value;
        final dx = t == 0 ? 0.0 : (1 - t) * 6 * math.sin(t * 3 * 2 * math.pi);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (i) {
          final isFilled = i < clampedFilled;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? (widget.error ? AppColors.error : AppColors.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: widget.error
                      ? AppColors.error
                      : (isFilled ? AppColors.primary : AppColors.border),
                  width: 1.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
