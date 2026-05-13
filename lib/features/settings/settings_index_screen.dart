import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/safe_scaffold.dart';

class SettingsIndexScreen extends StatelessWidget {
  const SettingsIndexScreen({super.key});

  static const _items = <_SettingsItem>[
    _SettingsItem(
      title: 'Networks',
      subtitle: 'Manage RPC endpoints and active chains',
      icon: Icons.hub_outlined,
      path: RoutePaths.settingsChains,
    ),
    _SettingsItem(
      title: 'Wallets',
      subtitle: 'View, rename, or delete wallets',
      icon: Icons.account_balance_wallet_outlined,
      path: RoutePaths.settingsWallets,
    ),
    _SettingsItem(
      title: 'Security',
      subtitle: 'PIN, biometrics, auto-lock',
      icon: Icons.lock_outline,
      path: RoutePaths.settingsSecurity,
    ),
    _SettingsItem(
      title: 'Privacy',
      subtitle: 'App-level privacy preferences',
      icon: Icons.privacy_tip_outlined,
      path: RoutePaths.settingsPrivacy,
    ),
    _SettingsItem(
      title: 'Export',
      subtitle: 'Reveal seed phrase / private key',
      icon: Icons.ios_share_outlined,
      path: RoutePaths.settingsExport,
    ),
    _SettingsItem(
      title: 'Transactions',
      subtitle: 'History across all chains',
      icon: Icons.receipt_long_outlined,
      path: RoutePaths.settingsTransactions,
    ),
    _SettingsItem(
      title: 'Phonebook',
      subtitle: 'Address book',
      icon: Icons.contact_phone_outlined,
      path: RoutePaths.settingsPhonebook,
    ),
    _SettingsItem(
      title: 'Contact us',
      subtitle: 'Reach the team',
      icon: Icons.email_outlined,
      path: RoutePaths.settingsContact,
    ),
    _SettingsItem(
      title: 'Support',
      subtitle: 'Open a support ticket',
      icon: Icons.support_agent_outlined,
      path: RoutePaths.settingsSupport,
    ),
    _SettingsItem(
      title: 'FAQ',
      subtitle: 'Frequently asked questions',
      icon: Icons.help_outline,
      path: RoutePaths.settingsFaq,
    ),
    _SettingsItem(
      title: 'Social',
      subtitle: 'Telegram, X, Discord',
      icon: Icons.public_outlined,
      path: RoutePaths.settingsSocial,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      title: 'Settings',
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final item = _items[i];
          return ContentColumn(
            child: Material(
              color: AppColors.surface,
              borderRadius: AppRadius.brMd,
              child: InkWell(
                onTap: () => context.push(item.path),
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
                      Icon(item.icon, color: AppColors.primary, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.path,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String path;
}
