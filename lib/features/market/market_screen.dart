import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/tokens.dart';
import '../../data/market/market_models.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/market_providers.dart';
import 'widgets/sparkline.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = v);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(topMarketsProvider);
    await ref.read(topMarketsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      title: 'Market',
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: ContentColumn(
                child: _SearchField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _search.clear();
                    _onSearchChanged('');
                  },
                ),
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? _TopMarketsList(refresh: _refresh)
                  : _SearchResultsList(query: _query),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search coins',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _TopMarketsList extends ConsumerWidget {
  const _TopMarketsList({required this.refresh});
  final Future<void> Function() refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topMarketsProvider);
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: refresh,
      child: async.when(
        data: (coins) {
          if (coins.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'Market data unavailable.\nPull down to retry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
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
              AppSpacing.xl,
            ),
            itemCount: coins.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final coin = coins[i];
              return ContentColumn(
                child: _MarketRow(
                  coin: coin,
                  onTap: () => context.push('/market/coin/${coin.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(
                'Could not load market data: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(marketSearchProvider(query));
    return async.when(
      data: (results) {
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'No coins matched.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, i) {
            final c = results[i];
            return ContentColumn(
              child: _SearchRow(
                result: c,
                onTap: () => context.push('/market/coin/${c.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          'Search failed: $e',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.coin, required this.onTap});

  final MarketCoin coin;
  final VoidCallback onTap;

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
              _CoinAvatar(url: coin.imageUrl, size: 32),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.tickerUpper,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coin.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Sparkline(values: coin.sparkline7d, width: 80),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pctLabel,
                    style: TextStyle(color: pctColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.result, required this.onTap});
  final CoinSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              _CoinAvatar(url: result.thumbUrl, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.tickerUpper,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.marketCapRank != null)
                Text(
                  '#${result.marketCapRank}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinAvatar extends StatelessWidget {
  const _CoinAvatar({required this.url, required this.size});
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
          alignment: Alignment.center,
          child: const Icon(
            Icons.currency_bitcoin_rounded,
            color: AppColors.textSecondary,
            size: 16,
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: AppColors.surfaceElevated,
          );
        },
      ),
    );
  }
}
