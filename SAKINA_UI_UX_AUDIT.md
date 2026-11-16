# Sakina UI/UX audit

Audit date: 2026-11-15. Scope: every file under `lib/` (219 Dart files, about
35,000 lines, of which 6,200 are generated l10n), the theme, the router and the
existing docs. Priorities: **P0** harms use or trust, **P1** clearly visible
quality gap, **P2** polish.

## 1. What the app is

- Flutter 3.47, Material 3, `provider` state, `go_router` navigation, GetIt DI.
- Arabic only (`locale: ar`), RTL throughout.
- 27 routes. Navigation is hub-and-spoke: the home screen is the hub, every
  feature is a pushed page. `MainNavigationShell` is a pass-through; there is no
  bottom bar, by owner decision (one entry point per destination).
- Three selectable designs (`warm` default, `sage`, `night`) plus a night
  reading theme for the Quran reader.
- A feedback service (haptics on, UI sounds off by default), reduced-motion
  support, an in-app text-size setting, and Arabic/Western digit styles
  already exist and are tested.

## 2. Current design assessment

What is already good:

- A real token layer exists: `AppSpacing`, `AppRadius`, `AppShadows`,
  `AppPalette`, `SakinaDecor`.
- Contrast is tested for the sage and night palettes.
- Reduced motion is honoured in transitions, entrances and loaders.
- Semantics labels, tooltips and 48dp targets are present on most controls.
- Loading uses a shared `PulseLoader`; four screens use a shared `EmptyState`.

What holds it back:

| # | Finding | Evidence | Priority |
|---|---|---|---|
| D1 | Tokens exist but most screens bypass them | 13 different corner radii (`circular(15)` ×17, `12` ×15, `20` ×11, `8` ×10, `16`, `10`, `18`, `14`…); 25 distinct literal font sizes; `AppRadius` used 22 times against 83 raw radii | P1 |
| D2 | The warm design is built by a different code path from sage/night | `lightTheme`/`darkTheme` are hand-built; the others use `_fromPalette`. Warm has no `tertiary`, no `onSurfaceVariant`, so its captions and outlines are seed-derived and drift | P1 |
| D3 | Warm dark mode is a neutral grey inversion, not a designed theme | `#121212` / `#1E1E1E` / `#242424` with a tan primary; none of the paper warmth of light mode carries over | P1 |
| D4 | Component themes are incomplete | Only elevated/outlined button, card, nav bar, sheet, dialog and input are themed. Filled/text/icon buttons, switch, checkbox, radio, segmented button, chip, list tile, snackbar, divider, progress, tooltip, popup menu, slider and tab bar all fall back to stock Material | P1 |
| D5 | Colours that belong to no design | Azkar grid uses ten saturated Material colours (blue, purple, pink, lime…); khatma button is `#F9D030` yellow; `Colors.brown.shade800`; splash `#5E3B29`; drawer icons `Colors.lightBlue`/`Colors.purple` | P1 |
| D6 | Typography has no line heights and weights are overridden everywhere | `AppTypography` sets size and weight only, leaving Cairo's loose default height on every style; 37 inline `fontFamily:` overrides; headings are restyled ad hoc as `fontSize: 18, bold` 25 times | P1 |
| D7 | Two parallel constant sets | `AppConstants.kPadding*`/`kBorderRadius*` duplicate `AppSpacing`/`AppRadius` | P2 |
| D8 | Private `_AppThemeExtensions` (success/warning/info, "premiumGradient") is unreachable from widgets | Declared private in `app_theme.dart`, so nothing can read it | P2 |

## 3. Screen-by-screen findings

**Home** (`home_screen.dart`, `home/*`, `widgets/*`)
- H1 (P1) Tiles are 11px bold labels under 40px PNGs in a 3-column grid; the PNG
  icons are a different style from the three Material icons beside them.
- H2 (P1) The wird card mixes five text colours and two unrelated buttons
  (yellow "finished", brown "read") with 8px radii while the card is 16px.
- H3 (P1) "Verse of the day" is chosen with `Random()` on every build of the
  screen, so it changes each visit; the card uses `Border(right:)`, which is a
  physical side.
- H4 (P1) The tab switcher and drawer switcher are two hand-built copies of
  the same control, with no animation, 12px text and no ripple shape.
- H5 (P2) Section headings are inconsistent (18 bold primary, 18 bold default,
  16 bold primary).
- H6 (P2) Drawer: header is a flat block with hardcoded white; icons mix
  outlined and filled; the qibla row loads `assets/images/kaaba.png`, which
  does not exist, and always falls back; two rows use `flutter_dash` and
  `camera_alt` in off-palette colours; five rows only show "coming soon".
- H7 (P2) Toast is a hand-rolled `OverlayEntry` without entrance animation or
  a screen-reader announcement.

**Quran list** — Q1 (P1) each card stacks Arabic name, English name and
translation at 18/16/12 with three colours; the number badge is a solid
circle rather than an ornament. Q2 (P2) error state is hand-built and tinted
red throughout.

**Surah reader** — R1 (P2) reader chrome uses raw radii and 14/16px literals;
bookmark and last-read actions give no haptic or visual confirmation beyond a
snackbar.

**Azkar categories** — A1 (P1) the rainbow tiles (D5) are the most off-brand
screen in the app. A2 (P2) a `DefaultTabController(length: 1)` placeholder
wraps the list and does nothing.

**Azkar details / Duas / After-adhan** — Z1 (P2) counters work and give
haptics; the completion moment has no visual change beyond the number.

**Tasbih** — T1 (P1) the count is a number on a flat block; tapping gives a
default ripple only. No ring, no pulse, nothing that feels like a counter.
T2 (P2) phrase rows use `GestureDetector` (no ripple, no focus state);
delete background uses a physical `Alignment.centerRight`.

**Prayer times / location dialog** — P1 (P2) solid, but the hero card is
duplicated between the home tab and this screen with different metrics
(44px vs 36px name).

**Qibla** — good motion already; two raw colours.

**Khatma (location, duration)** — K1 (P2) long forms built from raw
containers with 15/20px radii.

**Hadith, Asma, Guide, Media, Recitation** — consistent with the above:
functional, token-bypassing, stock Material controls.

**Settings** — S1 (P1) one flat 30-row list with no visual grouping; theme
mode, text size and digit style are three full-width dropdowns where a
segmented control reads faster; each alarm appears as two consecutive rows.

**Onboarding / Splash** — O1 (P2) splash uses two colours outside any palette
and a stock spinner.

## 4. Motion

- M1 (P1) One transition for everything (fade + 4% rise, 350 ms), including
  tab-like hub pages. There is no shared motion scale: durations 120, 250,
  320, 350, 400, 600, 900 ms appear as literals.
- M2 (P1) No press feedback beyond the ink ripple; no `Hero`; only three
  `AnimatedSwitcher`s and two `AnimatedContainer`s in the app. Selection
  changes (tabs, design picker, tasbih row, prayer row) snap.
- M3 (P2) `AnimatedEntrance` starts a `Future.delayed` per widget and is used
  per list row in the Quran list.

## 5. Sound and haptics

- F1 (P1) Only six events are wired (tasbih, adhkar, qibla, reset). Bookmark,
  favourite, finishing a wird, switching a tab or design, toggling a setting
  and errors are silent to the hand.
- F2 (P2) Sound is the platform click only. That is the right default for
  this app: no bundled audio, nothing musical, follows the silent switch.
  UI sound is not gated on recitation playing.

## 6. Notifications

- N1 (P2) The permission prompt, per-prayer modes, channels and deep links
  exist and are covered by tests. Gaps are presentational: the settings rows
  for alarms are split in two (S1) and a disabled state is not explained in
  place.

## 7. Arabic and RTL

- L1 (P1) 30 `TextAlign.right`, 31 `EdgeInsets.only(left/right…)`,
  `Alignment.centerRight/Left`, `Border(right:)`: correct today only because
  the app is Arabic-only, wrong the moment a second locale is added.
- L2 (P2) 24 nested `Directionality(rtl)` wrappers repeat what the locale
  already provides.
- L3 (P2) No style sets a line height, so everything inherits Cairo's
  natural 1.87: headings look loose and multi-line titles take more room
  than they need, while body text has no deliberate setting for diacritics.

## 8. Accessibility

- X1 (P1) 11px bold tile labels and 12px tab labels are below a comfortable
  Arabic reading size.
- X2 (P1) White 70% text on the feature card and on gradients is not
  contrast-tested for the warm design.
- X3 (P2) Custom tap targets built from `GestureDetector`/`InkWell` have no
  focus or hover state.
- X4 (P2) Selected state is colour-only in the two tab switchers and tasbih
  rows.

## 9. Performance

- V1 (P0) `NoiseBackground` wraps the whole app and builds a path of about
  5% of all pixels (≈18,000 rects on a phone) with a new `Random` on each
  paint. It is drawn *behind* the navigator, whose scaffolds are opaque, so
  the texture is never visible. Pure cost, repeated whenever the frame
  resizes (keyboard, rotation).
- V2 (P2) `SliverChildListDelegate` and per-row `AnimatedEntrance` timers in
  lists; several `Consumer`s rebuild whole cards for a one-line change.
- V3 (P2) The 40px home PNGs are decoded at full size (no `cacheWidth`).

## 10. Recommended direction

Keep the identity the owner chose: warm paper and brown by default, sage and
night as alternatives. Raise it by making the system do the work:

1. One palette-driven theme path for all three designs, with a designed warm
   dark mode and every Material component themed.
2. One motion scale and one press behaviour used everywhere.
3. A small set of shared widgets (card, section header, segmented control,
   pressable, status view) replacing the hand-built copies.
4. Rebuild the hub (home) on those parts, then sweep the feature screens.
5. Widen feedback events; keep sound opt-in and non-musical.

## 11. UI/UX changes versus new features

A. Done as UI/UX work (no new data or logic): everything in section 10.

B. Would be new product features; recorded, not built:
- About / share / rate / social links in the drawer (currently "coming
  soon"): need store URLs and owner accounts.
- A home layout the user can reorder: needs a persisted layout model.
- Bundled, licensed interface sounds: needs audio assets and a licence
  review; the platform click is used instead.
- Daily verse drawn from the full Quran dataset instead of six fixed verses:
  needs content review by the owner.
