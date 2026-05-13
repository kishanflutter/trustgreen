# Responsive layout — Trust Green Wallet (Flutter)

This document captures how Trust Green Wallet adapts across phones,
tablets, foldables, and accessibility text scales. It complements
§2 of `flutter_trustgreen.md` in the Expo source repo (the rebuild
spec).

## Breakpoints

Defined in `lib/core/responsive/breakpoints.dart`. Width-based, not
platform-based.

| Breakpoint | Width            | Typical device                            |
|------------|------------------|-------------------------------------------|
| compact    | `< 600 dp`       | Phones (incl. foldable cover screens)     |
| medium     | `600 – 899 dp`   | Small tablets, large foldables (unfolded) |
| expanded   | `>= 900 dp`      | Large tablets, desktop / web              |

Helpers live in `lib/core/responsive/responsive.dart`:

- `Responsive.of(context).breakpoint`
- `Responsive.of(context).font(base, ...)` — fluid scale, clamped
  between `0.85×` and `1.1×` of the design base.
- `PrimaryColumn` widget — caps width at **480 dp** on tablets.
- `ContentColumn` widget — caps width at **560 dp** on tablets.

## Max content widths

| Block type        | Max width |
|-------------------|-----------|
| Primary column    | 480 dp    |
| Content column    | 560 dp    |
| Bottom sheet      | 560 dp    |
| Dialog            | 480 dp    |

Wider screens center the column horizontally with symmetric padding.

## Per-screen behaviour (Phase 1 baseline)

| Screen              | Behaviour |
|---------------------|-----------|
| `boot`              | Centered spinner. |
| `create-import`     | Full-bleed `BoxFit.cover` JPEG background; primary column (480 dp) centered; logo scales with `Responsive.font`. |
| `success`           | Same treatment as `create-import`. |
| `pin`               | Placeholder — Phase 2 will switch to two-column on `expanded` (keypad + status side-by-side on tablets ≥ 900 dp). |
| `wallet/index`      | Single column on compact; `ContentColumn` (560 dp) on medium/expanded. Asset rows wrap if the actions row gets too tight (`SingleChildScrollView` fallback). |
| `wallet/*` (stack)  | Placeholder; sub-routes inherit `ContentColumn` once implemented. |
| `market`, `news`, `browser` | Placeholder — Phase 4 will add two-pane (master/detail) on `expanded`. |
| `settings/index`    | `ContentColumn` for each row; full-width list on compact. |
| `settings/*`        | Placeholder; same treatment planned. |

## Typography

- Material 3 base text theme from `GoogleFonts.interTextTheme`.
- `Responsive.font(base)` clamps fluid scale between `0.85×` and
  `1.1×` of the design base — small phones never overflow, tablets
  never look toy-sized.
- All text colours come from `AppColors` (`textPrimary`,
  `textSecondary`, `textTertiary`). No inline hex.

## Accessibility — text scale 1.3×

- `Responsive.of(context).isLargeTextScale` reports whether the user
  has scaled text 1.3× or more. Screens use this to stack rows that
  would otherwise overflow horizontally.
- Goldens for `wallet/index`, `pin`, `create-import`, and one
  settings page will land in Phase 5 at:
  - `390 × 844`     (phone reference)
  - `820 × 1180`    (tablet portrait)
  - `390 × 844`     with `textScaleFactor = 1.3`

## Safe areas

- `SafeScaffold` inserts a `SafeArea` automatically. Pages opt out
  on the top edge when they show their own custom header.
- Edge-to-edge system chrome is configured in `lib/main.dart`
  (transparent status bar, dark icons).

## Orientation

- Portrait-only in v1 (matches the Expo app and §2.1.10 of the
  spec). Locked in `lib/main.dart` via
  `SystemChrome.setPreferredOrientations`.

## Assets

- `assets/images/onboarding-circuit-bg.jpg` — `BoxFit.cover` only.
  Never stretch; never re-extension as PNG.
- `assets/images/wallet-success-circuit-bg.jpg` — same.
- `assets/chains/*.png` — 512×512 source; rendered at 32 dp on
  asset rows, 20 dp in the network dropdown.

## Open items (later phases)

- Golden tests across breakpoints (Phase 5).
- Master/detail two-pane layouts for `market`, `news`, and `browser`
  on expanded width.
- RTL pass — currently no `Directionality.maybeOf` overrides; UI
  reviewed visually but not golden-locked.
