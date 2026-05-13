import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class ImportWalletScreen extends StatelessWidget {
  const ImportWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Import existing wallet',
      description:
          'Paste or type a 12 / 18 / 24-word mnemonic. The phrase '
          'is validated against the BIP-39 word list before the '
          'wallet is derived.',
    );
  }
}
