import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Renders a chain logo asset at the given [size]. Falls back to a
/// muted circle placeholder if the asset cannot be loaded — useful
/// during development before all chain art ships.
class ChainLogo extends StatelessWidget {
  const ChainLogo({
    super.key,
    required this.logoKey,
    this.size = 32,
    this.rounded = true,
  });

  final String logoKey;
  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/chains/$logoKey.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: rounded ? BoxShape.circle : BoxShape.rectangle,
        ),
        alignment: Alignment.center,
        child: Text(
          logoKey.isEmpty ? '?' : logoKey[0].toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (!rounded) return image;
    return ClipOval(child: image);
  }
}
