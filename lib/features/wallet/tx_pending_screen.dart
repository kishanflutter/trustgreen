import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/chains/chain_config.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/chain_providers.dart';

/// Post-broadcast screen. Polls `eth_getTransactionReceipt` every
/// few seconds until the receipt is mined; flips to a success
/// state (or failure if the receipt's status is `0x0`).
class TxPendingScreen extends ConsumerStatefulWidget {
  const TxPendingScreen({super.key, required this.txHash});

  final String txHash;

  @override
  ConsumerState<TxPendingScreen> createState() => _TxPendingScreenState();
}

class _TxPendingScreenState extends ConsumerState<TxPendingScreen> {
  Timer? _poll;
  bool _confirmed = false;
  bool _failed = false;
  int _pollCount = 0;

  static const Duration _interval = Duration(seconds: 4);
  static const int _maxPolls = 75; // ~5 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickOff());
  }

  void _kickOff() {
    _poll = Timer.periodic(_interval, (_) => _tick());
    _tick();
  }

  Future<void> _tick() async {
    _pollCount += 1;
    if (_confirmed || _failed) return;
    final chain = ref.read(activeChainProvider);
    final rpc = ref.read(rpcServiceProvider);
    try {
      final receipt = await rpc.clientFor(chain).getTransactionReceipt(
            widget.txHash,
          );
      if (receipt == null) {
        if (_pollCount >= _maxPolls) {
          _poll?.cancel();
        }
        return;
      }
      _poll?.cancel();
      if (!mounted) return;
      setState(() {
        _confirmed = receipt.status == true;
        _failed = receipt.status == false;
      });
    } catch (_) {
      // Transient — keep polling unless we hit the cap.
      if (_pollCount >= _maxPolls) _poll?.cancel();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chain = ref.watch(activeChainProvider);
    final explorerUrl = chain.txExplorerUrl(widget.txHash);

    final IconData icon;
    final Color color;
    final String title;
    final String message;
    if (_confirmed) {
      icon = Icons.check_circle_rounded;
      color = AppColors.primary;
      title = 'Transaction confirmed';
      message =
          'Your transfer has been mined on ${chain.name}. Balances will update shortly.';
    } else if (_failed) {
      icon = Icons.error_rounded;
      color = AppColors.error;
      title = 'Transaction failed';
      message =
          'The network rejected this transaction. Funds were not moved — check the explorer for details.';
    } else {
      icon = Icons.hourglass_top_rounded;
      color = AppColors.warning;
      title = 'Broadcasting…';
      message =
          'Waiting for ${chain.name} to mine the transaction. This usually takes a few seconds.';
    }

    return SafeScaffold(
      title: 'Transaction',
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: ContentColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: _confirmed || _failed
                        ? Icon(icon, color: color, size: 48)
                        : SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: color,
                              strokeWidth: 3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _HashCard(hash: widget.txHash, chain: chain),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(explorerUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View on explorer'),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Back to wallet',
                  onPressed: () => context.go(RoutePaths.wallet),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HashCard extends StatelessWidget {
  const _HashCard({required this.hash, required this.chain});

  final String hash;
  final ChainDefinition chain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaction hash',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(
            hash,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
