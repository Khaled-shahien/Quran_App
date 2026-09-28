# Sakina Quran App - Deep Product, UX/UI, QA & Development Audit

> Implementation follow-up (2026-09-22): see [implemented fixes, validation and remaining requirements](docs/AUDIT_IMPLEMENTATION.md). Findings below describe the original audit baseline; they are not all current defects after the follow-up changes.

**Audit date:** 2026-09-22  
**Repository:** `e:\Projects\01-personal\Quran-App`  
**Audit status:** Static repository audit plus automated test execution, with the first implementation slice applied.  
**Important:** This document never treats the presence of code as proof that a feature works on a device.

## Evidence Classification

- **Verified in Code:** Behavior or configuration is explicit in repository files.
- **Verified at Runtime:** Confirmed by running the application on a real or emulated device. No device session was available for this audit.
- **Partially Verified:** Supported by code/tests, but an important boundary remains untested.
- **Requires Runtime Verification:** Cannot be established from code alone.
- **UX/UI Observation:** A visible or interaction-related observation supported by screen code, test fixtures, or existing product evidence.
- **Product Recommendation:** Proposed future behavior, not a confirmed defect.
- **Religious/Content Verification Required:** Requires a qualified content owner or scholar.
- **Security Verification Required:** Requires threat-model and security testing evidence.

## 1. Executive Summary

Sakina is an Arabic-first Flutter application for Quran reading, prayer times, Qibla, duas and adhkar, hadith, tasbeeh, Khatma tracking, Asma al-Husna, media, favorites/bookmarks, themes, and reminders. Its strongest foundations are bundled Quran/devotional content, a layered Provider/GetIt architecture, GoRouter route handling, explicit Qibla permission states, local notification abstractions, and broad unit/widget coverage.

The application is not production-ready. The primary blockers are: prayer times use unexplained fixed Cairo coordinates; provider and repository calculation defaults differ; Android release signing still uses debug signing; application/Firebase identities are not aligned across platforms; iOS Firebase setup is a placeholder; notification sound assets are incomplete; FCM backend token registration is a placeholder; the home search is visibly unfinished; a notification can route to an absent `/khatma` route; and runtime delivery, device permissions, accessibility, performance, and cross-platform behavior are not verified. The keyed prayer cache write-through path and flaky prayer integration assertion were fixed in this implementation slice.

The test suite provides useful component confidence but not product confidence. The latest test run completed **207 passing tests and 1 failing integration test**. The failure is the prayer flow expecting a `CircularProgressIndicator` while the production screen renders `PulseLoader`. No physical-device runtime verification was performed.

### Release position

**Release readiness: FAIL / BLOCKED.** Do not publish a production build until P0 release identity, prayer correctness, notification behavior, and platform configuration are resolved and verified on real devices.

## 2. Audit Scope

Inspected: `lib/`, `test/`, `integration_test/`, `pubspec.yaml`, assets, Android Gradle and manifest files, iOS Runner configuration, Firebase configuration, environment examples, GitHub Actions, routing, providers, repositories, services, data models, storage, error states, and existing audit reports.

The audit covers product behavior, architecture, feature inventory, routes, screen implementation, UX/UI risks, Arabic/RTL, Quran and religious-content presentation, prayer calculations, Qibla, notifications, permissions, offline behavior, accessibility, performance risks, security/privacy readiness, testing, release configuration, backlog, acceptance criteria, QA cases, and a production checklist.

## 3. Audit Limitations

- **Runtime Verification Unavailable:** The application was not launched on an Android emulator, Android device, iOS simulator, or iOS device during this audit.
- No visual screenshot review, screen-reader session, accessibility tree, frame-timing trace, memory profile, battery profile, network capture, notification delivery test, reboot test, or store artifact validation was available.
- Passing unit/widget tests prove only the exercised test scenarios. They do not prove API availability, platform permission behavior, notification delivery, sensor accuracy, or release readiness.
- Religious correctness, source authenticity, translations, Asma al-Husna meanings, hadith metadata, and prayer calculation policy were not independently validated. They are marked **Religious/Content Verification Required**.
- Security findings are configuration/readiness findings, not penetration-test results.

## 4. Evidence Methodology

For each conclusion, the report records the strongest available evidence type. Repository implementation is separated from actual runtime behavior. Findings are consolidated under one issue ID to avoid repeating the same defect in every section. Priority follows P0/P1/P2/P3:

- **P0:** Release blocker or severe core correctness, security, or data risk.
- **P1:** High-impact functionality, trust, accessibility, or reliability problem.
- **P2:** Meaningful friction or incomplete capability that does not block core use.
- **P3:** Polish or future enhancement.

## 5. Application Overview

### Product purpose

A daily Islamic worship companion combining offline reading content with network-powered prayer/media utilities and local/background reminders.

### Evidence-supported user groups

1. Arabic-speaking Quran readers.
2. Users checking daily prayer times and Qibla.
3. Users reading duas, adhkar, hadith, and Asma al-Husna.
4. Users tracking a Quran Khatma.
5. Users consuming articles, audio, and video.

### Main value proposition

Fast access to daily worship content and utilities in one Arabic-first app, with local content available without a network connection. The value is currently weakened by untrusted prayer inputs, incomplete reminder verification, unfinished search, and missing content provenance.

## 6. Architecture Audit

### Current architecture

- Flutter application with feature-oriented folders under `lib/features`.
- Provider/ChangeNotifier for state management.
- GetIt service locator and constructor injection for many repositories/services.
- GoRouter for route-based navigation and notification navigation.
- Local JSON assets for Quran, duas, prayer data, and hadith.
- SharedPreferences for theme, bookmarks/favorites, Khatma, cached media, alarms, and notification state.
- HTTP-based remote services for Aladhan prayer times, RSS articles, MP3Quran audio, and YouTube.
- Firebase Core/Messaging, `flutter_local_notifications`, timezone, WorkManager, Geolocator, and native compass channels.

### Architecture strengths

**Verified in Code:** Feature layering, repository interfaces, injectable prayer notification scheduler, route loaders for direct Quran/hadith routes, and test fakes improve maintainability.

### Architecture risks

| Issue | Evidence type | Risk |
|---|---|---|
| Initialization blocks before `runApp`; Firebase, DI, notifications, messaging, and WorkManager are awaited first. | Verified in Code | Slow first frame and difficult startup failure recovery. Runtime impact requires measurement. |
| SharedPreferences is used for multiple structured domains. | Verified in Code | Schema migration, corruption recovery, and queryability become harder as history/settings grow. |
| Prayer location abstraction currently resolves to fixed coordinates. | Verified in Code | Domain abstraction exists but does not provide real user location. |
| User-facing localization is distributed in Dart; no ARB resources were found. | Verified in Code | Inconsistent translation and difficult locale expansion. |
| Feature naming is inconsistent (`hadeath`, `duas`, `azkar`) and routes expose this inconsistency. | UX/UI Observation | Discoverability and maintainability friction. |

## 7. Complete Feature Inventory

| ID | Feature | Location | Status in Code | Runtime Status | UX Status | Priority |
|---|---|---|---|---|---|---|
| F-001 | Splash | `features/splash` | Implemented | Requires Runtime Verification | Needs startup validation | P1 |
| F-002 | Onboarding | `features/onboarding` | Implemented | Partially Verified by widget tests | Usable flow; permission timing needs review | P1 |
| F-003 | Home hub | `home_screen.dart` | Implemented | Partially Verified by widget tests | Dense hub; unfinished search and placeholder URL | P1 |
| F-004 | Quran browsing | `features/quran` | Implemented with bundled data | Partially Verified by tests | Core flow present | P1 |
| F-005 | Surah reader | `surah_details_screen.dart` | Implemented | Partially Verified by tests | Reading/accessibility/device validation needed | P1 |
| F-006 | Quran search | Quran repositories/home entry | Contract/partial UI only | Requires Runtime Verification | Home labels search as under development | P1 |
| F-007 | Last-read position | Surah/Khatma state | Partially implemented | Requires Runtime Verification | Must distinguish last read from bookmark | P2 |
| F-008 | Quran bookmarks | `bookmark_provider.dart` | Implemented | Partially Verified by unit tests | Persistence tested; return flow needs device validation | P2 |
| F-009 | Favorite verses | `favorites_provider.dart` | Implemented | Partially Verified by unit tests | Feedback and discovery need review | P2 |
| F-010 | Prayer times | `features/prayers` | Implemented with fixed location | Requires Runtime Verification | P0 trust/correctness risks | P0 |
| F-011 | Prayer notifications | scheduler/notification service | Implemented in Code | Requires Runtime Verification | Missing sound/reboot proof | P0 |
| F-012 | Adhan | notification channel | Channel references sound | Requires Runtime Verification | `adhan.mp3` missing | P1 |
| F-013 | Qibla | `features/qibla` + native channels | Implemented | Requires Device Verification | Permission states are strong; compass accuracy unknown | P1 |
| F-014 | Duas | `features/duas` | Implemented with assets | Partially Verified by tests | Source/provenance not visible | P1 |
| F-015 | Adhkar | `features/duas` | Implemented with assets | Partially Verified by tests | Source/provenance and repeat feedback need review | P1 |
| F-016 | Hadith | `features/hadeath` | Implemented with local asset | Partially Verified by tests | Source/narrator metadata not established | P1 |
| F-017 | Tasbeeh | `tasbeeh_screen.dart` | Implemented | Partially Verified by widget test | Persistence/reset/accessibility need device checks | P2 |
| F-018 | Khatma | `features/khatma` | Implemented partially | Partially Verified by tests | Notification deep-link destination is incomplete | P1 |
| F-019 | Asma al-Husna | `asma_al_husna_screen.dart` | Implemented | Requires Content Verification | English meanings require review | P2 |
| F-020 | Articles | media RSS | Implemented | Requires Runtime Verification | External feed/cache/failure states need validation | P2 |
| F-021 | Audio | MP3Quran data source | Implemented | Requires Runtime Verification | Playback lifecycle and offline behavior need validation | P2 |
| F-022 | Video | YouTube data source | Implemented conditionally | Requires Runtime Verification | API key and external channel fallback | P2 |
| F-023 | Notifications | FCM/local/WorkManager | Implemented in Code | Requires Device Verification | Delivery and tap behavior unproven | P0 |
| F-024 | Settings | providers/diagnostics | Partial | Requires Runtime Verification | No complete user-facing settings architecture evident | P1 |
| F-025 | Theme | `ThemeProvider`/`AppTheme` | Implemented | Partially Verified by tests | Contrast and dynamic type need device review | P2 |
| F-026 | Language | global Arabic locale | Arabic configured; no ARB | Requires Runtime Verification | Language switching is not established | P1 |
| F-027 | Sharing/copying | share/url/selectable text | Implemented in parts | Requires Runtime Verification | Action feedback and platform behavior need tests | P2 |
| F-028 | Offline content | local assets/cache | Partial | Requires Runtime Verification | Bundled content likely available; remote fallback incomplete | P1 |
| F-029 | User preferences | SharedPreferences | Implemented | Partially Verified by unit tests | Migration/deletion inventory needed | P2 |

## 8. Runtime Verification

**Status: Runtime Verification Unavailable.** No claims below are runtime-confirmed.

Required device matrix:

- Android 12, 13, and 14 on at least one physical device.
- iPhone with location and compass sensor; iOS simulator is insufficient for Qibla.
- Fresh install, upgrade, denied permissions, revoked permissions, offline first launch, foreground, background, terminated app, reboot, timezone change, date rollover, and app update.
- Arabic large text, TalkBack/VoiceOver, light/dark theme, portrait/landscape where supported.

The existing tests prove component scenarios but do not prove the matrix above.

## 9. Information Architecture

### Current IA

A Home-centered hub routes to individual tools and detail pages. GoRouter declares 23 route patterns including splash, onboarding, home, Quran, prayers, Qibla, duas/adhkar, hadith, tasbeeh, Asma, media, notification diagnostics, and Khatma setup.

### IA problems

- Home carries many destinations as a single hub, increasing scanning cost.
- Search is surfaced but visibly marked as under development.
- Settings are fragmented across theme, notification diagnostics, and provider state.
- Notification routing generates `/khatma`, but no matching route is defined; fallback goes to Home.
- Naming is inconsistent between Arabic product language and internal/route names.

### Recommended IA

1. **Home:** next prayer, daily content, current Khatma action, and recent reading.
2. **Read:** Quran, search, bookmarks, last read.
3. **Worship:** prayer times, Qibla, duas, adhkar, tasbeeh, Khatma.
4. **Learn:** hadith, Asma al-Husna, articles, audio, video.
5. **Settings:** appearance, language, prayer, notifications, privacy, sources, diagnostics.

This is a **Product Recommendation**, not a required redesign. Validate navigation frequency before implementation.

## 10. Navigation Audit

**Verified in Code:** Direct routes exist for Quran/surah and hadith details, with invalid data screens and loader fallbacks. Notification routing has feature-specific handlers.

**Partially Verified:** Back behavior, cold-start deep links, malformed payloads, and external-return behavior are not device-tested.

**AUD-009 - Khatma notification route has no destination** is a P1 navigation issue. Add a canonical `/khatma` route or route directly to an existing progress screen, then test foreground/background/terminated taps.

## 11. User Flow Audit

### Journey 1: First Launch -> Quran

**Current:** startup initialization -> splash -> onboarding -> optional notification permission -> home -> Quran -> surah.  
**Friction:** startup work and fixed delay precede value; notification permission may be encountered before the user has used a reminder.  
**Failure points:** initialization failure, permission denial, invalid route, asset loading.  
**Recommended:** render shell early -> optional onboarding -> Home/Quran immediately -> contextual reminder permission later.

### Journey 2: First Launch -> Prayer Times

**Current:** onboarding -> Home -> prayer widget/screen -> fixed Cairo coordinates -> API fetch.  
**Friction:** location is not chosen or disclosed; method defaults differ.  
**Failure points:** network, API, wrong city, date/timezone, stale/no cache.  
**Recommended:** explain location -> device permission or manual city -> method/madhab policy -> show provenance/freshness -> schedule reminders.

### Journey 3: Search -> Quran -> Ayah

**Current:** search entry exists but Home says search is under development; full Quran search is not established.  
**Friction:** user cannot rely on a complete find flow.  
**Recommended:** one search entry -> normalized Arabic query -> grouped results -> highlighted ayah -> open reader -> bookmark/copy/share.

### Journey 4: Prayer -> Notification

**Current:** provider schedules after a successful load.  
**Friction:** audio asset, permission, reboot recovery, exact alarm, and actual delivery are not proven.  
**Recommended:** configure category -> preview next scheduled time -> persist schedule -> verify after reboot/date rollover.

### Journey 5: Qibla

**Current:** location/sensor state machine -> native heading stream -> compass guidance.  
**Friction:** real sensor accuracy and calibration are unknown.  
**Recommended:** permission rationale -> calibration guidance -> compass -> accessible textual direction fallback.

### Journey 6: Dua/Adhkar

**Current:** local category -> detail -> read/repeat.  
**Friction:** source, progress, repeat state, and completion feedback need validation.  
**Recommended:** category -> item -> count/progress -> completion feedback -> optional reminder.

### Journey 7: Khatma

**Current:** location/duration setup -> persisted model -> current wird/reminder.  
**Friction:** notification destination and missed-day/edit behavior are incomplete.  
**Recommended:** create plan -> preview target -> save -> daily action -> edit/pause/reset -> reminder destination.

### Journey 8: Offline

**Current:** bundled content can be read locally; remote services have selected caches.  
**Friction:** prayer successful responses are not written to the defined cache; stale state is not a complete UX.  
**Recommended:** cached timestamp -> stale banner -> offline read -> retry when online.

### Journey 9: Bookmark -> Return Later

**Current:** bookmark/favorite persistence exists in SharedPreferences.  
**Friction:** complete discovery and last-read separation need validation.  
**Recommended:** save confirmation -> Read/Bookmarks list -> open exact location -> remove/undo.

## 12. Screen-by-Screen Audit

| Screen / route | Purpose and entry | Current implementation | Runtime | Main issues / states | Recommended flow |
|---|---|---|---|---|---|
| Splash `/splash` | App start | Fixed startup route and initialization gate | Requires Runtime Verification | Startup timing and failure recovery | Render shell early, then resolve startup state |
| Onboarding `/onboarding` | Explain product and finish setup | PageView, skip, progress semantics, notification dialog | Partially Verified by widget tests | Prayer setup absent; permission timing needs validation | Intro -> optional setup -> first value |
| Home `/home` | Main hub | Feature cards, favorites, search entry, external links | Partially Verified by widget tests | Search under development; placeholder donate URL; density | Prioritize next prayer/current Khatma/recent reading |
| Quran `/quran` | Browse Quran | Local surah data and search contract | Partially Verified by tests | Full search/filters/last-read UX incomplete | Browse/search -> surah -> resume/bookmark |
| Surah `/quran/surah/:number` | Read ayat | Loader/invalid route/selectable content/bookmark integration | Partially Verified by tests | Font, diacritics, scaling, rotation, copy/share need device checks | Read -> actions -> persist exact position |
| Prayer `/prayers` | Daily times | API provider, loading/error/empty, countdown | Requires Runtime Verification | Fixed location, cache, method mismatch, English labels | Show city/date/method/timezone/freshness and controls |
| Qibla `/qibla` | Compass | Geolocation plus native Android/iOS channel | Requires Device Verification | Sensor accuracy, calibration, true heading | Permission -> calibration -> compass + text fallback |
| Duas `/duas` | Dua categories | Local repository/provider | Partially Verified by tests | Source metadata and empty/error UX | Category -> item -> read/repeat/share |
| Adhkar `/azkar/details` | Adhkar detail | Category route and local data | Partially Verified by tests | Count/completion/source need validation | Detail -> progress -> completion |
| Hadith `/hadeath` and details | Read hadith | Local repository and route loader | Partially Verified by tests | Source/narrator/edition not established | List -> detail -> source/share |
| Tasbeeh `/tasbeeh` | Counter | Gesture/counter screen | Partially Verified by widget test | Reset persistence and accessible alternative | Counter -> feedback -> saved/reset |
| Khatma setup | Plan Quran completion | Location/duration routes and provider | Partially Verified by tests | Missing canonical notification destination | Create -> preview -> track -> edit |
| Asma `/asma` | Browse names | Local screen content | Requires Content Verification | Meaning/source verification required | Browse -> source metadata |
| Media `/media*` | Articles/audio/video | Remote sources/cache/providers | Requires Runtime Verification | API key, partial feeds, external links, offline states | Load -> cached/error -> open/play |
| Notification diagnostics | QA/operations | Permission, token, pending/schedule actions | Partially Verified by widget tests | Must remain diagnostic; device behavior unproven | Diagnostics -> safe action -> explicit result |
| Settings | Preferences | Theme/settings providers and diagnostics route | Requires Runtime Verification | No unified settings IA evident | Group preferences and explain dependencies |

## 13. UX Audit

The central UX issue is trust: prayer results and reminders are time-sensitive, but the user is not shown the location, calculation method, timezone, freshness, or scheduling status that produced them. The second issue is uneven recovery: local content has a stronger offline foundation than remote prayer/media paths.

Every important issue is documented below with an ID, root cause, solution, acceptance criteria, and QA cases. General statements such as “UX needs improvement” are intentionally avoided.

## 14. UI Audit

### Existing evidence

Material 3, AppColors/AppTypography, Cairo font usage, light/dark themes, global RTL, shared loaders, and several Semantics wrappers are present.

### Confirmed UI/content observations

- English prayer states appear inside an Arabic-first product: `Error loading prayer times`, `Retry`, `Today's Prayer Times`, and `No data available`.
- Prayer date is manually formatted as `day/month/year` rather than through a locale-aware formatter.
- Home search is visibly labeled as under development.
- Placeholder/example external donation URL exists.

### Requires visual/runtime verification

Contrast, clipping, long Arabic text, diacritics, dynamic type, touch targets, landscape, icon direction, card consistency, shadows, and screen-reader reading order require screenshots/device inspection. They are not claimed as defects without that evidence.

## 15. Design System Audit

### Existing design tokens

- App colors and light/dark color schemes.
- Cairo typography styles.
- Material 3 theme.
- Button, card, dialog, input, navigation-bar, bottom-sheet, and scrollbar themes.
- Shared pulse loader and feature state views.

### Missing or insufficiently centralized tokens

- Explicit spacing scale and Arabic line-height policy.
- Shared stale/offline state component.
- Shared semantic success/warning/info states.
- Minimum touch-target and focus-ring policy.
- Consistent localized string resource system.
- Shared content provenance/source presentation.

### Recommended design system

Create a documented token layer for color semantics, spacing, typography, radius, elevation, touch targets, motion, and Arabic text. Standardize `LoadingView`, `ErrorView`, `EmptyView`, `PermissionView`, `StaleDataBanner`, `SourceMetadata`, and `ActionFeedback` components.

## 16. Arabic & RTL Audit

**Verified in Code:** Arabic locale and global RTL directionality are configured; Cairo is used; Qibla permission copy is Arabic; onboarding includes RTL interaction tests.

**UX/UI Observation:** English fallback text, manual date formatting, mixed-language media, and likely API-derived numerals create bidi/localization risk.

### Required checks

- Arabic font fallback, diacritics, Quran line height, selectable text, and no truncation.
- Arabic/English mixed strings use bidi isolation.
- Dates, times, numerals, and Hijri dates use an explicit locale policy.
- Back/forward arrows and progress/swipe directions match RTL.
- Search normalizes diacritics and Arabic variants according to a documented policy.
- Notifications use reviewed Arabic titles and bodies.
- Large text and TalkBack/VoiceOver reading order are tested on devices.

### English string classification

| String/surface | Classification | Evidence type |
|---|---|---|
| Prayer `Error loading prayer times` | Important | UX/UI Observation from screen code |
| Prayer `Retry` | Important | UX/UI Observation from screen code |
| Prayer `Today's Prayer Times` | Important | UX/UI Observation from screen code |
| Prayer `No data available` | Important | UX/UI Observation from screen code |
| English model translations/metadata | Minor or intentional until product policy is set | Requires Product/Content Verification |
| Media/external provider titles | Requires locale policy | Requires Runtime and Content Verification |

## 17. Quran Experience Audit

**Verified in Code:** Quran metadata and ayahs load from bundled `assets/quran_master.json`; surah routes support direct loading; bookmarks and selectable text are present; tests cover local loading, properties, Arabic search by surah name, and screen rendering.

**Partially Verified:** Reading position, bookmark persistence, widget behavior, and route loaders have test evidence but no device session.

**Not established:** Juz browsing, audio recitation, translation, tafsir, tajweed visualization, Quran-wide ayah search, result highlighting, and reading history as complete product features. Do not list them as implemented.

### Quran risks and requirements

- **Religious/Content Verification Required:** Source, edition, verse integrity, metadata, translation, and any future tafsir.
- Quran text must not be changed during UI refactoring without source comparison and content-owner approval.
- Verify long ayat, diacritics, selection, copy, share, font scaling, scroll position, rotation, dark theme, and screen-reader output.
- Clarify the distinction between bookmark, favorite verse, and last-read location.

## 18. Prayer Times Audit

### Location

**Verified in Code:** `FixedPrayerLocationService` defaults to Cairo coordinates. Home also directly uses Cairo coordinates. No user location flow for prayer times is established. Qibla has a separate Geolocator flow and must not be treated as proof that prayer uses GPS.

**UX/UI Observation:** Prayer screen comments describe Makkah as an example, contradicting the provider’s Cairo implementation. Location provenance is not visible.

### Calculation

**Verified in Code:** Provider default method is `5`; repository default is `3`.  
**Religious/Content Verification Required:** Select and approve calculation method, madhab/Asr method, high-latitude rule, rounding, and display policy with the product/content owner.

### Timezone/date

**Requires Runtime Verification:** DST, device timezone, API timezone, local midnight refresh, date rollover, and travel behavior.

### Cache/offline

**Verified in Code:** Prayer responses are now cached by date, rounded coordinates, and calculation method, with timestamp expiry and cache cleanup. The repository reads a valid entry before the API and writes successful responses after mapping. Stale fallback and timezone/madhab-aware product behavior remain future work.  
**Recommendation:** extend the cache key and UI metadata with madhab/timezone when those settings are introduced; show stale timestamp; retain last valid data on network failure.

### UI requirements

Display city/coordinates or selected place, local date, selected calculation method, timezone, last update, cached/stale status, next prayer, and notification status.

### Notifications

Fajr, Sunrise, Dhuhr, Asr, Maghrib, and Isha IDs/channels exist in code. Exact timing, sound, cancellation, date changes, reboot, permission denial, Doze, and iOS behavior require device verification.

## 19. Qibla Audit

**Verified in Code:** Qibla includes disabled-location, denied, permanently denied, unsupported sensor, error, calibration, and near-Kaaba states. Android and iOS native heading channels are present.

**Requires Device Verification:** Bearing correctness, magnetic declination, calibration instructions, iOS true heading, landscape, sensor noise, battery, and unsupported hardware.

**Accessibility requirement:** Provide a textual bearing/direction and calibration status; do not make the compass visual the only interaction or output.

## 20. Dua & Adhkar Audit

**Verified in Code:** Local repositories and screens exist, with loading/error/empty tests for relevant flows.

**Religious/Content Verification Required:** Source, collection, wording, count, translation, and update/version metadata. Do not alter sacred text as part of UI cleanup.

**UX requirements:** Category labels, source metadata, repeat/count progress, completion feedback, copy/share, accessible reading order, offline indicator, and optional reminder controls.

## 21. Hadith Audit

**Verified in Code:** Bundled hadith data source, list/detail routes, invalid index handling, loading/error widgets, and tests exist.

**Religious/Content Verification Required:** Book/source, narrator, grading, edition/version, Arabic text, translation, and attribution. A local asset is not proof of authenticity.

**Product requirement:** Show source metadata where available and avoid presenting unverified translations or grading as authoritative.

## 22. Tasbeeh Audit

**Verified in Code:** Tasbeeh screen has widget coverage for swipe interaction.

**Requires Runtime Verification:** Gesture reliability, persistence, reset behavior, haptics, background/foreground state, large text, and accessible button alternative.

**Recommendation:** Add explicit increment control, count announcement, undo/reset confirmation, and persistence policy.

## 23. Khatma Audit

**Verified in Code:** Setup routes, domain model calculations, saved progress, current wird, daily targets, reminders, and tests exist.

**Confirmed issue:** Notification routing emits `/khatma`, but the router does not define a canonical `/khatma` route. The handler falls back to Home.

**UX requirements:** Create/edit/pause/reset plan, missed-day handling, progress explanation, current position, exact destination from reminder, and recovery after corrupted preferences.

## 24. Media Audit

**Verified in Code:** RSS articles, MP3Quran reciters/audio, YouTube video search, six-hour selected caching, timeout/error mapping, and external URL launching exist.

**Partially Verified:** YouTube requires `YOUTUBE_API_KEY` through `--dart-define`; empty keys use channel-link fallback. Network availability, partial-feed behavior, audio playback, cache freshness, and external-link return are untested.

**UX requirements:** Provider/source labels, loading/empty/offline/stale states, safe external link handling, retry, playback lifecycle, and API-key unavailable copy.

## 25. Search Audit

**Verified in Code:** Search contracts and some local surah search behavior exist.  
**UX/UI Observation:** Home explicitly presents search as under development.

### Missing/undefined behavior

Cross-content scope, Quran ayah search, Arabic normalization, diacritic tolerance, typo handling, suggestions, highlighting, history, filters, sorting, offline behavior, and deep-link result routing.

**Priority:** P1. Define product scope before implementation; do not imply a complete search feature in store material.

## 26. Notifications Audit

| Capability | Code status | Runtime status | Finding |
|---|---|---|---|
| FCM initialization | Implemented in Code | Requires Device Verification | Firebase setup and delivery are not proven. |
| Foreground message path | Implemented in Code | Requires Device Verification | Local display call exists; actual display unverified. |
| Background handler | Implemented in Code | Requires Device Verification | OS restrictions and payload behavior unverified. |
| Local channels | Implemented in Code | Requires Device Verification | Android channels defined. |
| Prayer scheduling | Implemented in Code | Requires Device Verification | Called after successful fetch only. |
| Adhan sound | Referenced in Code | Blocked/Requires Device Verification | `adhan.mp3` is absent. |
| Cancellation/rescheduling | Implemented in Code | Requires Device Verification | Date/timezone/reboot matrix absent. |
| Boot recovery | Partially Implemented | Requires Device Verification | Existing persisted reminder recovery does not prove prayer schedule rebuild. |
| Token retrieval/refresh | Implemented in Code | Requires Device Verification | Backend sync is a placeholder. |
| Notification tap routing | Implemented in Code | Requires Device Verification | Khatma destination is incomplete. |
| Permission flow | Implemented in Code | Requires Device Verification | Denial and settings recovery need platform tests. |

## 27. Permissions Audit

| Permission | Purpose | Evidence/status | Required action |
|---|---|---|---|
| Coarse/fine location | Qibla; future prayer location | Verified in Code for declaration/Qibla | Explain context, denial, manual fallback. |
| POST_NOTIFICATIONS | Local/FCM notifications | Verified in Code | Test Android 13+ denial and re-enable. |
| Exact alarms | Prayer/reminder timing | Verified in Code | Confirm policy necessity and denial behavior. |
| Boot completed | Alarm recovery | Verified in Code | Verify reboot/update behavior and battery impact. |
| Foreground service/wake lock | Background behavior | Verified in Code | Security/product review required for necessity. |
| iOS when-in-use location | Qibla | Verified in Code | Test rationale and denied-forever settings path. |
| iOS remote notification/fetch | FCM/background | Verified in Code | Real-device Apple configuration test required. |

## 28. Accessibility Audit

**Partially Verified:** Semantics exist for onboarding actions and Qibla controls; selectable Quran content and reduced-animation handling exist; widget tests cover some labels and RTL.

**Requires Device Verification:** TalkBack, VoiceOver, font scaling, contrast, focus order, keyboard navigation, touch target sizes, live announcements, icon labels, screen-reader Quran reading, notification accessibility, and reduced motion across all screens.

### Accessibility acceptance bar

A user must complete Quran browse/read/bookmark, prayer view/retry, Qibla permission recovery, notification preference, Khatma setup, and Tasbeeh increment without relying on color, gesture-only controls, or visual compass interpretation.

## 29. Performance Audit

### Observed risks, not measured defects

- Startup awaits several services before `runApp`; startup duration is unknown.
- Splash includes a fixed 3.5-second delay; perceived delay is unknown.
- Prayer screen calls `setState` every second for countdown; rebuild cost is unknown.
- Quran and media lists may load large content; frame/memory behavior is unknown.
- WorkManager, exact alarms, wake locks, and notifications may affect battery; no battery profile exists.

### Required measurement

Capture cold/warm startup, first frame, time to first useful content, frame build/raster times, memory, network bytes, release APK/IPA size, battery over 24 hours with reminders, and offline/cache timings. Optimize only after measurement.

## 30. Error Handling Audit

**Verified in Code:** Invalid Quran/hadith route data has explicit messages; Qibla distinguishes important permission/sensor states; prayer has loading/error/empty branches; media providers map errors.

**Issues:** Prayer displays raw provider error text and mixed English/Arabic copy; no complete stale-data fallback; notification errors and deep-link failures need device verification.

**Recommendation:** Map technical failures to localized user-safe messages, preserve diagnostics in logs, provide one recovery action, and label stale data explicitly.

## 31. Offline Audit

| Area | Current evidence | Status |
|---|---|---|
| Quran/duas/hadith assets | Bundled JSON/local repositories | Partially Verified; device asset load required |
| Theme/bookmarks/Khatma | SharedPreferences | Partially Verified by tests |
| Media cache | Six-hour cache service | Requires Runtime Verification |
| Prayer cache | Keyed write-through cache and expiry are implemented; stale fallback/UI metadata remain | Partially Implemented |
| First launch offline | No device test evidence | Requires Runtime Verification |
| Offline recovery | Feature-specific behavior varies | Requires Runtime Verification |

Every remote feature should show offline, stale, retry, and cached timestamp states.

## 32. Security Audit

No penetration test was performed and no security vulnerability is asserted.

### Confirmed configuration/readiness issues

- Android release uses debug signing.
- Application ID is still a sample/development identity.
- FCM token backend registration is a placeholder.
- External/example URLs exist and need allowlisting/review.

### Security Verification Required

Firebase rules/configuration, dependency vulnerabilities, payload validation, deep-link abuse, log redaction, exact-alarm/foreground permissions, release keystore handling, API-key exposure policy, transport security, and notification data privacy.

## 33. Privacy Audit

Location is used for Qibla and may later be used for prayer location; notification permissions and FCM tokens are used; SharedPreferences stores user preferences, bookmarks, Khatma, and alarm state. A complete user-facing data inventory, retention/deletion policy, token deletion policy, and privacy explanation are not evident.

**Recommendation:** Create a privacy inventory covering data, purpose, storage, retention, deletion, third parties, and user controls. Do not send or log FCM tokens without a documented backend/privacy contract.

## 34. Religious Content Verification

| Content area | Current evidence | Required verification |
|---|---|---|
| Quran | Bundled JSON exists | Source, edition, integrity, metadata/version |
| Hadith | Bundled local text exists | Source, narrator, grading, edition, translation |
| Duas/adhkar | Bundled repositories exist | Source, wording, count, attribution |
| Asma al-Husna | Local screen includes meanings | Names, meanings, translation, source |
| Prayer method | API method defaults differ | Scholarly/product approval of method/madhab/rules |
| Notification wording | Arabic notification strings exist | Content review for terminology and appropriateness |
| Audio | Adhan resource requested | Licensing and content approval |

## 35. Cross-Platform Audit

**Verified in Code:** Android declares location, notification, alarm, boot, vibration, foreground, wake, and sensor-related configuration. iOS declares when-in-use location and background notification modes. Native Qibla channels exist for both.

**Configuration risk:** Android Firebase uses `quran-app-10d05`/`com.example.sakina_app`; web/windows use another project identity; iOS contains a placeholder Google service file and a different bundle ID. This requires release alignment before production.

**Requires Runtime Verification:** Notification behavior, Qibla heading, permissions, background execution, timezone, deep links, accessibility, and offline parity on Android/iOS.

## 36. Testing Audit

### Existing test types

- Unit tests: providers, repositories, models, services, persistence, Qibla calculations.
- Widget tests: Quran, prayer, Qibla, duas, hadith, Khatma, onboarding, Tasbeeh, settings/notification diagnostics, home.
- Integration tests: app smoke, Quran flow, duas flow, prayer retry/display flow.
- Golden tests: none found.
- Dedicated accessibility tests: no full device/accessibility suite found.
- API/network tests: parsing and fakes exist; no complete live contract/device matrix.

### Broken test

The previously broken `integration_test/prayer_times_flow_test.dart` expected a `CircularProgressIndicator` and was also timing-sensitive during retry. The test now validates stable error, retry, and success outcomes without asserting a transient loader frame.

### Implementation validation

After the first implementation slice, focused repository/provider/integration validation completed with **12 passing tests and 0 failures**, and `dart analyze` reported no issues for the changed files. The full repository suite has not yet been rerun after these changes.

### Coverage gaps

- Physical notification delivery and tap routing.
- Permission denial/recovery on Android/iOS.
- Location selection and prayer correctness.
- Date rollover/timezone/DST/Doze.
- Khatma notification destination.
- Media network/cache/partial failure.
- Offline first launch and stale cache.
- Release signing/package/Firebase consistency.
- Full Arabic large-text/RTL/screen-reader behavior.
- No golden visual regression suite.

### False-confidence risks

- Unit tests for notification scheduling do not prove OS delivery.
- Widget tests with fake repositories do not prove API/cache behavior.
- Qibla math tests do not prove native sensor heading accuracy.
- Passing local asset tests do not prove source authenticity.
- Integration tests that mount isolated widgets do not boot the production `AppRoot` path.

## 37. Master Issue Tracker

| ID | Category | Screen/feature | Evidence type | Severity | Root cause | Recommendation | Priority |
|---|---|---|---|---|---|---|---|
| AUD-001 | Prayer correctness | Prayer times/Home | Code + UX/UI | P0 | Fixed Cairo location and no user selection | Implement GPS/manual location, provenance, permission/recovery | 1 |
| AUD-002 | Prayer correctness | Provider/repository | Code | P1 | Calculation defaults 5 vs 3 | Centralize approved method/madhab policy | 1 |
| AUD-003 | Reliability | Prayer repository | Implemented in this slice | P1 | Initial cache path lacked write-through and request keys | Extend with stale fallback and visible freshness metadata | 2 |
| AUD-004 | Release | Android build | Configuration | P0 | Debug signing in release | Protected release signing and CI gate | 1 |
| AUD-005 | Release identity | Android/Firebase/iOS | Configuration | P0 | Package/project/bundle identities differ; iOS config placeholder | Align product IDs and platform Firebase files | 1 |
| AUD-006 | Notifications | Prayer channel | Code/assets | P1 | `adhan` referenced but audio asset absent | Add approved asset or safe fallback | 2 |
| AUD-007 | Notifications | FCM | Code/security | P1 | Token backend hook is placeholder | Define token lifecycle/backend/privacy contract | 2 |
| AUD-008 | Notifications | Boot/background | Code + runtime gap | P1 | Prayer schedules not proven to rebuild after reboot/update | Persist and test schedule recovery | 2 |
| AUD-009 | Navigation | Khatma notifications | Code | P1 | `/khatma` destination has no route | Add canonical destination and payload tests | 2 |
| AUD-010 | Search | Home/Quran | UX/UI + code | P1 | Search is explicitly under development | Define scope and ship tested search | 3 |
| AUD-011 | Localization | Prayer/all screens | UX/UI + code | P1 | No ARB; English states remain | Add localization resources and Arabic review | 3 |
| AUD-012 | Accessibility | All screens | Partial code | P1 | Device AT not performed | Add TalkBack/VoiceOver/scaling gates | 3 |
| AUD-013 | Performance | Startup/prayer | Code risk | P1 | Pre-`runApp` work/fixed delay/second timer unmeasured | Profile, then defer/reduce work | 3 |
| AUD-014 | Content trust | Religious content | Content gap | P1 | Source/version metadata not established | Content provenance workflow and review | 3 |
| AUD-015 | External links | Home/media | Code + UX/UI | P1 | Example donation URL | Replace with reviewed link or remove | 1 |
| AUD-016 | Test contract | Prayer integration | Test | P1 | Test expects old loader | Align test and intended state contract | 1 |
| AUD-017 | Privacy | FCM/location/storage | Security/privacy | P1 | Data inventory and deletion policy absent | Document controls and lifecycle | 2 |
| AUD-018 | Cross-platform | iOS/Firebase | Configuration | P0 | Placeholder iOS Firebase config; child issue of AUD-005 | Add real release config and verify on device | 1 |

## 38. Root Cause Analysis

| Root cause | Symptoms | Corrective direction |
|---|---|---|
| Product configuration was left at sample/default values | Cairo location, debug package/signing, placeholder links, differing Firebase identities | Establish release configuration ownership and CI validation. |
| Time-sensitive domain policy was not centralized | Prayer calculation defaults differ; method/location not visible | Create one domain configuration model with approved policy. |
| Feature implementation progressed ahead of runtime validation | Notifications, Qibla, media, background work exist in code but lack device proof | Add device test matrix and release gates. |
| Localization was treated as inline UI text | English states and no ARB files | Introduce localization resources and translation review. |
| Product IA/settings contract is incomplete | Search under development, fragmented settings, Khatma route gap | Define task-based IA and route contract before adding features. |
| Test scope favors isolated components | 207 passing but one integration failure and no real-device proof | Add production AppRoot smoke, contract tests, and device automation. |

## 39. UX Redesign Recommendations

### Prayer

Show place, date, method, timezone, freshness, next prayer, and notification status above the list. Add edit location/method controls and stale/offline banners. Do not silently use an unexplained city.

### Home

Prioritize next prayer, current Khatma action, continue reading, and daily content. Move secondary media and diagnostics out of the primary scan path. Remove the example donation link until reviewed.

### Search

Replace “under development” with either a real search flow or remove the entry point temporarily. Search should return grouped, highlighted, routeable results.

### Settings

Create one task-based settings screen: Appearance, Language, Prayer, Notifications, Reading, Privacy, About/Sources, Diagnostics.

### Qibla

Keep the existing differentiated permission states, add calibration quality, textual bearing, and an accessible non-compass alternative.

## 40. UI Redesign Recommendations

- Define Arabic typography tokens with tested line heights for Quran and prose.
- Replace hard-coded English state labels with localized semantic components.
- Use consistent state illustrations/icons, but do not make color the only status signal.
- Show source metadata in content detail surfaces.
- Add visible cached/stale indicators for remote content.
- Use locale-aware date/time formatting and bidi isolation for mixed content.
- Validate card density, icon direction, touch targets, contrast, and dynamic type through screenshots/device tests before finalizing.

## 41. Technical Recommendations

1. Create `PrayerConfiguration` containing location source, coordinates/place, calculation method, madhab, high-latitude rule, timezone, and freshness.
2. Replace fixed prayer location with permission-backed GPS plus manual fallback.
3. Implement keyed prayer cache read/write/stale fallback.
4. Centralize notification schedule persistence and rebuild after boot/update/date/timezone changes.
5. Align Android application ID, Firebase project/config, iOS bundle/config, and release signing.
6. Add ARB localization and locale-aware formatting.
7. Add canonical Khatma route and notification payload schema validation.
8. Add release CI gates for analyzer, tests, integration tests, signed artifact, package/config consistency, required assets, and dependency/security review.
9. Measure startup/frame/memory/battery before performance optimization.
10. Create content provenance metadata without editing sacred text content in code changes.

## 42. Development Backlog

### TASK-001 - Establish production identity and signing

**Problem:** Debug signing, sample application ID, mismatched Firebase identities, and placeholder iOS Firebase config block release confidence.  
**Solution:** Finalize Android application ID, iOS bundle ID, Firebase projects/files, release keystore, secrets handling, and CI artifact verification.  
**Priority:** P0. **Complexity:** M. **Dependencies:** Product identity, secure credentials.

### TASK-002 - Implement trustworthy prayer configuration

**Problem:** Fixed Cairo coordinates and undisclosed method can produce incorrect user-specific times.  
**Solution:** GPS permission plus manual city/coordinates fallback, centralized method/madhab policy, visible provenance.  
**Priority:** P0. **Complexity:** L. **Dependencies:** Product and religious-content decision.

### TASK-003 - Repair prayer cache and date lifecycle

**Problem:** Successful responses are not written to defined cache; date/timezone rollover is unproven.  
**Solution:** Keyed cache, stale fallback, local-midnight refresh, timezone/date handling.  
**Priority:** P1. **Complexity:** M. **Dependencies:** TASK-002.

### TASK-004 - Make notifications production-ready

**Problem:** Audio, token backend, boot recovery, exact alarms, permissions, and delivery are unverified.  
**Solution:** approved sound/fallback, persisted schedules, FCM lifecycle, category controls, device matrix.  
**Priority:** P1. **Complexity:** L. **Dependencies:** Backend, audio approval, platform testing.

### TASK-005 - Close the Khatma notification route

**Problem:** Notification emits `/khatma`, but no canonical route exists.  
**Solution:** Add route to progress/current wird and validate all payload states.  
**Priority:** P1. **Complexity:** S. **Dependencies:** IA decision.

### TASK-006 - Ship Quran search

**Problem:** Search entry is visibly under development.  
**Solution:** Define scope, Arabic normalization, ranking, highlighting, offline behavior, and routeable results.  
**Priority:** P1. **Complexity:** M. **Dependencies:** Product/content scope.

### TASK-007 - Add localization and RTL quality gate

**Problem:** No ARB resources and English states remain.  
**Solution:** Add ARB, locale-aware formatters, bidi policy, translation review, large-text tests.  
**Priority:** P1. **Complexity:** M. **Dependencies:** Translation policy.

### TASK-008 - Establish religious-content provenance

**Problem:** Sources/editions/version metadata are not established in the product surface.  
**Solution:** Add reviewed source metadata and content release workflow.  
**Priority:** P1. **Complexity:** M. **Dependencies:** Content team/scholars.

### TASK-009 - Build release and device QA gates

**Problem:** Component tests do not establish runtime/platform behavior.  
**Solution:** Add AppRoot smoke, device notification/location/deep-link/accessibility matrix, and release artifact checks.  
**Priority:** P1. **Complexity:** L. **Dependencies:** Test devices and CI.

## 43. Acceptance Criteria

### TASK-001

- Given a release build, when package/config checks run, then Android, iOS, Firebase, and store identifiers match the approved release matrix.
- Given a release artifact, when signing is inspected, then it is not signed with debug keys.
- Given CI, when a release gate fails, then publication is blocked.

### TASK-002

- Given prayer permission is denied, the app offers manual location selection and explains the effect.
- Given a selected place, the screen shows place/date/method/timezone.
- Given location changes, times and scheduled notifications refresh.
- No unexplained silent fallback is allowed.

### TASK-003

- Given a successful fetch, response and timestamp are persisted under a location/date/method key.
- Given offline mode with valid cache, cached times render with timestamp.
- Given expired cache, stale status and retry are visible.
- Given local midnight or timezone change, the date-bound data is refreshed.

### TASK-004

- Given notification permission denial, settings recovery is available.
- Given a scheduled prayer, it remains correct after app restart and approved reboot/update scenarios.
- Given foreground/background/terminated notification taps, the destination is correct.
- Given token refresh, backend registration/deletion follows the documented lifecycle.
- No raw token is written to logs.

### TASK-005

- Given a Khatma notification, the app opens the Khatma progress/current-wird destination in all app states.
- Given malformed payload data, a safe fallback and diagnostic log are produced.

### TASK-006

- Given Arabic input with/without diacritics, agreed normalization returns deterministic results.
- Given no result, the user sees a localized empty state and retry/edit action.
- Given a result, matched text is highlighted and opens the exact content location.
- Bundled Quran search works offline.

### TASK-007

- No unapproved visible English remains in Arabic flows.
- Dates/times and mixed Arabic/English text follow the documented locale/bidi policy.
- TalkBack/VoiceOver completes core journeys at large text sizes.
- Reduced motion is respected across onboarding, navigation, and key animations.

### TASK-008

- Each religious collection displays approved source/version metadata where applicable.
- Changes to sacred text assets require content-owner approval and integrity comparison.
- Unverified translations are labeled as such or excluded.

### TASK-009

- Full unit/widget/integration suite is green.
- Physical Android notification/location/deep-link tests pass.
- Physical iOS notification/Qibla tests pass.
- Accessibility and large-text checks are recorded.
- Signed release artifact is built and install-tested.

## 44. QA Test Cases

| Test ID | Feature | Preconditions | Steps | Expected result | Priority |
|---|---|---|---|---|---|
| QA-001 | First launch | Fresh install | Launch app, observe startup | Shell/onboarding appears without unexplained hang; startup timing recorded | P1 |
| QA-002 | Onboarding skip | Fresh install | Skip pages, deny notifications | Home opens; permission can be revisited; no data loss | P1 |
| QA-003 | Quran offline | Network disabled | Open Quran and surah | Bundled content loads and is readable | P1 |
| QA-004 | Quran large text | Accessibility font enlarged | Browse/open surah | No clipping; controls remain usable; screen reader labels work | P1 |
| QA-005 | Quran bookmark | Surah open | Bookmark, restart, reopen | Exact bookmark restores and action feedback is accessible | P2 |
| QA-006 | Search Arabic | Search implemented | Query with diacritics/variant/no result | Normalized results/highlighting/empty recovery work | P1 |
| QA-007 | Prayer permission denied | Fresh permission state | Open prayer and deny location | Manual location path appears; no silent Cairo/Makkah fallback | P0 |
| QA-008 | Prayer success | Network available | Load prayer times | Correct approved location/method/date/timezone shown | P0 |
| QA-009 | Prayer offline cache | Prior successful fetch | Disable network, refresh | Cached/stale status appears with timestamp and retry | P1 |
| QA-010 | Prayer date rollover | Device/test clock controlled | Cross local midnight | New date loads and old notifications are handled safely | P1 |
| QA-011 | Prayer notification | Permission/audio configured | Schedule near-future prayer | Notification arrives at expected local time with approved sound/fallback | P0 |
| QA-012 | Notification denial | Notifications denied | Open settings/retry scheduling | Clear recovery path; app remains usable | P1 |
| QA-013 | Notification tap | App foreground/background/terminated | Tap each feature payload | Correct destination opens; malformed data falls back safely | P0 |
| QA-014 | Boot recovery | Scheduled alarms | Reboot/update device | Intended schedules are restored or user is informed | P1 |
| QA-015 | Qibla denied | Location denied/permanently denied | Open Qibla | Correct explanation and settings recovery; textual alternative present | P1 |
| QA-016 | Qibla sensor | Real device with compass | Calibrate and rotate | Bearing is stable/accurate within agreed tolerance | P1 |
| QA-017 | Dua/adhkar | Offline | Browse/read/count/share | Content loads, source policy applies, actions give feedback | P1 |
| QA-018 | Hadith | Offline | Open list/detail/invalid route | Data and source state are clear; invalid route recovers | P1 |
| QA-019 | Tasbeeh | Any device | Increment, background, restart, reset | Count policy is consistent and reset is confirmed | P2 |
| QA-020 | Khatma notification | Plan and reminder configured | Tap reminder | Khatma destination opens, not Home fallback | P1 |
| QA-021 | Media offline | Network disabled | Open article/audio/video | Cached content or clear offline state with retry | P2 |
| QA-022 | Theme/RTL | Arabic locale | Switch light/dark, large text, rotate | Contrast/layout/icon direction pass | P1 |
| QA-023 | FCM token | Firebase release config | Get/refresh/delete token | Backend lifecycle follows privacy contract; no raw logs | P1 |
| QA-024 | Release artifact | Signed build | Install/upgrade/uninstall | Correct identity, signing, Firebase startup, migration | P0 |

## 45. Production Release Checklist

| Area | Check | Status | Evidence/owner |
|---|---|---|---|
| Functional | Core flows pass on device | BLOCKED | Runtime matrix required |
| UX | Prayer trust inputs and recovery complete | FAIL | AUD-001/002 |
| UI | Visual regression/screenshot review complete | REQUIRES VERIFICATION | No visual session |
| Accessibility | TalkBack/VoiceOver/large text pass | REQUIRES VERIFICATION | No device audit |
| Localization | ARB/Arabic review complete | FAIL | No ARB; English states |
| RTL | Bidi/date/icon/gesture pass | REQUIRES VERIFICATION | Device tests required |
| Religious content | Sources and scholarly review approved | BLOCKED | Verification required |
| Notifications | Delivery/tap/boot/timezone pass | BLOCKED | Device tests required |
| Performance | Startup/frame/memory/battery budgets met | REQUIRES VERIFICATION | No measurements |
| Security | Threat model/dependency/config review | REQUIRES VERIFICATION | Security testing required |
| Privacy | Data inventory/retention/deletion published | FAIL | Policy not evident |
| Android | Final ID, permissions, release signing | FAIL | Debug signing/sample ID |
| iOS | Real Firebase config/bundle alignment | FAIL | Placeholder plist |
| Firebase | Android/iOS/project alignment | FAIL | Configuration mismatch |
| Signing | Release keystore protected and verified | FAIL | Debug signing configured |
| Store metadata | Name, IDs, privacy, content rating, screenshots | REQUIRES VERIFICATION | Not audited |
| Crash monitoring | Production crash reporting configured | REQUIRES VERIFICATION | Not evidenced |
| Analytics | Privacy-approved analytics policy | REQUIRES VERIFICATION | Not evidenced |
| Backup/migration | Preferences migration/recovery tested | REQUIRES VERIFICATION | SharedPreferences paths need tests |
| Rollback | Version rollback/remote disable strategy | REQUIRES VERIFICATION | Release process not evidenced |

## 46. Product Health Dashboard

| Area | Status | Evidence | Risk |
|---|---|---|---|
| Functionality | Needs Attention | Broad implementation/tests; key gaps | Core trust/features incomplete |
| UX | Significant Issues | Fixed prayer input, unfinished search, fragmented settings | User confusion/trust |
| UI | Needs Attention | Theme system exists; mixed English and visual validation absent | Inconsistency/accessibility |
| Accessibility | Insufficient Evidence | Partial Semantics only | Exclusion risk |
| RTL | Needs Attention | Global RTL; formatting/mixed-language risks | Incorrect reading/navigation |
| Notifications | Critical Issues | Code exists; runtime/audio/backend gaps | Missed reminders |
| Performance | Insufficient Evidence | Code risks, no metrics | Unknown startup/battery risk |
| Security | Requires Verification | Config/readiness concerns | Release/privacy risk |
| Privacy | Needs Attention | Data uses evident, policy incomplete | Compliance/trust risk |
| Content | Requires Verification | Assets exist, provenance unestablished | Religious/content trust |
| Reliability | Needs Attention | Error states/tests; cache gap | Offline/network failure |
| Release Readiness | Critical Issues | Debug signing/config mismatch/test failure | Cannot publish |

## 47. Priority Matrix

### P0 - Release blockers

- AUD-001 prayer location and correctness.
- AUD-004 debug release signing.
- AUD-005 platform/Firebase/application identity alignment.
- AUD-018 real iOS Firebase configuration.
- Notification delivery/tap behavior and prayer scheduling device verification.

### P1 - High priority

- AUD-002 calculation method mismatch.
- AUD-003 prayer cache.
- AUD-006 audio asset.
- AUD-007 FCM lifecycle.
- AUD-008 reboot recovery.
- AUD-009 Khatma route.
- AUD-010 search.
- AUD-011 localization.
- AUD-012 accessibility.
- AUD-013 performance measurement.
- AUD-014 content provenance.
- AUD-015 external links.
- AUD-016 broken integration contract.
- AUD-017 privacy lifecycle.

### P2 - Medium priority

Tasbeeh polish, reading history, richer media behavior, per-category reminder controls, shared design-system refinements, and content discovery improvements after P0/P1.

### P3 - Low priority

Widgets, advanced personalization, analytics, and nonessential visual polish after release reliability is established and privacy is approved.

## 48. Development Roadmap

### Phase 0 - Audit & Stabilization

**Goals:** Resolve broken test contract, freeze approved product/religious policies, finalize release identity matrix.  
**Issues:** AUD-002, AUD-004, AUD-005, AUD-016, AUD-018.
**Exit criteria:** Full existing suite green; approved location/method/identity decisions recorded.

### Phase 1 - Critical Fixes

**Goals:** Make prayer, release configuration, and notifications trustworthy.  
**Tasks:** TASK-001 through TASK-004.  
**Exit criteria:** Signed artifact, device prayer/notification matrix passes, no unexplained location fallback.

### Phase 2 - Core UX Improvements

**Goals:** Improve search, settings, onboarding, recovery, and trust information.  
**Tasks:** TASK-005, TASK-006, prayer/settings redesign.  
**Exit criteria:** Core journeys are routeable, localized, recoverable, and tested.

### Phase 3 - UI & Design System

**Goals:** Centralize state components, Arabic typography, visual tokens, and accessibility semantics.  
**Tasks:** TASK-007 plus design-system work.  
**Exit criteria:** Screenshot/accessibility/RTL checks pass at target sizes.

### Phase 4 - Advanced Features

**Goals:** Add only validated value such as reading history, widgets, per-prayer controls, or analytics.  
**Dependencies:** Core reliability, privacy approval, product validation.  
**Exit criteria:** Each feature has a user need, acceptance criteria, analytics/privacy decision, and rollback plan.

### Phase 5 - QA & Release

**Goals:** Validate production artifact and publish safely.  
**Tasks:** TASK-009, release checklist, store/privacy/content approval.  
**Exit criteria:** No P0/P1 release blockers; signed artifacts and rollback/monitoring plan approved.

## 49. Sakina Quran App - Product Development Blueprint

### Blueprint A: Prayer trust

**Problem:** Users may receive timings calculated for Cairo with an undisclosed method.  
**Evidence:** AUD-001/AUD-002; fixed Cairo service, Home coordinates, provider method 5 versus repository method 3. **Evidence Type: Verified in Code + UX/UI Observation.**  
**Root cause:** Location and calculation policy are not a single user-owned domain configuration.  
**UX solution:** Ask for location contextually, provide manual fallback, show place/date/method/timezone/freshness.  
**UI solution:** Trust header, edit controls, stale/offline banner, next-prayer card.  
**Technical solution:** `PrayerConfiguration`, Geolocator/manual city adapter, keyed cache, date/timezone refresh.  
**Development task:** TASK-002 and TASK-003.  
**Acceptance criteria:** QA-007 through QA-010 pass; no silent fallback; approved scholarly method is consistent.  
**Release verification:** Device matrix across permission denial, travel/timezone, offline, midnight, and signed release.

### Blueprint B: Notification reliability

**Problem:** Notification code exists, but actual delivery, audio, reboot behavior, backend token lifecycle, and Khatma routing are unproven/incomplete.  
**Evidence:** AUD-006 through AUD-009; channel references missing audio, token sync is placeholder, `/khatma` route absent. **Evidence Type: Verified in Code + Requires Runtime Verification.**  
**Root cause:** Scheduling was implemented without a complete persisted lifecycle and platform acceptance matrix.  
**UX solution:** Category controls, permission explanation/recovery, next-run preview, safe destination and status.  
**UI solution:** Notification settings grouped by category; diagnostics separate from normal settings; masked token display.  
**Technical solution:** Persist schedules, rebuild after boot/update/date/timezone changes, validate payloads, implement backend token lifecycle, add approved sound/fallback.  
**Development task:** TASK-004 and TASK-005.  
**Acceptance criteria:** QA-011 through QA-014 and QA-020 pass.
**Release verification:** Android/iOS foreground/background/terminated/reboot tests on signed builds.

### Blueprint C: Production release foundation

**Problem:** Release configuration is still development-oriented and platform Firebase identities are inconsistent.  
**Evidence:** AUD-004/AUD-005/AUD-018; debug signing, sample ID, placeholder iOS plist, differing project/bundle identities. **Evidence Type: Verified in Configuration.**  
**Root cause:** No enforced release configuration contract or CI gate.  
**UX/product solution:** None directly; users need a stable, correctly identified app.  
**Technical solution:** Final identity matrix, secure signing, real iOS Firebase file, CI checks, dependency/security review.  
**Development task:** TASK-001.  
**Acceptance criteria:** QA-024 passes and release checklist has no FAIL in Android/iOS/Firebase/signing.  
**Release verification:** Store-like install, upgrade, uninstall/reinstall, Firebase startup, crash monitoring, and rollback drill.

### Blueprint D: Discoverability and localization

**Problem:** Search is visibly unfinished and Arabic users see English state copy; no ARB localization layer exists.  
**Evidence:** AUD-010/AUD-011; Home search label and prayer strings. **Evidence Type: UX/UI Observation + Verified in Code.**  
**Root cause:** Product discovery and localization were implemented as feature-local strings rather than shared contracts.  
**UX solution:** Complete search flow and consistent Arabic content states.  
**UI solution:** Localized search field/results, grouped state components, bidi-safe metadata.  
**Technical solution:** ARB resources, locale-aware formatters, Arabic normalization/search indexing.  
**Development task:** TASK-006/TASK-007.  
**Acceptance criteria:** QA-006 and QA-022 pass; no unapproved visible English remains.  
**Release verification:** Arabic large-text, screen-reader, offline search, and mixed-language content review.

### Blueprint E: Religious content trust

**Problem:** Local assets are present but source/edition/version metadata is not established in the product.  
**Evidence:** AUD-014 and Section 34. **Evidence Type: Religious/Content Verification Required.**  
**Root cause:** Content governance and release provenance are not visible in the application contract.  
**UX solution:** Source/edition/narrator metadata where relevant; clearly label translations and unverified material.  
**UI solution:** Source metadata component on detail screens and About/Sources settings.  
**Technical solution:** Content manifest/version/integrity checks and approval workflow.  
**Development task:** TASK-008.  
**Acceptance criteria:** Content owner approves every collection; sacred text changes are integrity-reviewed.  
**Release verification:** Signed content manifest and documented scholar/content approval.

## 50. Final Recommendations

### Must change before production

1. Replace unexplained fixed prayer location and centralize approved calculation policy.
2. Implement prayer cache and lifecycle handling.
3. Align Android/iOS/Firebase identities and replace debug signing/placeholder configuration.
4. Verify notifications on real devices, including permission, audio, boot, taps, timezone, and terminated states.
5. Resolve the failing integration test and add production AppRoot/device smoke coverage.
6. Remove or replace placeholder external links.

### Should be redesigned

Prayer trust presentation, settings organization, home prioritization, search entry/result flow, shared loading/error/stale components, and Arabic/RTL state presentation.

### Should be developed

Search, FCM backend token lifecycle, content provenance, robust offline states, Khatma canonical destination, and accessibility/device QA gates.

### Should not be claimed yet

Working notifications, accurate personalized prayer times, production cross-platform parity, complete accessibility, verified religious authenticity, measured performance, or security compliance.

### Final answer to the production-readiness question

To move Sakina from its current state to a production-ready religious app, the team must first establish trustworthy domain inputs and release configuration, then prove platform behavior on devices, then complete localization/accessibility/content governance, and only afterward add advanced personalization. The implementation path is defined by the issue tracker, backlog, acceptance criteria, QA cases, release checklist, and five linked blueprints in this document.
