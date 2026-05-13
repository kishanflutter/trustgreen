import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class VerifySeedScreen extends StatelessWidget {
  const VerifySeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Verify seed phrase',
      description:
          'Prompts the user to confirm 3–4 random words from their '
          'mnemonic before activating the wallet.',
    );
  }
}
