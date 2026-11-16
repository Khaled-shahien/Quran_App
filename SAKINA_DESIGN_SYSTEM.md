# Sakina design system

The system lives in `lib/core/theme/` and `lib/core/widgets/`. Screens take
colour, type, spacing, radius, motion and feedback from here and from nowhere
else. If a value is missing, add it here first.

## Principles

1. **Calm before clever.** One accent per screen, generous space, no
   decoration that does not carry meaning.
2. **The text is the content.** Verses and adhkar get the script face, room
   and contrast; everything else steps back.
3. **Ornament is a signature, not wallpaper.** The geometric pattern appears
   only on feature surfaces (headers, the verse card, the side-menu header,
   empty states) at 7–8% opacity.
4. **Motion explains a change.** Something moved, was chosen, or finished.
   Nothing loops for decoration, and reduced motion removes all of it.
5. **Arabic first.** Layout is written with start/end, never left/right.

## Colour

Three designs, chosen in Settings. Each is an `AppPalette`
(`app_design.dart`); `AppTheme._fromPalette` turns any palette into a full
`ThemeData`, so designs differ in colour only.

| Role | Warm light | Warm dark | Sage light | Sage dark | Night |
|---|---|---|---|---|---|
| `primary` | `#795547` | `#D9B690` | `#1F5C4A` | `#8FC7AE` | `#D4AF6A` |
| `onPrimary` | `#FFFFFF` | `#21160F` | `#F6F4EE` | `#0F1714` | `#101826` |
| `secondary` (tiles) | `#F0E6D2` | `#2A211C` | `#E3EDE7` | `#1E2C26` | `#22304A` |
| `background` | `#FEFBF4` | `#17120F` | `#F6F4EE` | `#0F1714` | `#101826` |
| `text` | `#2A1F1A` | `#F3EAE0` | `#1C2723` | `#E8EFEA` | `#EDE3CF` |
| `body` | `#54463F` | `#D9CCBF` | `#3E4C46` | `#C9D3CD` | `#D5CCBA` |
| `caption` | `#675757` | `#B3A497` | `#4F5E57` | `#A3B1AA` | `#A9B2C3` |
| `outline` | `#81756F` | `#8C7B6E` | `#6F7E77` | `#7A8C84` | `#6B7A99` |
| `decor.accent` | `#CC9B76` | `#CC9B76` | `#8A6A2E` | `#C9A66B` | `#D4AF6A` |
| `decor.card` | `#FFFFFF` | `#211A16` | `#FFFFFF` | `#16211C` | `#182235` |
| `decor.featureCard` | `#3A2A22` | `#2E221B` | `#16463A` | `#16463A` | `#0B1220` |
| `decor.heroColors` | `#8A6450→#4E342E` | `#6B4A3A→#3A2620` | `#2A7560→#16463A` | `#1F5C4A→#0F2E25` | `#2A3A5C→#0B1220` |

Rules:

- Warm dark is designed, not inverted: espresso surfaces and sand text keep
  the paper feeling at night. No neutral greys.
- Light text on `featureCard` and `heroColors` uses `decor.onFeature`
  (white) and `decor.onFeatureMuted` (80%).
- Status uses `decor.success`, `decor.warning` and `colorScheme.error`,
  always with an icon or text, never colour alone.
- Every pair above is held to WCAG AA by `test/core/theme/app_design_test.dart`
  (4.5:1 text, 3:1 outlines) for all five palettes.
- The night reading theme (`AppTheme.nightReadingTheme`) is separate and
  applies only inside the Quran reader.
- No `Color(0x…)` or `Colors.*` in feature code, except `Colors.transparent`.
  The splash screen is the one exception: it is matched to its artwork.

## Typography

`app_typography.dart`. Cairo for the interface, Amiri for sacred text shown
on cards, Amiri Quran inside the reader.

| Style | Size / weight / height | Use |
|---|---|---|
| `displaySmall` | 36 / 700 / 1.3 | Next-prayer name |
| `headlineSmall` | 24 / 700 / 1.4 | Screen-level statements |
| `titleLarge` | 20 / 700 / 1.45 | App bar titles, dialog titles, hero titles |
| `titleMedium` | 16 / 600 / 1.5 | Section headers, list titles |
| `titleSmall` | 14 / 600 / 1.5 | Row titles, card labels |
| `bodyLarge` | 16 / 400 / 1.7 | Long reading text |
| `bodyMedium` | 14 / 400 / 1.7 | Default body |
| `bodySmall` | 12.5 / 400 / 1.6 | Captions, metadata |
| `labelLarge` | 14 / 600 / 1.45 | Buttons, segments |
| `labelMedium` | 12.5 / 600 / 1.45 | Chips, tile labels |
| `AppTypography.script` | Amiri 24 / 700 / 1.8 | Verses and adhkar on cards |
| `AppTypography.numeral` | Cairo 40 / 800 / 1.1, tabular | Counters and clocks |

Rules: take styles from `Theme.of(context).textTheme` and change colour or
weight with `copyWith`; do not write `fontSize:` in feature code. Nothing
below 12.5. Numbers pass through `context.digits()` so the digit-style
setting applies.

## Spacing, radius, elevation

`AppSpacing` (4-point): `xxs 2 · xs 4 · sm 8 · ms 12 · md 16 · lg 24 · xl 32
· xxl 48`. `page` (16) is the horizontal page margin; `touchTarget` is 48.

`AppRadius`, by role: `chip` 8 · `controls` 12 (buttons, inputs, rows) ·
`card` 16 · `hero` 24 · `dialog`/`sheet` 28 · `pill`.

`AppShadows`: `subtle` (resting cards), `card` (raised), `floating` (toasts).
Shadows are warm-tinted and used in light themes only; dark themes separate
surfaces by colour and a hairline `outlineVariant` border.

## Motion

`AppMotion`:

| Token | Value | Use |
|---|---|---|
| `fast` | 120 ms | Press states |
| `base` | 200 ms | Selection, switches, the segmented thumb |
| `medium` | 320 ms | Entrances, page transitions in |
| `exit` | 220 ms | Page transitions out |
| `slow` | 480 ms | Progress fills |
| `stagger` | 40 ms | Gap between items entering in sequence |
| `enter` / `leave` / `standard` | easeOutCubic / easeInCubic / (0.2, 0, 0, 1) | Arriving / leaving / moving in place |
| `pressedScale` | 0.97 | `Pressable` while held |

`AppMotion.of(context, duration)` returns zero when the system asks for
reduced motion; use it for every implicit animation. Lists stagger only the
first screenful. Page transitions are a fade with a 4% rise.

## Feedback

`FeedbackService` (`lib/core/feedback/`). Screens call
`playFeedback(context, event)` and never touch `HapticFeedback` directly.

| Event | Haptic | Sound (if enabled) |
|---|---|---|
| `selection` (tabs, segments, design, tasbih row) | selection tick | — |
| `toggle` | light | — |
| `bookmark`, `favorite` | light | click |
| `success` (wird finished) | double pulse | click |
| `warning` | heavy | — |
| `tasbihCount` / `adhkarCount` | tick / light | click |
| `tasbihSetComplete` / `adhkarComplete` / `qiblaAligned` | double pulse | click / click / — |
| `reset` | medium | — |

Haptics are on by default, sounds off. The only sound is the platform click:
no bundled audio, nothing musical, and it follows the phone's own
touch-sound and silent settings. Sounds are suppressed while recitation is
playing (`FeedbackService.isSacredAudioPlaying`).

## Components

Material components are themed once in `app_theme.dart`: elevated, filled,
outlined, text and icon buttons; FAB; segmented button; switch; checkbox;
radio; slider; progress; chip; card; list tile; divider; navigation bar; tab
bar; bottom sheet; dialog; snackbar; banner; popup and menu; tooltip; drawer;
input; scrollbar. Use them unstyled.

Button hierarchy: one `FilledButton` per view for the main action,
`OutlinedButton` for the alternative, `TextButton` for dismissals. All are
at least 48 high with 12 radius.

Shared widgets (`lib/core/widgets/`):

| Widget | Use |
|---|---|
| `Pressable` | Any custom tappable surface: ripple, shrink while held, focus ring, optional feedback event and semantics label. Replaces bare `InkWell`/`GestureDetector`. |
| `SakinaCard` | The one card. `plain` (card colour, hairline, soft shadow), `tinted` (tile colour, flat), `feature` (deep colour). Tappable when `onTap` is set. |
| `SectionHeader` | Accent mark + `titleMedium` title + optional trailing. Every section heading. |
| `SakinaSegmented` | Two-or-more way switch with a sliding thumb. Home tabs, side-menu tabs. |
| `StatusView` | Icon medallion + message + optional action. Load failures. |
| `EmptyState` | Ornament medallion + message. Nothing-here-yet. |
| `PulseLoader` | Skeleton lines while loading. |
| `AnimatedEntrance` | Fade and rise on first appearance. |
| `GeometricPattern` | The ornament; decorative, hidden from screen readers. |

## Iconography

Material Symbols in the rounded/outlined family: outlined for navigation and
rows, filled only for a selected or active state (a set bookmark, a favourite
heart). 24 in app bars, 20 inside 36 medallions in menus, 28 inside hero
medallions. Back uses `arrow_back_ios`, which mirrors in RTL.
The six home category images are the app's own artwork and stay.

## Accessibility

- Text contrast AA in every palette (tested). Captions use `caption`, never
  an alpha of `text`.
- Touch targets 48 minimum; tested by the large-text audit.
- Every screen must lay out without overflow at 200% text
  (`test/accessibility/`).
- Custom controls announce role, label and selected state; decorative
  elements are excluded.
- Selected and finished states carry a mark (dot, tick, border) as well as
  colour.
