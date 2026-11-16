# Sakina UI/UX development plan

Status values: `[ ]` Not Started · `[~]` In Progress · `[x]` Completed ·
`[!]` Blocked. A task is marked completed only after `flutter analyze` and the
relevant tests pass. Finding IDs (D1, H2…) refer to `SAKINA_UI_UX_AUDIT.md`.

Branch: `ui-ux-transformation` (nothing committed; the owner commits).

**Resume here:** nothing is in progress. Open items are listed under Open issues.

## Later passes (2026-11-15)

Verified at the end: `flutter analyze` clean, 665 tests passing, format
clean, debug build checked on the Pixel 7 Pro emulator in the night design.

- Codemods: raw corner radii and font-family literals (25 files) and 53
  inline `TextStyle(fontSize: …)` (16 files) moved onto tokens. The text
  codemod caused one regression (button labels in the permission dialog
  took the page ink colour); found and fixed.
- Codemod: on-scale spacing literals (4, 8, 12, 16, 24, 32, 48) became
  `AppSpacing` tokens in 28 files with no visual change; off-scale values
  were snapped in onboarding and qibla only.
- New shared pieces: `StatusView.footnote`, `KhatmaDropdown`, a theme-wide
  back-button icon (`actionIconTheme`).
- Found, not changed: `widgets/prayer_time_header.dart` is no longer used
  by any screen.

## Quran reader redesign (2026-11-16)

Tracked in `SAKINA_QURAN_READER_IMPLEMENTATION_PLAN.md`; findings in
`SAKINA_QURAN_READER_AUDIT.md`. Supersedes task 5.6 for the reading area.

- [x] Continuous reading (default): flowing text, inline end-of-ayah
  ornament, no card, mushaf page markers
- [x] Verse-by-verse layout
- [x] Mushaf page layout on authentic page boundaries (not line-exact; the
  data has no line information)
- [x] Verse actions: listen from here, bookmark here, copy
- [x] Bookmarks by verse, with conversion of old page-index bookmarks
- [x] Duplicate basmala banner removed
- [x] Integrity tests against the source text
- [x] Status-bar icon colour stated in the theme (was white on light paper
  on screens with a transparent app bar)

## Uthmanic font and fixed mushaf pages (2026-11-16)

- [!] KFGQPC Uthmanic Hafs: blocked on the licence; Amiri Quran stays
  (`SAKINA_UTHMANIC_FONT_AUDIT.md`)
- [x] Mushaf pages: horizontal only, fixed, fitted; slim page bar
- [x] Two reader bugs fixed (wird page split, bookmark restoration)
- [x] Tests: 696 passing (680 before)

**Resume here:** the font switch, once written approval exists (steps in the
font audit, section 5).

## Phase 1 — Audit

- [x] 1.1 Read architecture, router, theme, shared widgets, feedback service
- [x] 1.2 Measure token bypass (radii, font sizes, colours, RTL literals)
- [x] 1.3 Write `SAKINA_UI_UX_AUDIT.md`
- [x] 1.4 Baseline before any change: analyze clean, 663 tests passing

## Phase 2 — Design system

- [x] 2.1 Tokens: extended `AppRadius`, `AppSpacing`, `AppShadows`; added `AppMotion` (D1, M1)
- [x] 2.2 Typography with line heights, `script` and `numeral` styles (D6, L3)
- [x] 2.3 Warm palette as `AppPalette`; designed warm dark mode (D2, D3)
- [x] 2.4 Single theme builder with every component themed (D4)
- [x] 2.5 `success`, `warning`, `onFeature` on `SakinaDecor`; private extension removed (D8)
- [x] 2.6 Contrast tests extended to the warm palettes and to card/tile pairs (X2)
- [x] 2.7 `SAKINA_DESIGN_SYSTEM.md`

## Phase 3 — Core experience

- [x] 3.1 Shared widgets: `Pressable`, `SakinaCard`, `SectionHeader`, `SakinaSegmented`, `StatusView` (H4, H5, M2)
- [x] 3.2 Noise painter removed (V1)
- [x] 3.3 Home header and date card
- [x] 3.4 Home wird card (H2)
- [x] 3.5 Home verse of the day (H3)
- [x] 3.6 Home tabs, category grid, prayer tab (H1, H4, X1)
- [x] 3.7 Home drawer and toast (H6, H7)

## Phase 4 — Interactive experience

- [x] 4.1 Motion scale applied to route transitions and entrances (M1, M3)
- [x] 4.2 New feedback events: selection, toggle, bookmark, favourite, success, warning (F1)
- [x] 4.3 New events wired on every tab, picker, switch, bookmark, favourite, stepper and completion in the app
- [x] 4.4 UI sounds stay silent while recitation plays (F2)

## Phase 5 — Remaining screens

- [x] 5.1 Quran list (Q1, Q2)
- [x] 5.2 Azkar categories (A1, A2)
- [x] 5.3 Tasbih (T1, T2)
- [x] 5.4 Settings: sections on cards, theme mode and digit style as segmented controls, each reminder on one row. Text size stays a dropdown by decision (four long labels do not fit a segmented control at large text).
- [x] 5.5 Splash (O1) — kept its artwork colours, documented as the one exception
- [x] 5.6 Surah reader chrome (R1): plain themed icon buttons, type-scale title and page counter, motion tokens. The Quran text itself is untouched by design.
- [x] 5.7 Azkar details, Duas, After-adhan (Z1)
- [x] 5.8 Prayer times screen. The location dialog is built from stock controls and takes the theme as it is (P1)
- [x] 5.9 Khatma start and duration screens: card, shared dropdown, selectable plan cards with a tick, one shared stepper row, reminder field (K1)
- [x] 5.10 Hadith list card and details
- [x] 5.11 Asma al-Husna: item card, spacing, themed app bar
- [x] 5.12 Islamic guide cards: palette surfaces, accent-edged dua block, token motion
- [x] 5.13 Media tiles, article cards, video and channel cards
- [x] 5.14 Mini player and player sheet. The recitation list and downloads screens are stock controls and take the theme as they are.
- [x] 5.15 Qibla: success colour, type-scale dial labels, spacing tokens. Its 250 ms dial easing is kept; a test pins it.
- [x] 5.16 Notification permission dialog rebuilt; onboarding pages on spacing, radius and motion tokens
- [x] 5.17 Duplicate `AppConstants` dimension constants removed (D7)

Screens in 5.6–5.16 already pick up the new palette, type scale and component
themes; what remains is replacing their hand-set radii, font sizes and
containers with tokens and shared widgets.

## Phase 6 — Accessibility and performance

- [x] 6.1 Directional layout: no `TextAlign.right`, physical insets or physical alignments remain in live screens. Two intentional exceptions: the English translation in favourites is left-aligned, and the unused `widgets/prayer_time_header.dart` (L1).
- [!] 6.2 Remove redundant `Directionality` wrappers (L2). Not done by decision: they are invisible to users, `azkar_screen_test` requires the wrapper, and screens shown without the app's locale (tests, previews) rely on them.
- [x] 6.3 Large-text audit passes at 200% for every audited screen and design
- [x] 6.4 `cacheWidth` on home tile images and video thumbnails; builder delegates on the home and azkar grids; staggered entrance limited to the first eight Quran rows. The remaining non-lazy lists hold six to thirty fixed rows (V2, V3).

## Phase 7 — Quality assurance

- [x] 7.1 `flutter analyze` clean
- [x] 7.2 Full `flutter test` green (665), re-run after every pass
- [x] 7.3 Settings golden baselines regenerated and reviewed
- [~] 7.4 Device check on the Android emulator (API 36), in warm light, warm dark, night and sage: onboarding, home, side menu, Quran list, surah reader, azkar categories, adhkar list, tasbih, khatma start and duration, settings, Asma al-Husna, guide, prayer times, hadith list, media. Not checked: the qibla dial (needs the location permission, which was not granted), after-adhan, articles and videos (network), haptics and sound.
- [x] 7.5 Final report

## Decisions

1. **Identity kept.** Warm stays the default and keeps its brown `#795547`
   and paper `#FEFBF4`; sage and night keep their palettes. The work went into
   the system around them.
2. **Warm accent text.** White on the caramel accent `#CC9B76` was 2.4:1.
   The accent stays; text on it is now ink `#2A1F1A` (6.5:1).
3. **Warm hero gradient.** The old gradient began with amber at 80% alpha,
   on which white text failed contrast. It is now `#8A6450 → #4E342E`.
4. **Headers use the hero gradient, not `primary`.** In dark themes `primary`
   is a light sand; a full-width sand header would glare at night.
5. **Verse of the day is chosen by calendar day**, not `Random()` per visit.
   The six verses themselves were not edited (verified: no diff in those
   lines).
6. **Dialogs sit on the card colour**, not the page colour, so they lift off
   the page in dark themes. `settings_screen_test` was updated to match.
7. **Icons restored where tests name them.** `arrow_back_ios`, `refresh` and
   `error_outline` are asserted by existing tests and were kept rather than
   changing the tests for taste.
8. **No new dependencies and no audio assets.** Sound stays the platform
   click.
9. **No bottom navigation bar and no new entry points**, per the owner's
   one-path-per-destination rule.
10. **Side-menu "coming soon" rows kept.** Removing them would remove
    visible items; wiring them needs store URLs and accounts. Only their
    icons and colours were unified.

## Changed files

New:
`lib/core/theme/app_motion.dart`,
`lib/core/widgets/pressable.dart`, `sakina_card.dart`, `section_header.dart`,
`sakina_segmented.dart`, `status_view.dart`,
`SAKINA_UI_UX_AUDIT.md`, `SAKINA_DESIGN_SYSTEM.md`,
`SAKINA_UI_UX_DEVELOPMENT_PLAN.md`.

Modified (core):
`lib/core/theme/app_design.dart`, `app_theme.dart`, `app_typography.dart`,
`app_radius.dart`, `app_spacing.dart`, `app_shadows.dart`,
`noise_background.dart`; `lib/core/feedback/feedback_service.dart`;
`lib/core/app/app_root.dart`; `lib/core/router/fade_slide_route.dart`;
`lib/core/widgets/animated_entrance.dart`.

Modified (features):
`onboarding/presentation/screens/home_screen.dart`,
`home/home_drawer_lists.dart`, `home/home_prayer_time_header.dart`,
`home/home_wird_sheet.dart`;
`onboarding/presentation/widgets/category_grid_widget.dart`,
`current_wird_widget.dart`, `daily_verse_section_widget.dart`,
`date_card_widget.dart`, `prayer_time_header.dart`,
`prayer_times_widget.dart`, `tab_switcher_widget.dart`;
`duas/presentation/screens/azkar_screen.dart`;
`quran/presentation/screens/quran_screen.dart`, `tasbeeh_screen.dart`,
`surah_details_screen.dart`, `surah_reader/surah_reader_buttons.dart`;
`settings/presentation/screens/settings_screen.dart`,
`settings/presentation/widgets/settings_controls.dart`;
`splash/presentation/screens/splash_screen.dart`;
`qibla/presentation/screens/qibla_screen.dart`;
`khatma/presentation/screens/khatma_duration_screen.dart`,
`media/presentation/widgets/article_card.dart`, `video_card.dart`
(text alignment only).

Modified (tests):
`test/core/theme/app_design_test.dart` (two palettes and four pairs added),
`test/features/settings/presentation/screens/settings_screen_test.dart`
(dialog surface expectation),
`test/features/settings/presentation/screens/goldens/windows/settings_light.png`,
`settings_dark.png` (regenerated).

## Validation log

| When | Command | Result |
|---|---|---|
| Before changes | `flutter analyze` | No issues |
| Before changes | `flutter test` | 663 passed |
| After theme only | `flutter test` | 660 passed, 3 failed: 2 goldens (expected), 1 dialog-surface expectation (decision 6) |
| After home | large-text audit | Home overflowed at 200% text; header title height tightened; passes |
| After screens | `flutter test` | 656 passed, 9 failed: 2 goldens, 7 tied to icons/app-bar details; code adjusted (decision 7) |
| Final | `flutter analyze` | No issues |
| Final | `flutter test` | 665 passed |
| Final | `dart format --set-exit-if-changed lib test` | Clean |
| Final | `flutter build apk --debug`, installed on emulator-5554 | Launches; onboarding, home (light and dark) and side menu render; no `FATAL` or `E/flutter` lines in logcat |

## Open issues

- Haptics and the click sound are verified by unit test only, not felt on a
  physical phone.
- The qibla dial, after-adhan screen, articles and videos were not seen on
  device.
- The settings golden baselines were regenerated on this machine and should
  be confirmed on the Windows CI job that owns them.
- `assets/hadeath/ahadeth.txt` has a space inside the word in the first
  eight titles ("الحد يث"), visible in the hadith list. It predates this
  work and is source content, so it was left for the owner to review.
- `lib/features/onboarding/presentation/widgets/prayer_time_header.dart` is
  no longer referenced by any screen.
- The side-menu rows for contact, social links, share and rate still only
  show "coming soon"; they need store URLs and accounts.
- On the emulators used for checking, the Sakina debug install has
  onboarding marked complete.

## Notifications (follow-up phase)

Audit and plan: `SAKINA_NOTIFICATION_AUDIT.md`,
`SAKINA_NOTIFICATION_IMPLEMENTATION_PLAN.md`. One shared notification style
(brand colour, app large icon, header detail, expandable text, buttons per
category, iOS categories and thread ids) with every existing channel kept.
Prayer alerts show the prayer time; the "prayer is near" reminder says when
the prayer is and clears itself. New opt-in daily verse (settings → التنبيهات),
which quotes the whole ayah from the Quran asset and opens the reader at
it. Checked on emulator-5554; iOS not checked on a device.
