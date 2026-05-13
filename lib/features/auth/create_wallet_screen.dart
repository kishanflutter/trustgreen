import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class CreateWalletScreen extends StatelessWidget {
  const CreateWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Create new wallet',
      description:
          'Generates a fresh BIP-39 mnemonic, shows it with security '
          'warnings, and lets the user copy it for safekeeping.',
    );
  }
}
