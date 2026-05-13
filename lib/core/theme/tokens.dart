import 'package:flutter/material.dart';

/// Design tokens — ports `theme/tokens.ts` from the Expo source 1:1.
///
/// Keep this file as the *single source of truth* for colors, spacing,
/// and radii. New tokens belong here, never inline magic numbers in
/// widgets.
@immutable
class AppColors {
  const AppColors._();

  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1A1A1A);

  static const Color primary = Color(0xFF00E676);
  static const Color primaryMuted = Color(0xFF00C853);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF757575);

  static const Color border = Color(0xFF2A2A2A);
  static const Color borderFocus = Color(0xFF00E676);

  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF42A5F5);

  static const Color qrBg = Color(0xFFFFFFFF);
  static const Color qrFg = Color(0xFF000000);

  static const Color onPrimary = Color(0xFF000000);
}

@immutable
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

@immutable
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
}

/// Recommended minimum tap target per the Flutter accessibility
/// guidelines and §2.1.6 of the rebuild spec.
const double kMinTouchTarget = 48;

/// Primary CTA min height (§3 of spec).
const double kPrimaryButtonHeight = 52;
