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
    this.fallbackIcon,
  });

  final String logoKey;
  final double size;
  final bool rounded;

  /// Icon shown when the asset is missing. If `null`, the first
  /// letter of [logoKey] is rendered instead.
  final IconData? fallbackIcon;

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
        child: fallbackIcon != null
            ? Icon(
                fallbackIcon,
                color: AppColors.primary,
                size: size * 0.55,
              )
            : Text(
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
