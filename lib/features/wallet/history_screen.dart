import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/tokens.dart';
import '../../data/chains/chain_config.dart';
import '../../data/history/tx_history_models.dart';
import '../../data/rpc/rpc_service.dart';
import '../../shared/widgets/chain_logo.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/balance_providers.dart';
import '../../state/chain_providers.dart';
import '../../state/history_providers.dart';
import '../../state/wallet_providers.dart';
import 'widgets/tx_row.dart';

/// `/wallet/history` — per-wallet activity feed for the active
/// chain. Backed by Etherscan V2 when the chain is supported;
/// otherwise renders a polite fallback with an explorer deep-link.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chain = ref.watch(activeChainProvider);
    final walletAsync = ref.watch(activeWalletProvider);
    final supported = ref.watch(activeChainSupportsHistoryProvider);

    return SafeScaffold(
      title: 'History',
      body: walletAsync.when(
        data: (wallet) {
          if (wallet == null) {
            return const _Empty(message: 'No active wallet.');
          }
          if (!supported) {
            return _UnsupportedChainView(
              chain: chain,
              address: wallet.addressEvm,
            );
          }
          final key = BalanceKey(
            chainId: chain.id,
            address: wallet.addressEvm,
          );
          return _SupportedChainList(
            chain: chain,
            address: wallet.addressEvm,
            balanceKey: key,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _Empty(message: 'Failed to load wallet: $e'),
      ),
    );
  }
}

class _SupportedChainList extends ConsumerWidget {
  const _SupportedChainList({
    required this.chain,
    required this.address,
    required this.balanceKey,
  });

  final ChainDefinition chain;
  final String address;
  final BalanceKey balanceKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(txHistoryProvider(balanceKey));

    Future<void> refresh() async {
      ref.invalidate(txHistoryProvider(balanceKey));
      await ref.read(txHistoryProvider(balanceKey).future);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: refresh,
      child: async.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _HeaderRow(chain: chain),
                const _Empty(
                  message:
                      'No transactions yet. Make a transfer to see it here.',
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            itemCount: items.length + 1,
            separatorBuilder: (_, i) {
              if (i == 0) return const SizedBox.shrink();
              return const SizedBox(height: AppSpacing.xs);
            },
            itemBuilder: (context, i) {
              if (i == 0) return _HeaderRow(chain: chain);
              final item = items[i - 1];
              return ContentColumn(
                child: TxRow(
                  item: item,
                  self: address,
                  onTap: () => _openDetail(context, chain, item),
                ),
              );
            },
          );
        },
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            SizedBox(height: 80),
          ],
        ),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HeaderRow(chain: chain),
            _Empty(message: 'Could not load history: $e'),
          ],
        ),
      ),
    );
  }

  void _openDetail(
    BuildContext context,
    ChainDefinition chain,
    TxHistoryItem item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _TxDetailSheet(item: item, chain: chain),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.chain});
  final ChainDefinition chain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: ContentColumn(
        child: Row(
          children: [
            ChainLogo(logoKey: chain.logoKey, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                chain.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              'Pull to refresh',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textTertiary,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedChainView extends StatelessWidget {
  const _UnsupportedChainView({
    required this.chain,
    required this.address,
  });

  final ChainDefinition chain;
  final String address;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ContentColumn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'History unavailable in-app',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${chain.name} isn\'t covered by the bundled history API. '
                'You can view your full activity on the chain explorer.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(chain.addressExplorerUrl(address));
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open in explorer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxDetailSheet extends StatelessWidget {
  const _TxDetailSheet({required this.item, required this.chain});
  final TxHistoryItem item;
  final ChainDefinition chain;

  @override
  Widget build(BuildContext context) {
    final amount = TokenAmount(
      raw: item.valueRaw,
      decimals: item.assetDecimals,
    );
    final fee = item.feeWei;
    final feeAmount = fee == null
        ? null
        : TokenAmount(raw: fee, decimals: chain.decimals);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Transaction',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(label: 'Status', value: item.success ? 'Confirmed' : 'Failed'),
            _DetailRow(
              label: 'Amount',
              value: item.assetKind == TxAssetKind.unknown
                  ? 'Contract call'
                  : '${amount.format(maxFraction: 8)} ${item.assetSymbol}',
            ),
            _DetailRow(label: 'From', value: item.from),
            _DetailRow(label: 'To', value: item.to),
            if (item.tokenAddress != null && item.tokenAddress!.isNotEmpty)
              _DetailRow(label: 'Token contract', value: item.tokenAddress!),
            _DetailRow(label: 'Network', value: chain.name),
            _DetailRow(label: 'Time', value: item.timestamp.toString()),
            if (feeAmount != null)
              _DetailRow(
                label: 'Network fee',
                value:
                    '${feeAmount.format(maxFraction: 8)} ${chain.symbol}',
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: item.hash),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hash copied')),
                      );
                    },
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Copy hash'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(chain.txExplorerUrl(item.hash));
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Explorer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
