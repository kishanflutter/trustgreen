import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/chains/chain_config.dart';
import '../../shared/widgets/chain_logo.dart';
import '../../shared/widgets/safe_scaffold.dart';

/// Wallet dashboard — the spec calls out very specific label / value
/// ordering (USD on top, native green below; asset row native white,
/// USD grey; two-line dropdowns). This Phase-1 implementation wires
/// up the *layout* with realistic stub data so the design system can
/// be reviewed before Phase 3 hooks in real balances.
class WalletDashboardScreen extends StatelessWidget {
  const WalletDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chain = ChainCatalog.defaultChain();

    return SafeScaffold(
      body: CustomScrollView(
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
                    _Header(chain: chain),
                    const SizedBox(height: AppSpacing.lg),
                    const _BalanceCard(
                      usdAmount: '\$0.00',
                      nativeAmount: '0.00 TG',
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
                      onPressed: () => context.push(RoutePaths.walletTokenList),
                      child: const Text('Manage'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: ChainCatalog.defaults().length,
            itemBuilder: (context, index) {
              final c = ChainCatalog.defaults()[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: ContentColumn(
                  child: _AssetRow(
                    chain: c,
                    onTap: () =>
                        context.push(RoutePaths.walletCoin(c.chainId.toString())),
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.chain});
  final ChainDefinition chain;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TwoLineDropdown(
            label: 'Wallet',
            value: 'Main wallet',
            onTap: () => DefaultTabController.maybeOf(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TwoLineDropdown(
            label: 'Network',
            value: chain.name,
            leading: ChainLogo(logoKey: chain.logoKey, size: 20),
            onTap: () {},
          ),
        ),
      ],
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
  const _BalanceCard({required this.usdAmount, required this.nativeAmount});

  final String usdAmount;
  final String nativeAmount;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Total balance',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs),
          // USD on top — primary white, larger (per §5.1)
          Text(
            usdAmount,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Native chain symbol — green, smaller than USD (per §5.1)
          Text(
            nativeAmount,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      _DashboardAction(
        icon: Icons.arrow_upward_rounded,
        label: 'Send',
        path: RoutePaths.walletSend,
      ),
      _DashboardAction(
        icon: Icons.arrow_downward_rounded,
        label: 'Receive',
        path: RoutePaths.walletReceive,
      ),
      _DashboardAction(
        icon: Icons.swap_horiz_rounded,
        label: 'Swap',
        path: RoutePaths.walletSwap,
      ),
      _DashboardAction(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan',
        path: RoutePaths.walletScan,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Wrap horizontally on narrow widths to avoid clipping (§5.4).
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
  const _AssetRow({required this.chain, this.onTap});

  final ChainDefinition chain;
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
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ChainLogo(logoKey: chain.logoKey, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chain.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chain.symbol,
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
                  // Top: native amount — white, prominent (per §5.3).
                  Text(
                    '0.00 ${chain.symbol}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Bottom: USD estimate — grey (per §5.3).
                  const Text(
                    '\$0.00',
                    style: TextStyle(
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
