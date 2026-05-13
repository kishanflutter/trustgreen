import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/tokens.dart';
import '../../data/market/market_models.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/market_providers.dart';

class CoinDetailScreen extends ConsumerStatefulWidget {
  const CoinDetailScreen({super.key, required this.coinId});

  /// CoinGecko coin id (e.g. `ethereum`, `bitcoin`).
  final String coinId;

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  ChartRange _range = ChartRange.week;

  @override
  Widget build(BuildContext context) {
    final markets = ref.watch(topMarketsProvider).valueOrNull;
    final MarketCoin? known = (markets == null)
        ? null
        : markets.cast<MarketCoin?>().firstWhere(
              (c) => c?.id == widget.coinId,
              orElse: () => null,
            );

    final chartAsync = ref.watch(
      coinChartProvider(CoinChartKey(id: widget.coinId, range: _range)),
    );

    return SafeScaffold(
      title: known?.name ?? widget.coinId,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: ContentColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (known != null) _Header(coin: known),
                const SizedBox(height: AppSpacing.lg),
                _RangeBar(
                  selected: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
                const SizedBox(height: AppSpacing.md),
                _ChartCard(async: chartAsync, range: _range),
                const SizedBox(height: AppSpacing.lg),
                if (known != null) _StatsGrid(coin: known),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Open on CoinGecko',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.coingecko.com/en/coins/${widget.coinId}',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coin});
  final MarketCoin coin;

  @override
  Widget build(BuildContext context) {
    final pct = coin.priceChange24hPct;
    final pctColor = (pct ?? 0) >= 0 ? AppColors.primary : AppColors.error;
    final pctLabel = pct == null
        ? '—'
        : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
    final price = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: coin.priceUsd >= 1 ? 2 : 6,
    ).format(coin.priceUsd);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _NetworkImage(url: coin.imageUrl, size: 44),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${coin.name} · ${coin.tickerUpper}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$pctLabel (24h)',
                style: TextStyle(color: pctColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.selected, required this.onChanged});
  final ChartRange selected;
  final ValueChanged<ChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final r in ChartRange.values)
            Expanded(
              child: Material(
                color: selected == r ? AppColors.primary : Colors.transparent,
                borderRadius: AppRadius.brSm,
                child: InkWell(
                  onTap: () => onChanged(r),
                  borderRadius: AppRadius.brSm,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      r.label,
                      style: TextStyle(
                        color: selected == r
                            ? AppColors.onPrimary
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.async, required this.range});

  final AsyncValue<CoinChartSeries> async;
  final ChartRange range;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: async.when(
          data: (series) {
            if (series.isEmpty) {
              return const Center(
                child: Text(
                  'No chart data.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            final values =
                series.points.map((p) => p.$2).toList(growable: false);
            final min = values.reduce((a, b) => a < b ? a : b);
            final max = values.reduce((a, b) => a > b ? a : b);
            final pad = (max - min) * 0.05;
            final isUp =
                series.points.last.$2 >= series.points.first.$2;
            final color = isUp ? AppColors.primary : AppColors.error;

            return LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: min - pad,
                maxY: max + pad,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => AppColors.surfaceElevated,
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final tsMs = series.points[s.x.toInt()].$1;
                        final dt =
                            DateTime.fromMillisecondsSinceEpoch(tsMs);
                        final df = range.days <= 1
                            ? DateFormat.Hm()
                            : DateFormat.MMMd();
                        final priceFmt = NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: s.y >= 1 ? 2 : 6,
                        );
                        return LineTooltipItem(
                          '${priceFmt.format(s.y)}\n${df.format(dt)}',
                          const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.18,
                    color: color,
                    barWidth: 1.8,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
              duration: Duration.zero,
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text(
              'Could not load chart: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.coin});
  final MarketCoin coin;

  @override
  Widget build(BuildContext context) {
    final pct = coin.priceChange24hPct;
    final rank = coin.marketCapRank;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'Market cap rank',
            value: rank == null ? '—' : '#$rank',
          ),
          _StatRow(
            label: '24h change',
            value: pct == null
                ? '—'
                : '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%',
            valueColor: (pct ?? 0) >= 0 ? AppColors.primary : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({required this.url, required this.size});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppColors.surfaceElevated,
        ),
      ),
    );
  }
}
