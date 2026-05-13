import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';

/// 5-tab bottom navigation shell. Sits between [GoRouter]'s
/// [StatefulShellRoute] and the per-tab content so swapping tabs
/// preserves each branch's navigation stack (matches Expo `(tabs)`).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_TabDestination>[
    _TabDestination(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Wallet',
    ),
    _TabDestination(
      icon: Icons.show_chart,
      selectedIcon: Icons.show_chart_rounded,
      label: 'Market',
    ),
    _TabDestination(
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
      label: 'News',
    ),
    _TabDestination(
      icon: Icons.language_outlined,
      selectedIcon: Icons.language,
      label: 'Browser',
    ),
    _TabDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _TabDestination {
  const _TabDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
