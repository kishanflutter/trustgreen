import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class PinScreen extends StatelessWidget {
  const PinScreen({super.key, this.mode});

  /// `'unlock'` when the user has an existing PIN, otherwise null
  /// (first-launch setup).
  final String? mode;

  @override
  Widget build(BuildContext context) {
    final isUnlock = mode == 'unlock';
    return PlaceholderScreen(
      title: isUnlock ? 'Unlock Trust Green' : 'Set your PIN',
      titleInAppBar: false,
      description: isUnlock
          ? 'Enter your PIN to unlock the wallet.'
          : 'Create a 6-digit PIN to secure this device. '
              'You\'ll need it every time you reopen the app.',
    );
  }
}
