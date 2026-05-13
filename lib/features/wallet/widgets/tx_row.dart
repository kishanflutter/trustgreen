import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../data/history/tx_history_models.dart';
import '../../../data/rpc/rpc_service.dart';

/// Single-row representation of a transaction in the history list.
class TxRow extends StatelessWidget {
  const TxRow({
    super.key,
    required this.item,
    required this.self,
    required this.onTap,
  });

  final TxHistoryItem item;
  final String self;
  final VoidCallback onTap;

  String _short(String addr) {
    if (addr.length < 12) return addr;
    return '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}';
  }

  ({IconData icon, Color color, String title}) _badge() {
    switch (item.direction) {
      case TxDirection.incoming:
        return (
          icon: Icons.south_east_rounded,
          color: AppColors.primary,
          title: 'Received',
        );
      case TxDirection.outgoing:
        return (
          icon: Icons.north_east_rounded,
          color: AppColors.warning,
          title: 'Sent',
        );
      case TxDirection.selfSelf:
        return (
          icon: Icons.sync_alt_rounded,
          color: AppColors.info,
          title: 'Self transfer',
        );
      case TxDirection.contract:
        return (
          icon: Icons.code_rounded,
          color: AppColors.info,
          title: 'Contract',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge();
    final amount = TokenAmount(
      raw: item.valueRaw,
      decimals: item.assetDecimals,
    );
    final isIn = item.direction == TxDirection.incoming;
    final sign = isIn ? '+' : '-';
    final color = isIn ? AppColors.primary : AppColors.textPrimary;

    final timeLabel = _formatTime(item.timestamp);
    final counter = item.counterparty(self);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(badge.icon, color: badge.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          badge.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!item.success) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.error.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Failed',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isIn ? 'From' : 'To'} ${_short(counter)} · $timeLabel',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.assetKind == TxAssetKind.unknown
                        ? 'Call'
                        : '$sign${amount.format(maxFraction: 6)} '
                            '${item.assetSymbol}',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.success ? 'Confirmed' : 'Reverted',
                    style: TextStyle(
                      color: item.success
                          ? AppColors.textSecondary
                          : AppColors.error,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(t);
  }
}
