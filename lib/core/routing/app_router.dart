import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/create_import_screen.dart';
import '../../features/auth/create_wallet_screen.dart';
import '../../features/auth/import_wallet_screen.dart';
import '../../features/auth/pin_screen.dart';
import '../../features/auth/success_screen.dart';
import '../../features/auth/verify_seed_screen.dart';
import '../../features/boot/boot_controller.dart';
import '../../features/browser/browser_screen.dart';
import '../../features/market/market_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/settings/settings_index_screen.dart';
import '../../features/settings/settings_stub_screens.dart';
import '../../features/shell/main_shell.dart';
import '../../features/wallet/wallet_dashboard_screen.dart';
import '../../features/wallet/wallet_stub_screens.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _walletNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'wallet');
final _marketNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'market');
final _newsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'news');
final _browserNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'browser');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.boot,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RoutePaths.boot,
        builder: (context, state) => const BootController(),
      ),

      // ── Auth stack (outside the shell) ─────────────────────────
      GoRoute(
        path: RoutePaths.pin,
        builder: (context, state) =>
            PinScreen(mode: state.uri.queryParameters['mode']),
      ),
      GoRoute(
        path: RoutePaths.createImport,
        builder: (context, state) => const CreateImportScreen(),
      ),
      GoRoute(
        path: RoutePaths.createWallet,
        builder: (context, state) => const CreateWalletScreen(),
      ),
      GoRoute(
        path: RoutePaths.verifySeed,
        builder: (context, state) => const VerifySeedScreen(),
      ),
      GoRoute(
        path: RoutePaths.importWallet,
        builder: (context, state) => const ImportWalletScreen(),
      ),
      GoRoute(
        path: RoutePaths.success,
        builder: (context, state) => const SuccessScreen(),
      ),

      // ── Main 5-tab shell ───────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Wallet branch (deep nested stack)
          StatefulShellBranch(
            navigatorKey: _walletNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.wallet,
                builder: (context, state) => const WalletDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'receive',
                    builder: (context, state) => const ReceiveScreen(),
                  ),
                  GoRoute(
                    path: 'send',
                    builder: (context, state) => const SendScreen(),
                  ),
                  GoRoute(
                    path: 'swap',
                    builder: (context, state) => const SwapScreen(),
                  ),
                  GoRoute(
                    path: 'scan',
                    builder: (context, state) => const ScanScreen(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const HistoryScreen(),
                  ),
                  GoRoute(
                    path: 'token-list',
                    builder: (context, state) => const TokenListScreen(),
                  ),
                  GoRoute(
                    path: 'token/:key',
                    builder: (context, state) => TokenDetailScreen(
                      tokenKey: state.pathParameters['key'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'coin/:chainId',
                    builder: (context, state) => CoinChainScreen(
                      chainId: state.pathParameters['chainId'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'confirm-tx',
                    builder: (context, state) => const ConfirmTxScreen(),
                  ),
                  GoRoute(
                    path: 'confirm-swap',
                    builder: (context, state) => const ConfirmSwapScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Market branch
          StatefulShellBranch(
            navigatorKey: _marketNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.market,
                builder: (context, state) => const MarketScreen(),
              ),
            ],
          ),

          // News branch
          StatefulShellBranch(
            navigatorKey: _newsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.news,
                builder: (context, state) => const NewsScreen(),
              ),
            ],
          ),

          // Browser branch
          StatefulShellBranch(
            navigatorKey: _browserNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.browser,
                builder: (context, state) => const BrowserScreen(),
              ),
            ],
          ),

          // Settings branch (nested stack)
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsIndexScreen(),
                routes: [
                  GoRoute(
                    path: 'chains',
                    builder: (context, state) => const ChainsSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'wallets',
                    builder: (context, state) => const WalletsSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) =>
                        const SecuritySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'export',
                    builder: (context, state) => const ExportSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'transactions',
                    builder: (context, state) =>
                        const TransactionsSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'phonebook',
                    builder: (context, state) =>
                        const PhonebookSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'contact',
                    builder: (context, state) => const ContactSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const SupportSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'faq',
                    builder: (context, state) => const FaqSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'social',
                    builder: (context, state) => const SocialSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
