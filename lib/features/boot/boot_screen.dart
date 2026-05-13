import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../core/theme/tokens.dart';

/// Splash-equivalent. Held on screen until the router guard finishes
/// reading the boot providers and picks the next destination.
///
/// Triggers [FlutterNativeSplash.remove] from the first post-frame
/// callback so the native splash, which is still on-screen at this
/// point, hands off seamlessly to this widget (same black background,
/// same centered logo above the spinner).
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tearing the native splash down here (rather than from main)
      // guarantees Flutter has painted at least one frame, so there
      // is no black flash between the native and Flutter splash.
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mirror the native splash exactly so the handoff is
            // invisible: same logo, same black bg, same centered layout.
            Image.asset(
              'assets/images/app_logo.png',
              width: 120,
              height: 120,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
