import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../shared/widgets/placeholder_screen.dart';
import 'qr_scan_screen.dart';

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

/// Dashboard "Scan" tile. Opens the camera-backed QR scanner and,
/// if a valid 0x address is returned, hands off to the Send screen
/// with the recipient pre-filled.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
  }

  Future<void> _launch() async {
    if (_launched) return;
    _launched = true;
    final scanned = await QrScanScreen.open(context);
    if (!mounted) return;
    if (scanned == null || scanned.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    final isEvm = RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(scanned);
    if (!isEvm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unrecognised QR (expected an EVM address).'),
        ),
      );
      Navigator.of(context).maybePop();
      return;
    }
    // Hand off to the Send screen with the scanned address
    // pre-filled — Phase 4 polish so the QR tile is actually useful.
    context.pushReplacement(
      '${RoutePaths.walletSend}?recipient=$scanned',
    );
  }

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Scan QR',
        description: 'Opening camera…',
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
