import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../data/chains/chain_config.dart';
import '../../data/rpc/rpc_service.dart';
import '../../data/tx/send_pipeline.dart';
import '../../data/wallet/wallet_models.dart';
import '../../shared/widgets/chain_logo.dart';
import '../../shared/widgets/primary_button.dart';

/// Pre-sign review sheet. Shows the user every detail of the
/// transaction in plain English before we ask for the PIN.
///
/// Returns `true` if the user taps "Confirm", `false` / `null` for
/// dismissal.
Future<bool?> showSendReviewSheet(
  BuildContext context, {
  required WalletMeta from,
  required ChainDefinition chain,
  required SendAsset asset,
  required String to,
  required TokenAmount amount,
  required FeeQuote fee,
  required Map<String, double> prices,
}) {
  return showModalBottomSheet<bool?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
    ),
    builder: (context) => _SendReviewBody(
      from: from,
      chain: chain,
      asset: asset,
      to: to,
      amount: amount,
      fee: fee,
      prices: prices,
    ),
  );
}

class _SendReviewBody extends StatelessWidget {
  const _SendReviewBody({
    required this.from,
    required this.chain,
    required this.asset,
    required this.to,
    required this.amount,
    required this.fee,
    required this.prices,
  });

  final WalletMeta from;
  final ChainDefinition chain;
  final SendAsset asset;
  final String to;
  final TokenAmount amount;
  final FeeQuote fee;
  final Map<String, double> prices;

  String _shortAddr(String a) {
    if (a.length < 12) return a;
    return '${a.substring(0, 6)}…${a.substring(a.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final symbol = asset == SendAsset.native
        ? chain.symbol
        : chain.usdt.symbol;
    final priceId = asset == SendAsset.native
        ? chain.coingeckoId
        : chain.usdt.coingeckoId;
    final price = priceId == null ? null : prices[priceId];
    final amountUsd = price == null
        ? null
        : '\$${(amount.toDoubleUnits() * price).toStringAsFixed(2)}';

    final feePrice = chain.coingeckoId == null
        ? null
        : prices[chain.coingeckoId];
    final feeUsd = feePrice == null
        ? null
        : '\$${(fee.totalAmount.toDoubleUnits() * feePrice).toStringAsFixed(4)}';

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
              'Review transaction',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Column(
                children: [
                  ChainLogo(
                    logoKey: asset == SendAsset.native
                        ? chain.logoKey
                        : 'usdt',
                    size: 40,
                    fallbackIcon: Icons.attach_money_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${amount.format(maxFraction: 8)} $symbol',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (amountUsd != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      amountUsd,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ReviewRow(
              label: 'From',
              value: '${from.name} · ${_shortAddr(from.addressEvm)}',
            ),
            _ReviewRow(
              label: 'To',
              value: _shortAddr(to),
              valueFull: to,
            ),
            _ReviewRow(label: 'Network', value: chain.name),
            _ReviewRow(
              label: 'Network fee',
              value:
                  '${fee.totalAmount.format(maxFraction: 6)} ${chain.symbol}'
                  '${feeUsd == null ? '' : ' · $feeUsd'}',
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Confirm',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.valueFull,
  });

  final String label;
  final String value;
  final String? valueFull;

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
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Tooltip(
              message: valueFull ?? value,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
