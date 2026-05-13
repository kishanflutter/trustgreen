/// Centralised path constants for `go_router`. Keep these in sync
/// with the Expo source `app/` directory so the two projects share a
/// mental model.
class RoutePaths {
  RoutePaths._();

  // Boot
  static const String boot = '/';

  // Auth (matches Expo `(auth)` group)
  static const String pin = '/auth/pin';
  static const String createImport = '/auth/create-import';
  static const String createWallet = '/auth/create-wallet';
  static const String verifySeed = '/auth/verify-seed';
  static const String importWallet = '/auth/import-wallet';
  static const String success = '/auth/success';

  // Main tabs
  static const String wallet = '/wallet';
  static const String market = '/market';
  static const String news = '/news';
  static const String browser = '/browser';
  static const String settings = '/settings';

  // Wallet sub-routes (nested under /wallet)
  static const String walletReceive = '/wallet/receive';
  static const String walletSend = '/wallet/send';
  static const String walletSwap = '/wallet/swap';
  static const String walletScan = '/wallet/scan';
  static const String walletHistory = '/wallet/history';
  static const String walletTokenList = '/wallet/token-list';
  // /wallet/token/:key
  static String walletToken(String key) => '/wallet/token/$key';
  // /wallet/coin/:chainId
  static String walletCoin(String chainId) => '/wallet/coin/$chainId';
  static const String walletConfirmTx = '/wallet/confirm-tx';
  static const String walletConfirmSwap = '/wallet/confirm-swap';

  // Settings sub-routes
  static const String settingsChains = '/settings/chains';
  static const String settingsWallets = '/settings/wallets';
  static const String settingsSecurity = '/settings/security';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsExport = '/settings/export';
  static const String settingsTransactions = '/settings/transactions';
  static const String settingsPhonebook = '/settings/phonebook';
  static const String settingsContact = '/settings/contact';
  static const String settingsSupport = '/settings/support';
  static const String settingsFaq = '/settings/faq';
  static const String settingsSocial = '/settings/social';
}
