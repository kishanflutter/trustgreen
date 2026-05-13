import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Receive',
        description:
            'Renders a QR code (white bg / black modules) and a copy-to-'
            'clipboard control for the active wallet address.',
      );
}

class SendScreen extends StatelessWidget {
  const SendScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Send',
        description:
            'Address + amount form with gas estimation and a "Confirm '
            'transaction" handoff.',
      );
}

class SwapScreen extends StatelessWidget {
  const SwapScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Swap',
        description:
            'In-app swap UI between supported tokens with a confirm '
            'screen and slippage controls.',
      );
}

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Scan QR',
        description: 'Camera viewfinder powered by mobile_scanner.',
      );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Transaction history',
        description:
            'Per-wallet activity list with explorer deep links per chain.',
      );
}

class TokenListScreen extends StatelessWidget {
  const TokenListScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Manage tokens',
        description: 'Add / hide / reorder displayed tokens.',
      );
}

class TokenDetailScreen extends StatelessWidget {
  const TokenDetailScreen({super.key, required this.tokenKey});
  final String tokenKey;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Token · $tokenKey',
        description:
            'Token detail view with balance, price, recent transactions, '
            'and contract metadata.',
      );
}

class CoinChainScreen extends StatelessWidget {
  const CoinChainScreen({super.key, required this.chainId});
  final String chainId;

  @override
  Widget build(BuildContext context) => PlaceholderScreen(
        title: 'Chain · $chainId',
        description:
            'Per-chain dashboard showing native + ERC-20 balances on '
            'this network.',
      );
}

class ConfirmTxScreen extends StatelessWidget {
  const ConfirmTxScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Confirm transaction',
        description: 'Final review screen before signing and broadcasting.',
      );
}

class ConfirmSwapScreen extends StatelessWidget {
  const ConfirmSwapScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Confirm swap',
        description: 'Final review screen before executing a swap.',
      );
}
