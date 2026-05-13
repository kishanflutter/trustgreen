import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Splash-equivalent. Held on screen until the router guard finishes
/// reading the boot providers and picks the next destination.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
