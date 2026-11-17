# Sakina – UI/UX Audit

Audit date: 2026-11-17. Finding IDs: [COMPREHENSIVE_AUDIT_REPORT.md](COMPREHENSIVE_AUDIT_REPORT.md) §4.12.

## 1. Limitation (read first)

**No screen was visually inspected on a device or emulator during this audit.** The assessment below is based on source code, theme definitions, the existing automated UI tests (goldens, large-text audit, page-fit tests) and the project's own earlier design documents (`SAKINA_UI_UX_AUDIT.md`, `SAKINA_DESIGN_SYSTEM.md`, `SAKINA_QURAN_READER_AUDIT.md`, screenshots in `docs/reader-screenshots/` and `docs/notification-screenshots/` produced before this audit). Statements about appearance are therefore *Potential* unless they cite code. Task P3-04 schedules the missing visual review.

## 2. Design system and theming

- Tokens: `lib/core/theme/` (`app_colors`, `app_design`, `app_spacing`, `app_radius`, `app_shadows`, `app_motion`, `app_typography`); `AppTheme.light/dark(design)` (`app_theme.dart`, 574 lines). Multiple designs (`AppDesign`, incl. dark-only designs that override the mode, `theme_provider.dart:22-25`).
- Persistence: `theme_mode` and `app_design` in prefs; read synchronously before the first frame (prefs are loaded in DI), so no theme flash after splash.
- Fonts: Cairo (UI), Amiri, AmiriQuran (Quran) bundled with OFL licences.
- Hard-coded colours outside tokens: only 3 in features — `splash_screen.dart:85-86` (UX-02) and a black fallback in `quran_page_layout.dart:254` used only when the style has no colour.
- Status bar: `SystemUiOverlayStyle` set in `app_theme.dart:173` and forced `light` on hero app bars (`sakina_hero_app_bar.dart:54`, `home_screen.dart:146`) — verify contrast on light designs (P3-04).

## 3. Light / dark mode

- Both themes are generated from the same design object, so components share structure.
- `test/accessibility/large_text_audit_test.dart` renders screens in several design/brightness variants (e.g. "recitation (sage dark)") without overflow.
- Not verified: contrast ratios of every text/background pair, illustration legibility (category images are PNGs with fixed colours), system navigation bar colour per design. → P3-04.

## 4. Arabic and RTL

- Locale fixed to `ar` (`app_root.dart:353`); all directionality from `MaterialApp` → RTL throughout.
- Generated localizations in `lib/l10n/` (`app_ar.arb`). A localization test exists (`test/l10n`).
- Digit style (Arabic-Indic / Western) is a user setting applied in UI and notifications (`DigitStyleScope`, `applyDigitStyle`).
- Display strings are also used as identifiers (ARCH-02) — a localization edit can break scheduling.
- Some Arabic literals remain in UI code (UX-03); most literals outside ARB are religious content (CONT-01).

## 5. Navigation experience

User-flow map (from `app_router.dart` and `home_drawer_lists.dart`):

```
/splash ─► /onboarding (first run) ─► /home
/home ─┬─ category grid ─► /quran ─► /quran/surah/:n   (/quran/search)
       │                ─► /prayers (location dialog, adhan settings)
       │                ─► /duas ─► /azkar/details      (/duas/all)
       │                ─► /hadeath ─► /hadeath/details/:i
       │                ─► /tasbeeh  /asma  /qibla  /guide  /recitation ─► /recitation/downloads
       │                ─► /media ─► /media/articles  /media/videos   (/media/audio → /recitation)
       ├─ wird card ─► /khatma ─► /khatma/location ─► /khatma/duration ─► reader with range
       └─ drawer ─► /settings ─► /settings/data-sources   (debug: /settings/notification-test)
Notification tap ─► go('/home') + push(/duas/morning|evening | /quran/surah/n | /prayers | /after-adhan | /khatma)
In-app prayer banner ─► /after-adhan
```

- Back behaviour: every notification target is pushed above `/home`, so system back returns home (good). `MainNavigationShell` is a pass-through, so there is no persistent bottom bar; navigation is hub-and-spoke from Home.
- Settings has a single entry point (drawer), which is a deliberate product decision.
- Dead ends: unknown routes show GoRouter's default page (ARCH-05). No route restoration after process death (the app restarts at splash) — acceptable for this app.

## 6. Screen-by-screen notes (code-based)

| Screen | Notes |
|---|---|
| Splash | Fixed brown/gold palette regardless of design (UX-02); waits only for prefs. |
| Onboarding | Paged; notification permission explained before request. |
| Home | Hero header with prayer countdown, wird card, daily verse, category grid with PNG illustrations (non-ASCII asset names; fine on Android/iOS). |
| Quran reader | Scroll and page modes, `quran_page_fit_test` guarantees ≥12 px on 360×640; full asset decode on open may delay first paint (PERF-01). |
| Quran search | Arabic normalisation; result list. |
| Prayer times | Location dialog (bundled cities, GPS, manual), method/madhab settings, adhan preferences with exact-alarm and battery guidance and a "test alert". Location dialog has 0 % test coverage. |
| Azkar / details | Counters with progress persistence. |
| Qibla | Compass dial with calibration hint; error states for missing sensor/permission. |
| Recitation | Mini player + sheet; downloads screen. |
| Media | Articles/videos with offline/error/empty states (`media_state_views.dart`); "missing key" state for videos. |
| Settings | Appearance, reading, digits, text size, reminders, crash-report consent, about/licences. Golden-tested. |

## 7. Feedback, states, motion

- Shared widgets for states: `status_view.dart`, `empty_state.dart`, `pulse_loader.dart`, `media_state_views.dart`.
- Haptics/sounds via `FeedbackService`; interface sounds suppressed while recitation plays (`SacredAudioGate`, `app_root.dart:301-309`). Documented in `docs/FEEDBACK_AND_MOTION.md`.
- Motion tokens in `app_motion.dart`; verify reduced-motion handling on device (P3-01).

## 8. Accessibility

- Code signals: 52 `Semantics` widgets, 21 semantic labels, 37 tooltips; most taps use `InkWell`/buttons (only 2 `GestureDetector`).
- Automated: `test/accessibility/*` (large-text audit across screens and designs), `test/core/accessibility/*` (text scale, digit style).
- `AppTextScale` applies a user factor; verify it composes with the system text scale rather than replacing it (P3-01).
- Outstanding: TalkBack/VoiceOver walkthrough, contrast measurement, focus order in the reader, touch-target audit (UX-01).

## 9. Recommendations

1. Run a visual review of every route in light, dark and each design at 360×640 and a tablet size; record screenshots in `docs/audit/screens/` (P3-04).
2. Screen-reader walkthrough of the 10 core flows; fix missing labels and traversal order (P3-01).
3. Derive splash colours from the active design (P3-02).
4. Move remaining UI literals into ARB (P3-03); replace display-string identifiers (P1-03).
5. Add a localized router error page (P1-06).
