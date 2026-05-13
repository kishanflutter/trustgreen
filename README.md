# Trust Green Wallet — Flutter

Multi-chain crypto wallet rebuilt from scratch in Flutter, mirroring
the Expo / React Native reference at
[`kishanflutter/trustgreen`](https://github.com/kishanflutter/trustgreen)
and the design spec in `flutter_trustgreen.md`.

> **Status:** Phases 1 – 4 complete. Wallet creation, multi-wallet
> management, live balances, send / receive, history, market,
> news and an in-app browser are all wired up against real APIs.
> Phase 5 (biometrics + polish) is the only thing left before
> production. See the [phased rebuild plan](#phased-rebuild-plan).

## Highlights

- **Multi-wallet, multi-chain.** Trust Green (BSC testnet), BNB,
  Ethereum, Avalanche, Polygon, Arbitrum, Optimism. Active chain
  is persisted; balances + prices auto-refresh.
- **PIN-only security.** 6-digit PIN derived via PBKDF2-HMAC-SHA256
  (200k iters, salt) — implemented in pure Dart and run on a
  background isolate so the UI never freezes. Mnemonic is encrypted
  with AES-256-GCM using the PIN-derived key.
- **BIP-39 / BIP-32.** 12 / 18 / 24-word phrases, EIP-55 checksummed
  EVM addresses, standard `m/44'/60'/0'/0/0` derivation.
- **Live send + receive.** Address QR, paste / scan recipient, MAX
  with gas reserve, debounced gas estimate, USD equivalent, review
  sheet, **PIN re-prompt every transaction**, signed broadcast,
  receipt polling.
- **History, Market, News, Browser.** Etherscan V2 unified history
  (native + ERC-20), CoinGecko top-50 with 7-day sparklines, coin
  detail with fl_chart (24h / 7d / 30d / 1y), Crypto News API feed,
  and a webview_flutter tab with a smart URL bar.
- **71 unit tests** green; `flutter analyze` clean; debug APK builds.

## Requirements

| Tool      | Version            |
|-----------|--------------------|
| Flutter   | `>= 3.24` (tested on 3.29.2) |
| Dart      | `^3.7.2`           |
| Android   | minSdk 23, target 36, NDK 27.0.12077973, Kotlin 2.1.20 |
| iOS       | iOS 13+, portrait-only, dark UI |

## Getting started

```bash
# 1. Install Flutter SDK — https://docs.flutter.dev/get-started/install
flutter --version

# 2. Clone and bootstrap
git clone https://github.com/kishanflutter/trustgreen.git
cd trustgreen
cp .env.example .env       # fill in your CoinGecko + News API keys
flutter pub get

# 3. Run
flutter run                # debug, attached device
flutter analyze            # static analysis — must be clean
flutter test               # 71 unit tests
flutter build apk --debug  # ./build/app/outputs/flutter-apk/app-debug.apk
```

### First-run UX

1. **Splash** (native + Flutter handoff) → **Set PIN** (6 digits, twice)
2. **Create or import wallet**
   - *Create*: choose 12 / 18 / 24 words → display mnemonic → 3-position
     random word verification → wallet committed.
   - *Import*: paste / type mnemonic with live per-word BIP-39
     validation → import.
3. **Success** → main 5-tab shell.

After this any restart goes through the unlock PIN screen only.

## Project layout

```
lib/
├── main.dart                              # binding + dotenv + active-chain hydration
├── app.dart                               # MaterialApp.router + dark theme
│
├── core/
│   ├── env/app_env.dart                   # typed .env accessor
│   ├── theme/{tokens,app_theme}.dart      # colors, spacing, Material 3 dark
│   ├── responsive/{breakpoints,responsive}.dart
│   └── routing/{route_paths,app_router}.dart
│
├── data/
│   ├── auth/
│   │   ├── crypto_utils.dart              # PBKDF2 (sync + async/compute), hex, CT-equals
│   │   ├── pin_service.dart               # PIN hash/verify + storage
│   │   └── wallet_cipher.dart             # AES-256-GCM with PIN-derived key
│   ├── chains/chain_config.dart           # ChainCatalog (TG + 6 EVM chains)
│   ├── history/
│   │   ├── etherscan_v2_client.dart       # unified V2 API, txlist + tokentx merge
│   │   └── tx_history_models.dart
│   ├── market/
│   │   ├── coingecko_market.dart          # top-50, search, market_chart
│   │   └── market_models.dart
│   ├── news/
│   │   ├── crypto_news_client.dart        # cryptonews-api.com
│   │   └── news_models.dart
│   ├── prices/price_service.dart          # CoinGecko simple/price + 60s cache
│   ├── rpc/
│   │   ├── erc20.dart                     # minimal ABI + transfer-call encoder
│   │   └── rpc_service.dart               # per-chain Web3Client pool, fee quote
│   ├── storage/secure_storage.dart        # PIN + multi-wallet keychain layout
│   ├── tx/send_pipeline.dart              # sign-and-broadcast (PIN → PK → tx)
│   └── wallet/
│       ├── hd_wallet.dart                 # BIP-39 + BIP-32 + EVM derivation
│       ├── wallet_models.dart             # WalletMeta + WalletSecret
│       └── wallet_repository.dart         # multi-wallet CRUD (atomic)
│
├── state/
│   ├── providers.dart                     # storage, PIN service, session, has-pin/has-wallet
│   ├── onboarding_provider.dart           # transient setup state
│   ├── wallet_providers.dart              # walletsList, activeWallet
│   ├── chain_providers.dart               # activeChain (persisted), RPC + price services
│   ├── balance_providers.dart             # native + USDT balance family + price family
│   ├── history_providers.dart             # Etherscan client + tx history family
│   ├── market_providers.dart              # topMarkets, search, coinChart family
│   └── news_providers.dart                # latestNews
│
├── features/
│   ├── boot/                              # splash + first-launch routing
│   ├── auth/                              # PIN, create-import, create/verify/import/success,
│   │                                      # PinConfirmSheet (reusable signing prompt)
│   ├── shell/main_shell.dart              # 5-tab bottom navigation
│   ├── wallet/                            # dashboard, receive, send, send-review,
│   │   ├── widgets/                       # tx-pending, history, qr-scan,
│   │   └── ...                            # chain/wallet picker sheets
│   ├── market/
│   │   ├── market_screen.dart             # top-50 + search + sparklines
│   │   └── coin_detail_screen.dart        # fl_chart, range selector, tooltip
│   ├── news/news_screen.dart              # article cards + sentiment / ticker pills
│   ├── browser/browser_screen.dart        # WebView + URL bar + nav controls
│   └── settings/                          # index + 11 sub-pages (Phase 5 polish)
│
└── shared/widgets/
    ├── safe_scaffold.dart                 # dark scaffold + SafeArea
    ├── primary_button.dart                # full-width CTA
    ├── chain_logo.dart                    # chain asset renderer + icon fallback
    ├── pin_boxes.dart                     # animated PIN dots with shake
    ├── numeric_pad.dart                   # 3×4 numeric keypad with haptics
    └── placeholder_screen.dart            # used by routes still on Phase 5
```

## Configuration

All runtime config lives in `.env`, loaded via `flutter_dotenv` and
registered as an asset in `pubspec.yaml`. `.env` is git-ignored —
copy `.env.example` and fill in your keys before the first run.

| Key                          | Purpose | Required |
|------------------------------|---------|----------|
| `TRUSTGREEN_CHAIN_ID`        | Featured / home chain numeric ID | yes |
| `TRUSTGREEN_RPC_URL`         | Default RPC endpoint | yes |
| `TRUSTGREEN_EXPLORER_URL`    | Block-explorer base URL | yes |
| `TRUSTGREEN_SYMBOL`          | Native symbol (e.g. `TG`) | yes |
| `TRUSTGREEN_USDT`            | USDT contract on the TG chain | yes |
| `TRUSTGREEN_USDT_DECIMALS`   | 6 or 18 | yes |
| `COINGECKO_API_KEY`          | Demo or Pro CoinGecko key (CG- prefix = Demo) | recommended |
| `NEWS_API_URL`               | Crypto News base URL | optional |
| `NEWS_API_KEY`               | Crypto News API token | optional |
| `NEWS_SECTION`               | `general` / `alltickers` | optional |
| `ETHERSCAN_API_KEY`          | Lifts history rate limit (1/5s → 5/s) | optional |
| `BROWSER_HOME_URL`           | Default page for the Browser tab | optional |

## Tech stack

| Layer | Choice | Notes |
|-------|--------|-------|
| State | `flutter_riverpod` 2.6 | `StateNotifier`, `FutureProvider.family`, persisted overrides |
| Routing | `go_router` 14.x | `StatefulShellRoute` for the 5-tab shell |
| Storage | `flutter_secure_storage` 9.x + `shared_preferences` | secrets in keystore / keychain, non-sensitive prefs in shared prefs |
| Crypto | `crypto` (HMAC), `pointycastle` (AES-GCM), custom Dart PBKDF2 | PIN never leaves the device |
| Chain RPC | `web3dart` 2.7 | per-chain pooled `Web3Client` |
| HD wallet | `bip39` 1.0 + `bip32` 2.0 | English wordlist, mnemonic ↔ seed ↔ PK |
| HTTP | `dio` 5.x (`http` 1.x for web3dart) | retry-friendly, mock-friendly |
| Charts | `fl_chart` 0.69 | sparklines + coin detail line chart |
| Camera | `mobile_scanner` 6.x | QR scanning for recipient pre-fill |
| WebView | `webview_flutter` 4.x | in-app browser tab |
| QR display | `qr_flutter` 4.x | white-on-black per spec §5.5 |

## Security model

- PIN never written anywhere — only its PBKDF2(salt, 200k) hash is stored.
- Mnemonic encrypted with AES-256-GCM; key derived from PIN via the same
  PBKDF2 (different salt). Wrong PIN ⇒ authentication-tag failure ⇒ refused.
- Each transaction requires a fresh PIN entry. The decrypted mnemonic and
  derived private key live only for the duration of `signAndBroadcast()`
  and are dropped immediately afterwards.
- Wallets created with rollback semantics: encrypted blob is written first,
  index second; if the index write fails the orphan blob is deleted.
- Multi-wallet support via per-wallet keychain entries (`tg_wallet_{id}_blob`)
  + a single index pointer (`tg_wallets_index`).
- Trust Green chain UI shows a `TESTNET` badge; USD price is hidden because
  the native "TG" token has no public price.

## Identifiers

| Item               | Value |
|--------------------|-------|
| Package (Android)  | `com.trustgreen` |
| Bundle ID (iOS)    | `com.trustgreen` |
| Deep link scheme   | `trustgreen://` |
| Display name       | `Trust Green Wallet` |

## Responsive design

See [`RESPONSIVE.md`](./RESPONSIVE.md) — breakpoints, max column widths,
per-screen behaviour, accessibility text-scale plan and golden-test matrix.

## Testing

```bash
flutter test                    # 71 tests; ~12 s on a recent laptop
```

Covered:

- `crypto_utils_test.dart` — PBKDF2 RFC-6070 vectors, constant-time
  equality, hex round-trip, secure random bytes.
- `wallet_cipher_test.dart` — AES-GCM round-trip, wrong-PIN rejection,
  distinct ciphertexts per encryption, structurally-invalid blob.
- `hd_wallet_test.dart` — BIP-39 generation, length triplet, valid-vs-
  invalid mnemonic, deterministic EVM address.
- `wallet_models_test.dart` — `WalletMeta.listFromJsonString` always
  returns a growable list (regression guard).
- `erc20_test.dart` — canonical `0xa9059cbb` selector, address padding,
  uint256 encoding, multi-byte large values.
- `token_amount_test.dart` — format / parse round-trips, decimals,
  malformed input rejection.
- `chain_config_test.dart` — catalog completeness, coingeckoId per
  mainnet, explorer URL helpers strip trailing slashes.
- `price_service_test.dart` — CoinGecko fake adapter, cache TTL, empty
  / 500 fallback.
- `etherscan_v2_client_test.dart` — txlist + tokentx merge, direction
  classification, failed tx flagging, rate-limit fallback, unsupported
  chain handling.
- `market_models_test.dart` — MarketCoin / CoinSearchResult /
  CoinChartSeries parsing, missing-field tolerance.
- `news_models_test.dart` — RFC-1123 date parsing, ticker / sentiment,
  missing-field tolerance.
- `smoke_test.dart` — app boots and renders the boot screen.

## Phased rebuild plan

| Phase | Scope | Status |
|-------|-------|--------|
| 1 | Scaffolding: package id, theme tokens, dark Material 3, responsive helpers, `GoRouter` with all routes, placeholder screens, Android + iOS config, env loader, `RESPONSIVE.md`. | ✅ Done |
| 2 | Auth flow: PIN setup/unlock (PBKDF2 async, 200k iter), mnemonic create / verify / import (12/18/24), multi-wallet secure storage, AES-256-GCM encrypt, BIP-39/BIP-32. Adaptive icon + native splash. | ✅ Done |
| 3 | Wallet stack: per-chain RPC client, active-chain state (persisted), native + USDT balances + CoinGecko prices, real dashboard, receive (QR), send (paste / scan, MAX, live gas, USD), review sheet, PIN-gated sign + broadcast, tx-pending screen. | ✅ Done |
| 4 | Activity & discovery: Etherscan V2 unified history (native + ERC-20), HistoryScreen + dashboard teaser, Market tab (top-50, search, sparklines, coin chart with fl_chart), News tab (cryptonews-api), Browser tab (webview_flutter with URL bar). | ✅ Done |
| 5 | Polish: biometric unlock (`local_auth`), screen-capture guard for mnemonic, in-app swap (1inch / 0x), custom token list, settings sub-pages (chain on/off, reveal seed, export), golden tests, release signing config, GitHub Actions CI. | ⏳ Pending |

## Source reference

The Expo / React Native source app is the canonical reference for
behaviour and visual design:

- Spec: `flutter_trustgreen.md` (Expo repo root)
- Screens: `app/` (Expo Router pages → mapped 1:1 to `lib/features/`)
- Theme tokens: `theme/tokens.ts` → `lib/core/theme/tokens.dart`
- Chain config: `config/chains.ts` → `lib/data/chains/chain_config.dart`

## Contributing

1. Fork + branch (`feat/your-feature`).
2. `flutter analyze` and `flutter test` must stay green.
3. Add unit tests for any new business logic in `lib/data/` or
   `lib/state/`.
4. Open a PR — the description should call out screens / providers
   touched and any new `.env` keys.

## License

Internal / unlicensed at the moment. Treat as proprietary until a
formal license is added.
