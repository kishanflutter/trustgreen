# Trust Green Wallet — Flutter

Multi-chain crypto wallet in Flutter, built from the spec in
`flutter_trustgreen.md` (kept in the Expo source repo) and the
original Expo / React Native reference at
[`kishan-flutter/trustgreen`](https://github.com/kishanflutter/trustgreen).

> **Status:** Phase 1 — scaffolding, design system, routing,
> placeholder screens. Not production-ready. See
> [Phased rebuild plan](#phased-rebuild-plan).

## Requirements

| Tool      | Version            |
|-----------|--------------------|
| Flutter   | `>= 3.24` (tested on 3.29.2) |
| Dart      | `^3.7.2`           |
| Android   | minSdk 23, target current Flutter default |
| iOS       | iOS 13+, portrait-only, dark UI |

## Getting started

```bash
# 1. Install Flutter SDK (https://docs.flutter.dev/get-started/install)
flutter --version

# 2. Clone and bootstrap
git clone https://github.com/kishanflutter/trustgreen.git
cd trustgreen
cp .env.example .env       # then fill in real values
flutter pub get

# 3. Run
flutter run                # debug, attached device
flutter analyze            # static analysis
flutter test               # unit + widget tests (Phase 5)
```

## Project layout

```
lib/
├── main.dart                      # WidgetsFlutterBinding + ProviderScope
├── app.dart                       # MaterialApp.router + dark theme
├── core/
│   ├── env/app_env.dart          # typed .env accessor
│   ├── theme/tokens.dart         # colors, spacing, radii (single source of truth)
│   ├── theme/app_theme.dart      # Material 3 dark ThemeData
│   ├── responsive/breakpoints.dart
│   ├── responsive/responsive.dart # PrimaryColumn, ContentColumn helpers
│   ├── routing/route_paths.dart
│   └── routing/app_router.dart   # GoRouter + StatefulShellRoute
├── data/
│   ├── chains/chain_config.dart  # ChainCatalog (TG + 6 EVM chains)
│   └── storage/secure_storage.dart
├── state/
│   └── providers.dart            # Riverpod: secure storage, hasPin, hasAnyWallet, session
├── features/
│   ├── boot/                     # splash + first-launch routing
│   ├── auth/                     # PIN, create-import, create/verify/import/success
│   ├── shell/main_shell.dart     # bottom navigation
│   ├── wallet/                   # dashboard + stack
│   ├── market/, news/, browser/  # other tabs
│   └── settings/                 # index + 11 sub-pages
├── shared/widgets/
│   ├── safe_scaffold.dart        # dark scaffold + SafeArea
│   ├── primary_button.dart       # full-width CTA
│   ├── chain_logo.dart           # chain asset renderer
│   └── placeholder_screen.dart   # used by every unimplemented route
```

## Configuration

All runtime config lives in `.env` (loaded via `flutter_dotenv` and
registered as an asset in `pubspec.yaml`). See `.env.example` for
the full set of keys.

| Key                          | Purpose |
|------------------------------|---------|
| `TRUSTGREEN_CHAIN_ID`        | Featured/home chain numeric ID |
| `TRUSTGREEN_RPC_URL`         | Default RPC endpoint |
| `TRUSTGREEN_EXPLORER_URL`    | Block explorer base URL |
| `TRUSTGREEN_SYMBOL`          | Native symbol (e.g. `TG`) |
| `TRUSTGREEN_USDT`            | USDT contract on TG |
| `TRUSTGREEN_USDT_DECIMALS`   | 6 or 18 |
| `COINGECKO_API_KEY`          | Optional; CG- prefix uses Demo API |
| `NEWS_API_URL`               | Crypto news base URL |
| `NEWS_API_KEY`               | News API token |
| `NEWS_SECTION`               | `general` / `alltickers` |

`.env` is git-ignored. `.env.example` is the committed template.

## Identifiers

| Item               | Value |
|--------------------|-------|
| Package (Android)  | `com.trustgreen` |
| Bundle ID (iOS)    | `com.trustgreen` |
| Deep link scheme   | `trustgreen://` |
| Display name       | `Trust Green Wallet` |

## Responsive design

See [`RESPONSIVE.md`](./RESPONSIVE.md) — breakpoints, max column
widths, per-screen behaviour, accessibility text-scale plan, and
golden-test matrix.

## Phased rebuild plan

| Phase | Scope | Status |
|-------|-------|--------|
| 1 | Scaffolding: package id, theme tokens, dark Material 3, responsive helpers, `GoRouter` with all routes, placeholder screens, Android + iOS config, env loader, `RESPONSIVE.md`. | ✅ Done |
| 2 | Auth flow: PIN setup/unlock, mnemonic create/verify/import, secure storage, BIP-39 / BIP-32 derivation. | ⏳ Pending |
| 3 | Wallet stack: dashboard balances, send / receive / swap / scan / history / token list, confirm screens. | ⏳ Pending |
| 4 | Other tabs: market (`fl_chart` + CoinGecko), news, browser (`webview_flutter`), settings sub-pages. | ⏳ Pending |
| 5 | Polish: golden tests, `flutter analyze` clean, `flutter test` green, signing config, release docs. | ⏳ Pending |

## Source reference

The Expo / React Native source app is the canonical reference for
behaviour and visual design:

- Spec: `flutter_trustgreen.md` (Expo repo root)
- Screens: `app/` (Expo Router pages → mapped 1:1 to
  `lib/features/` in this project)
- Theme tokens: `theme/tokens.ts` → `lib/core/theme/tokens.dart`
- Chain config: `config/chains.ts` → `lib/data/chains/chain_config.dart`
