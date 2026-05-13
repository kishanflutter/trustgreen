import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/chains/chain_config.dart';
import '../../data/rpc/rpc_service.dart';
import '../../data/wallet/wallet_models.dart';
import '../../shared/widgets/chain_logo.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/balance_providers.dart';
import '../../state/chain_providers.dart';
import '../../state/history_providers.dart';
import '../../state/wallet_providers.dart';
import 'widgets/chain_picker_sheet.dart';
import 'widgets/tx_row.dart';
import 'widgets/wallet_picker_sheet.dart';

/// Wallet dashboard. Phase 3 replaces the static placeholders with
/// real on-chain balances + USD prices for the active wallet's
/// address on the active chain.
class WalletDashboardScreen extends ConsumerWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chain = ref.watch(activeChainProvider);
    final walletAsync = ref.watch(activeWalletProvider);

    return SafeScaffold(
      body: walletAsync.when(
        data: (wallet) {
          if (wallet == null) {
            return const _EmptyWalletState();
          }
          return _DashboardBody(wallet: wallet, chain: chain);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Could not load wallet: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWalletState extends StatelessWidget {
  const _EmptyWalletState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.textSecondary, size: 48),
            SizedBox(height: AppSpacing.md),
            Text(
              'No wallet found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Create or import a wallet to get started.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.wallet, required this.chain});

  final WalletMeta wallet;
  final ChainDefinition chain;

  Future<void> _refresh(WidgetRef ref) async {
    invalidateAllBalances(ref);
    // Give the refresh indicator something to wait on so it stays
    // visible long enough to feel like work happened.
    await Future.wait([
      ref.read(nativeBalanceProvider(
        BalanceKey(chainId: chain.id, address: wallet.addressEvm),
      ).future),
      ref.read(usdtBalanceProvider(
        BalanceKey(chainId: chain.id, address: wallet.addressEvm),
      ).future).catchError((_) => TokenAmount.zeroNative),
    ]).catchError((_) => <TokenAmount>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = BalanceKey(chainId: chain.id, address: wallet.addressEvm);

    final nativeAsync = ref.watch(nativeBalanceProvider(key));
    final usdtAsync = ref.watch(usdtBalanceProvider(key));

    // Build the price-id list the dashboard cares about. Trust Green
    // has no coingecko id → just look up the stablecoin.
    final priceIds = <String>{
      if (chain.coingeckoId != null) chain.coingeckoId!,
      chain.usdt.coingeckoId,
    }.toList();

    final pricesAsync = ref.watch(usdPricesProvider(priceIds));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _refresh(ref),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: ContentColumn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(chain: chain, wallet: wallet),
                    const SizedBox(height: AppSpacing.md),
                    _AddressChip(address: wallet.addressEvm),
                    const SizedBox(height: AppSpacing.lg),
                    _BalanceCard(
                      chain: chain,
                      nativeAsync: nativeAsync,
                      usdtAsync: usdtAsync,
                      pricesAsync: pricesAsync,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _ActionsRow(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: ContentColumn(
                child: Row(
                  children: [
                    Text(
                      'Assets',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          context.push(RoutePaths.walletTokenList),
                      child: const Text('Manage'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: ContentColumn(
                child: _AssetRow(
                  iconLogoKey: chain.logoKey,
                  title: chain.symbol,
                  subtitle: chain.name,
                  amountAsync: nativeAsync,
                  pricesAsync: pricesAsync,
                  priceId: chain.coingeckoId,
                  onTap: () => context.push(
                    RoutePaths.walletCoin(chain.chainId.toString()),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: ContentColumn(
                child: _AssetRow(
                  iconLogoKey: 'usdt',
                  fallbackIcon: Icons.attach_money_rounded,
                  title: 'USDT',
                  subtitle: 'Tether · ${chain.name}',
                  amountAsync: usdtAsync,
                  pricesAsync: pricesAsync,
                  priceId: chain.usdt.coingeckoId,
                  onTap: () => context.push(RoutePaths.walletToken('usdt')),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _RecentActivitySection(
              chain: chain,
              address: wallet.addressEvm,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection({
    required this.chain,
    required this.address,
  });

  final ChainDefinition chain;
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(activeChainSupportsHistoryProvider);
    if (!supported) return const SizedBox.shrink();

    final key = BalanceKey(chainId: chain.id, address: address);
    final async = ref.watch(txHistoryProvider(key));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: ContentColumn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Recent activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(RoutePaths.walletHistory),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            async.when(
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.brMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No transactions yet.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }
                final teaser = items.take(3).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final t in teaser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: TxRow(
                          item: t,
                          self: address,
                          onTap: () =>
                              context.push(RoutePaths.walletHistory),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.chain, required this.wallet});

  final ChainDefinition chain;
  final WalletMeta wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _TwoLineDropdown(
            label: 'Wallet',
            value: wallet.name,
            onTap: () => showWalletPickerSheet(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TwoLineDropdown(
            label: 'Network',
            value: chain.name,
            leading: ChainLogo(logoKey: chain.logoKey, size: 20),
            onTap: () => showChainPickerSheet(context),
          ),
        ),
      ],
    );
  }
}

class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.address});
  final String address;

  String get _short {
    if (address.length < 12) return address;
    return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: address));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        borderRadius: AppRadius.brMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _short,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.content_copy_rounded,
                color: AppColors.textSecondary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TwoLineDropdown extends StatelessWidget {
  const _TwoLineDropdown({
    required this.label,
    required this.value,
    this.leading,
    this.onTap,
  });

  final String label;
  final String value;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.chain,
    required this.nativeAsync,
    required this.usdtAsync,
    required this.pricesAsync,
  });

  final ChainDefinition chain;
  final AsyncValue<TokenAmount> nativeAsync;
  final AsyncValue<TokenAmount> usdtAsync;
  final AsyncValue<Map<String, double>> pricesAsync;

  @override
  Widget build(BuildContext context) {
    final isLoading = nativeAsync.isLoading || usdtAsync.isLoading;
    final hasError = nativeAsync.hasError && usdtAsync.hasError;

    String usdLabel = '\$0.00';
    String nativeLabel = '0 ${chain.symbol}';

    final native = nativeAsync.valueOrNull;
    final usdt = usdtAsync.valueOrNull;
    final prices = pricesAsync.valueOrNull ?? const <String, double>{};

    if (native != null) {
      nativeLabel = '${native.format(maxFraction: 6)} ${chain.symbol}';
    }

    final nativePrice = chain.coingeckoId == null
        ? null
        : prices[chain.coingeckoId];
    final usdtPrice = prices[chain.usdt.coingeckoId];

    double total = 0;
    var resolvedAny = false;
    if (native != null && nativePrice != null) {
      total += native.toDoubleUnits() * nativePrice;
      resolvedAny = true;
    }
    if (usdt != null && usdtPrice != null) {
      total += usdt.toDoubleUnits() * usdtPrice;
      resolvedAny = true;
    }

    if (resolvedAny) {
      usdLabel = '\$${total.toStringAsFixed(2)}';
    } else if (native != null && chain.coingeckoId == null) {
      // Testnet — no price available.
      usdLabel = '—';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Total balance',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            usdLabel,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            nativeLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Couldn\'t reach ${chain.name}. Pull to retry.',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = <_DashboardAction>[
      const _DashboardAction(
        icon: Icons.arrow_upward_rounded,
        label: 'Send',
        path: RoutePaths.walletSend,
      ),
      const _DashboardAction(
        icon: Icons.arrow_downward_rounded,
        label: 'Receive',
        path: RoutePaths.walletReceive,
      ),
      const _DashboardAction(
        icon: Icons.swap_horiz_rounded,
        label: 'Swap',
        path: RoutePaths.walletSwap,
      ),
      const _DashboardAction(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan',
        path: RoutePaths.walletScan,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final perItem = constraints.maxWidth / actions.length;
        final cramped = perItem < 76;

        if (cramped) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final a in actions)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: SizedBox(width: 84, child: _ActionTile(action: a)),
                  ),
              ],
            ),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final a in actions) Expanded(child: _ActionTile(action: a)),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          onTap: () => context.push(action.path),
          borderRadius: AppRadius.brMd,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(action.icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  action.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.iconLogoKey,
    required this.title,
    required this.subtitle,
    required this.amountAsync,
    required this.pricesAsync,
    required this.priceId,
    this.fallbackIcon,
    this.onTap,
  });

  final String iconLogoKey;
  final IconData? fallbackIcon;
  final String title;
  final String subtitle;
  final AsyncValue<TokenAmount> amountAsync;
  final AsyncValue<Map<String, double>> pricesAsync;
  final String? priceId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final amount = amountAsync.valueOrNull;
    final prices = pricesAsync.valueOrNull ?? const <String, double>{};
    final price = priceId == null ? null : prices[priceId];

    final balanceLabel = amount == null
        ? (amountAsync.hasError ? '—' : '…')
        : '${amount.format(maxFraction: 6)} $title';

    String usdLabel;
    if (amount == null) {
      usdLabel = '—';
    } else if (price == null) {
      usdLabel = priceId == null ? '—' : '\$—';
    } else {
      usdLabel = '\$${(amount.toDoubleUnits() * price).toStringAsFixed(2)}';
    }

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
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
              ChainLogo(
                logoKey: iconLogoKey,
                size: 32,
                fallbackIcon: fallbackIcon,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
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
                    balanceLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usdLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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
}
