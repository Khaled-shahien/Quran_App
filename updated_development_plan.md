# UPDATED DEVELOPMENT & IMPROVEMENT PLAN

> **This document is the single source of truth for the Sakina Quran App's development status.**

---

## 1. Audit Update Summary

| Metric | Value |
|---|---|
| **Previous audit date** | 2026-09-22 |
| **Previous plan update** | 2026-09-28 (docs/production-fix-progress.md) |
| **Current re-audit date** | 2026-09-28 |
| **Original tracked tasks** | 40 (T01–T40) |
| **STATUS A — Completed** | 17 |
| **STATUS B — Partially Completed** | 16 |
| **STATUS D — Needs Rework** | 1 (T11) |
| **STATUS F — Blocked** | 3 (T34, T35, T39) |
| **STATUS C — Not Implemented** | 0 |
| **STATUS E — No Longer Applicable** | 0 |
| **STATUS G — Unable to Verify** | 3 tasks have runtime/device aspects that cannot be verified statically |
| **New findings this re-audit** | 5 (NF-001 through NF-005) |
| **Confirmed test failures** | 3 (Quran surah name/number lookup in `quran_search_screen_test.dart`) |
| **Static analysis** | `dart analyze lib`: **no issues** |
| **Full test suite** | **220 tests: 217 passed, 3 failed** |
| **Current production blockers** | 5 categories (identity/signing, content, notifications, privacy/store, device evidence) |
| **Production readiness** | **NOT READY** |

---

## 2. Current Project Baseline

### Architecture

| Layer | Implementation | Evidence |
|---|---|---|
| Framework | Flutter 3.48.0-0.5.pre / Dart 3.14 beta | [pubspec.yaml](file:///e:/Projects/01-personal/Quran-App/pubspec.yaml) |
| Structure | Feature-oriented `lib/features/` with data/domain/presentation layers | [lib/features](file:///e:/Projects/01-personal/Quran-App/lib/features) |
| State management | Provider/ChangeNotifier | Prayer, settings, media, Quran providers |
| DI | GetIt service locator | [service_locator.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/di/service_locator.dart) |
| Navigation | GoRouter with ShellRoute (5-tab bottom nav) | [app_router.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/navigation/app_router.dart) |
| Storage | SharedPreferences (prayers, bookmarks, settings, Khatma) | Multiple providers |
| Content | Bundled JSON: Quran, duas, hadith, prayer cities | [assets/](file:///e:/Projects/01-personal/Quran-App/assets) |
| Network | HTTP to Aladhan, RSS, MP3Quran, YouTube | Data source files |
| Firebase | Core, Messaging (dormant), Crashlytics (opt-in), Analytics (opt-in) | [firebase_options.dart](file:///e:/Projects/01-personal/Quran-App/lib/firebase_options.dart) |
| Notifications | flutter_local_notifications, WorkManager, boot receivers | [notification_service.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/services/notification_service.dart) |
| Monitoring | Optional Crashlytics + Analytics, off by default, requires build flag + user opt-in | [monitoring_service.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/services/monitoring_service.dart) |
| Localization | Partial ARB (11 strings), inline Arabic elsewhere | [app_ar.arb](file:///e:/Projects/01-personal/Quran-App/lib/l10n/app_ar.arb) |
| Fonts | Bundled Cairo + Amiri with OFL licenses | [fonts/](file:///e:/Projects/01-personal/Quran-App/fonts) |
| Themes | Light/dark Material 3 with `AppColors`, `AppTypography`, component themes | [app_theme.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/theme/app_theme.dart) |

### Implemented Features

| Feature | Status | Key files |
|---|---|---|
| Splash | Working (2s delay) | [splash_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/splash/presentation/screens/splash_screen.dart) |
| Onboarding | Working | [onboarding_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/onboarding/presentation/screens/onboarding_screen.dart) |
| Home hub | Working (extracted widgets) | [home_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/onboarding/presentation/screens/home_screen.dart) |
| 5-tab navigation | Working | [main_navigation_shell.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/navigation/main_navigation_shell.dart) |
| Quran browsing | Working offline | [quran_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/quran/presentation/screens/quran_screen.dart) |
| Quran reader | Working (extracted parts) | [surah_details_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/quran/presentation/screens/surah_details_screen.dart) |
| Quran search (verse) | Working offline with highlighting | [quran_search_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/quran/presentation/screens/quran_search_screen.dart) |
| Quran search (surah name/number) | **Code present but tests fail** | Same file — `_matchingSurahs` + `_loadSurahNames()` |
| Prayer times | Working with GPS/manual/city selection | [prayer_times_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/prayers/presentation/screens/prayer_times_screen.dart) |
| Prayer location dialog | Working with city catalog | [prayer_location_dialog.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/prayers/presentation/screens/prayer_location_dialog.dart) |
| Qibla | Working in code; device unverified | [qibla_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/qibla/presentation/screens/qibla_screen.dart) |
| Duas | Working offline | [duas_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/duas/presentation/screens/duas_screen.dart) |
| Adhkar | Working offline | [azkar_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/duas/presentation/screens/azkar_screen.dart) |
| Hadith | Working offline | [hadeath_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/hadeath/presentation/screens/hadeath_screen.dart) |
| Tasbeeh | Working | [tasbeeh_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/quran/presentation/screens/tasbeeh_screen.dart) |
| Khatma | Working with completion dialog | khatma screens + `/khatma` route |
| Asma al-Husna | Present; content verification needed | [asma_al_husna_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/quran/presentation/screens/asma_al_husna_screen.dart) |
| Media (articles/audio/video) | Working with cache; offline partial | media screens |
| Settings | Working (theme, reading, location, notifications, monitoring, about, sources) | [settings_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/settings/presentation/screens/settings_screen.dart) |
| Notifications (local) | Scheduling code present; device delivery unverified | notification_service.dart |
| Bookmarks/Favorites | Working (SharedPreferences) | bookmark/favorites providers |
| Continue reading | Working | Home shortcut |
| Content manifest | Present but `pending_owner_review` | [content_manifest.json](file:///e:/Projects/01-personal/Quran-App/content_manifest.json) |

### Firebase Configuration State

> [!WARNING]
> **Two different Firebase projects are in use:**
> - Android/iOS: `quran-app-10d05` (project ID)
> - Web/macOS/Windows: `quran-app-754e2` (project ID)
> - Android namespace: `com.example.sakina_app`
> - iOS bundle: `com.example.quranApp`
> - iOS GoogleService-Info: **placeholder only** (`GoogleService-Info.plist.placeholder`)

---

## 3. Previous Findings vs Current State

| Area | Previous State (2026-09-22) | Current State (2026-09-28) | Change |
|---|---|---|---|
| Prayer location | Silent/fixed Cairo fallback | GPS/manual/city selection, method persistence, stale-request protection, timezone-aware display | ✅ Major improvement |
| Prayer cache | Write-through incomplete | Keyed cache, expiry, stale metadata, refresh paths | ✅ Improved; multi-day/DST pending |
| Prayer calculation | Methods 5 vs 3 conflict | Centralized `PrayerCalculationPolicy` with 3 selectable methods (MWL, Umm al-Qura, Egyptian) | ✅ Resolved |
| Signing/identity | Debug signing, sample IDs | Debug fallback rejected in Gradle; but identities remain `com.example.*` | ⚠️ Partial |
| Khatma route | `/khatma` missing from router | Canonical `/khatma` route defined with `CurrentWirdWidget` | ✅ Fixed |
| Notification routing | Khatma notification fell back to Home | `NotificationRouter._navigateToKhatma` now routes to `/khatma` | ✅ Fixed |
| Search | Explicitly "under development" | Offline verse search + surah name/number code present | ⚠️ Partial (3 tests fail) |
| Localization | No ARB, English prayer states | 11-string ARB, `flutter_localizations`/`intl` added, prayer screen localized | ⚠️ Partial |
| Dark mode | Gaps in components | Component themes added: navigation, sheet, dialog, input, scrollbar | ✅ Fixed |
| Fonts | Dynamic GoogleFonts fetch | Bundled Cairo + Amiri with OFL licenses | ✅ Fixed |
| Navigation | Feature-specific routing only | 5-tab bottom NavigationBar shell | ✅ Major improvement |
| Settings | Fragmented/missing | Full settings screen with sections | ✅ Major improvement |
| Content provenance | Not tracked | `content_manifest.json` with SHA-256 hashes, `pending_owner_review` | ⚠️ Partial |
| Privacy | No inventory | Draft policy, data inventory, data sources screen | ⚠️ Partial |
| Monitoring | Not configured | Crashlytics + Analytics, opt-in, disabled by default | ⚠️ Partial |
| FCM/push | Active at startup | Startup messaging disabled, auto-init disabled, local-only production | ✅ Improved |
| Splash | 3.5s fixed delay | 2s delay, independent onboarding state | ✅ Improved |
| External links | Placeholder donation URL | Removed | ✅ Fixed |
| Test contract | Integration test expected wrong loader | Fixed, 220 tests total, 217 pass | ⚠️ 3 failures remain |
| Home | Dense single hub | Extracted widgets (drawer, khatma, prayer, continue-reading) | ✅ Improved |
| Reader | Monolithic screen | Extracted data/content/controls/buttons parts | ✅ Improved |
| Timer | Per-second setState rebuilds | Per-minute refresh | ✅ Improved |
| iOS Firebase | Placeholder plist | Still placeholder (`GoogleService-Info.plist.placeholder`) | ❌ No change |

---

## 4. Master Task Status Table

| ID | Original Task | Category | Orig. Priority | Current Status | Completion | Remaining Work | New Issues | Next Action |
|---|---|---|---:|---|---:|---|---|---|
| T01 | GPS flow | Prayer | P1 | B | 75% | Physical denial/travel tests | NF-001 | Fix error handling + device tests |
| T02 | Location UI | Prayer | P1 | B | 75% | Policy and device UX | — | Scholarly method approval |
| T03 | Release signing | Release | P0 | B | 50% | Keystore/IDs/signed artifact | — | Owner credentials |
| T04 | Dark components | Theme | P1 | A | 100% | — | — | Maintenance |
| T05 | Caption contrast | Theme | P1 | A | 100% | — | — | Maintenance |
| T06 | Crashlytics | Monitoring | P1 | B | 75% | iOS/symbol/project verification | — | Approved Firebase project |
| T07 | Analytics | Monitoring | P2 | B | 75% | Dashboard/retention | — | Approved Firebase project |
| T08 | Privacy | Privacy | P0 | B | 75% | Owner/contact/public URL | — | Owner approval |
| T09 | Settings | UI/UX | P1 | A | 100% | — | — | Maintenance |
| T10 | Quran search | Feature | P1 | B | 75% | **3 surah lookup tests fail** | NF-003 | Fix test regression |
| T11 | FCM decision | Architecture | P1 | D | 75% | Dormant code/dependency cleanup | — | Remove or isolate FCM |
| T12 | Content provenance | Content | P0 | B | 75% | Sources/reviewer approval | — | Owner/scholar review |
| T13 | Diagnostic route | Debug | P1 | A | 100% | — | — | Maintenance |
| T14 | Device notifications | Notifications | P0 | B | 50% | Physical matrix + future-day replenishment | — | Device testing |
| T15 | Primary navigation | Navigation | P2 | A | 100% | — | — | Maintenance |
| T16 | Continue reading | Feature | P2 | A | 100% | — | — | Maintenance |
| T17 | Refresh | Feature | P2 | A | 100% | — | — | Maintenance |
| T18 | Media offline UX | Feature | P2 | B | 75% | Complete cached/stale validation | — | Device testing |
| T19 | Splash | UI/UX | P2 | A | 100% | — | — | Maintenance |
| T20 | Khatma completion | Feature | P3 | A | 100% | — | — | Maintenance |
| T21 | Home refactor | Architecture | P2 | A | 100% | — | — | Maintenance |
| T22 | Reader refactor | Architecture | P2 | A | 100% | — | — | Maintenance |
| T23 | Color aliases | Theme | P2 | A | 100% | — | — | Maintenance |
| T24 | Directionality | RTL | P2 | B | 75% | Bidi/icon review | NF-002 | Tooltip + direction audit |
| T25 | Use-case dirs | Architecture | P3 | A | 100% | — | — | Maintenance |
| T26 | Bundled fonts | Assets | P1 | A | 100% | — | — | Maintenance |
| T27 | Semantics | Accessibility | P1 | B | 75% | Screen-reader audit | — | Device audit |
| T28 | Dark visual tests | Testing | P2 | A | 100% | — | — | Maintenance |
| T29 | RTL tests | Testing | P1 | A | 100% | — | — | Maintenance |
| T30 | Network failure tests | Testing | P1 | A | 100% | — | — | Maintenance |
| T31 | Accessibility suite | Accessibility | P0 | B | 75% | Device audit | — | Physical accessibility testing |
| T32 | Integration flows | Testing | P1 | B | 75% | Physical/signed run | — | Signed artifact testing |
| T33 | Store listing | Release | P1 | B | 50% | Final assets/URL | — | Owner assets |
| T34 | iOS Firebase | Platform | P0 | F | 25% | Blocked on platform decision | — | Owner decision |
| T35 | Device matrix | QA | P0 | F | 25% | Physical devices unavailable | — | Acquire devices |
| T36 | Security review | Security | P0 | B | 50% | Independent review | NF-004 | Security review |
| T37 | Profiling | Performance | P2 | B | 50% | Profile measurements | — | Profile build |
| T38 | Final regression | QA | P0 | B | 50% | 3 test failures + physical regression | NF-003 | Fix tests + device regression |
| T39 | Store release | Release | P0 | F | 0% | All gates must close | — | All blockers |
| T40 | Operations | Operations | P1 | B | 50% | Alerts/owners/evidence | — | Approved project |

---

## 5. Completed Implementations

The following tasks are verified complete at repository/test scope:

| ID | Implementation | Evidence |
|---|---|---|
| T04 | Dark component themes (navigation, sheet, dialog, input, scrollbar) | [app_theme.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/theme/app_theme.dart) + tests |
| T05 | Dedicated dark caption token with automated contrast check | app_colors.dart + test |
| T09 | Full settings screen: theme, reading, location, notifications, monitoring, about, sources | [settings_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/settings/presentation/screens/settings_screen.dart) |
| T13 | Debug-only notification test route | [notification_test_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/settings/presentation/screens/notification_test_screen.dart), `kDebugMode` guard |
| T15 | 5-destination NavigationBar shell (Home, Quran, Prayer, Adhkar, Settings) | [main_navigation_shell.dart](file:///e:/Projects/01-personal/Quran-App/lib/core/navigation/main_navigation_shell.dart) |
| T16 | Continue-reading bookmark shortcut restoring reader position | Home widget |
| T17 | Prayer pull-to-refresh and media retry paths | Prayer screen + tests |
| T19 | 2-second splash delay with independent onboarding state tracking | [splash_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/splash/presentation/screens/splash_screen.dart) |
| T20 | Khatma completion congratulations dialog | Khatma feature |
| T21 | Home refactored: drawer, khatma actions, prayer header, continue-reading extracted | home widgets |
| T22 | Reader refactored: data, content, controls, buttons parts extracted | [reader_*.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/quran/presentation/screens) |
| T23 | Legacy color aliases removed, canonical tokens migrated | app_colors.dart |
| T25 | `domain/usecases` directory structure verified | Feature directories |
| T26 | Cairo + Amiri bundled with OFL licenses; no dynamic GoogleFonts | [fonts/](file:///e:/Projects/01-personal/Quran-App/fonts), pubspec.yaml |
| T28 | Settings light/dark golden tests with bundled fonts | settings_golden_test.dart |
| T29 | RTL navigation + settings checks at 360px/2x text | settings_screen_test.dart |
| T30 | Network failure tests: media retry, GPS denial/stale regressions | Multiple test files |

---

## 6. Partially Completed Items

| ID | Implemented | Remaining |
|---|---|---|
| T01 | GPS/manual/city selection, stale-request protection, request ordering | Physical permission denial, travel, NF-001 error handling |
| T02 | City catalog, coordinates, device location, calculation method UI | Scholarly method/madhab approval, policy documentation |
| T03 | Gradle rejects debug fallback for release | Owner keystore, approved app ID, signed artifact |
| T06 | Opt-in Crashlytics/Android plugin | Real Firebase project events, iOS upload, symbol verification |
| T07 | Allowlisted events (app_open, settings_open) | Dashboard validation, retention policy |
| T08 | Arabic draft policy, data inventory, in-app sources page | Owner contact, retention approval, public URL |
| T10 | Verse search works + surah name/number code present | **3 surah lookup tests fail deterministically** |
| T12 | SHA-256 hashes, in-app disclosure, release gate | Source, edition, license, reviewer sign-off |
| T14 | Scheduling/routing code, boot receivers | Physical delivery matrix, future-day replenishment |
| T18 | Retry/error paths present | Full cached/stale validation for all media types |
| T24 | Removed redundant directionality wrapper | Bidi/icon direction review, NF-002 tooltip |
| T27 | Semantics labels on settings + icon tooltips | Complete screen-reader audit across all screens |
| T31 | Automated target/contrast/large-text checks | Physical TalkBack/VoiceOver audit |
| T32 | Settings/theme/search/reader integration flows | Physical signed-build execution |
| T33 | Arabic listing copy + screenshot requirements | Final assets, privacy URL, owner approval |
| T36 | Local security checks (signing, .gitignore, HTTPS) | Independent security review, NF-004 |
| T37 | Offline fonts, shorter splash | Profile-mode startup/frame/memory measurements |
| T38 | 220 tests (217 pass) | Fix 3 failures + physical device regression |
| T40 | Runbook/monitoring integration drafted | Alerts, named owners, production evidence |

---

## 7. Remaining Development Work

### P0 — Production Blockers

1. **Identity/signing (T03):** Supply approved Android app ID, iOS bundle ID (if applicable), matching Firebase project/config, protected signing credentials, and verify signed artifact
2. **Content provenance (T12):** Obtain source, edition, license, and qualified reviewer sign-off for Quran, duas, hadith, and prayer data
3. **Notification evidence (T14):** Physical foreground/background/terminated delivery, permission denial/recovery, reboot, upgrade, timezone, and future-day replenishment
4. **Privacy/store package (T08, T33):** Public privacy URL, support contact, store listing assets, approved disclosures
5. **Device evidence (T35, T31):** TalkBack/VoiceOver, large text, Qibla sensors, performance measurements, signed install

### P1 — Critical

6. **NF-001:** Restore error handling in manual prayer selection
7. **NF-003:** Fix 3 failing Quran surah lookup tests
8. **T11:** Isolate or remove dormant FCM code/dependency
9. **T06/T07:** Verify monitoring on approved Firebase project
10. **T36:** Complete security review

### P2 — Important

11. **NF-002:** Restore back-button tooltips in duas/azkar screens
12. **T37:** Run profile-mode measurements
13. **T18:** Validate media cached/stale behavior
14. **T24:** Complete bidi/icon direction audit
15. **NF-005:** Expand ARB localization coverage

### P3 — Enhancement

16. Post-release polish, global search, quiet hours, richer offline media

---

## 8. Items Requiring Rework

### T11 — FCM Decision (STATUS D, 75%)

**Original Finding:** FCM token backend registration was a placeholder.  
**Implementation:** Local reminders selected for production. Startup messaging/token registration and native auto-init disabled. Dormant diagnostic code/dependency retained.  
**Problem:** `firebase_messaging` remains in `pubspec.yaml` (line 66), `firebase_messaging_service.dart` (370 lines) is still present with active background handler code and FCM initialization paths. This creates:
- Unnecessary dependency size
- Privacy/audit confusion (FCM code exists but isn't used)
- `firebaseMessagingBackgroundHandler` is annotated `@pragma('vm:entry-point')` and will be compiled

**Required Action:** Either fully remove `firebase_messaging` dependency and `firebase_messaging_service.dart`, or clearly isolate it behind a feature flag with documentation. The current state misleadingly suggests push notification capability.

---

## 9. Blocked Items

| ID | Blocker | Required Resolution |
|---|---|---|
| T34 (iOS Firebase) | No launch-platform decision, no approved bundle/project identity, iOS GoogleService-Info is a placeholder file | Owner must decide iOS launch scope, supply genuine native Firebase config |
| T35 (Device matrix) | Physical test devices and evidence capture unavailable | Acquire Android test devices; decide iOS inclusion |
| T39 (Store release) | All P0 gates must close: credentials, content approval, device evidence, signed artifact validation | Complete all Phase 1–6 items |

---

## 10. New Findings

### NF-001 — Manual prayer configuration lacks controlled failure handling *(confirmed, carried from previous plan)*

**Evidence:** [prayer_times_provider.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/prayers/presentation/providers/prayer_times_provider.dart) lines 157-187: `selectLocation()` awaits `_notificationScheduler.cancelPrayerNotifications()` and multiple `_preferences?.set*` calls **without** try-catch. If any throws, the exception propagates to the caller unhandled.  
**Impact:** Storage or scheduler failure becomes an uncaught exception; user unsure if location was saved.  
**Root Cause:** Error handling was removed while asynchronous persistence remained.  
**Priority:** P1  
**Action:** Wrap the notification cancellation and preference writes in error handling; show localized retry on failure; add scheduler-failure and preference-write-failure tests.  
**Acceptance:** No uncaught UI exception from `selectLocation`; latest request remains authoritative; failed saves show localized retry; passed saves are confirmed.

### NF-002 — Back-button tooltips removed from dua/azkar screens *(confirmed, carried from previous plan)*

**Evidence:** [duas_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/duas/presentation/screens/duas_screen.dart) line 29 and [azkar_screen.dart](file:///e:/Projects/01-personal/Quran-App/lib/features/duas/presentation/screens/azkar_screen.dart) line 26: `IconButton` has no `tooltip` property. `Semantics` wrapper with label is present but doesn't provide hover/pointer tooltip.  
**Impact:** Pointer/desktop users lose hover guidance on back buttons.  
**Priority:** P2  
**Action:** Add `tooltip: 'الرجوع'` to each back IconButton, or adopt a shared back-button component with both semantics and tooltip.  
**Acceptance:** Back actions expose both semantic labels and hover tooltips.

### NF-003 — Quran surah name/number lookup tests fail *(confirmed, carried from previous plan)*

**Evidence:** `flutter test` output — 3 deterministic failures:
```
surah lookup supports 1 offline
surah lookup supports الفاتحة offline
surah lookup supports ١ offline
```
All in [quran_search_screen_test.dart](file:///e:/Projects/01-personal/Quran-App/test/features/quran/presentation/screens/quran_search_screen_test.dart). The test expects `ListTile` to appear after entering a query, but no `ListTile` is rendered.  
**Root Cause:** `_loadSurahNames()` uses `rootBundle.loadString('assets/quran_master.json')` asynchronously. The `quran_master.json` is a 2.7MB file (line 54). In the test environment, the asynchronous metadata loading race condition means `_surahs` may not be populated when the query is entered, even though `pumpAndSettle` is called. The test pre-loads the asset (line 41) but the widget's internal async state may not resolve before `_matchingSurahs` is computed.  
**Priority:** P1  
**Action:** Trace the async loading/rendering timing; ensure surah metadata is available before query evaluation completes; fix tests to be deterministic.  
**Acceptance:** All 3 tests pass; the full suite is green (220/220); surah name and number queries render exactly one result.

### NF-004 — YouTube API key exposed in committed .env file *(NEW FINDING)*

**Evidence:** [.env](file:///e:/Projects/01-personal/Quran-App/.env) contains `YOUTUBE_API_KEY=AIzaSyC1qnj7kgbOVoZowIB03OZJhGBzeljeems`. While `.env` is listed in [.gitignore](file:///e:/Projects/01-personal/Quran-App/.gitignore) (line 48), the file exists in the working tree. If this was ever committed to version history, the key is exposed.  
**Impact:** Potential unauthorized YouTube API usage, quota abuse, or billing impact.  
**Root Cause:** API key placed in a file that should be excluded but may have been committed before `.gitignore` was updated.  
**Priority:** P1 (Security)  
**Action:** Verify git history for `.env` commits. If committed: rotate the key immediately. Regardless: ensure `.env` is never committed; use `--dart-define` or CI secrets for API keys.  
**Acceptance:** No API keys in version-controlled files; `.env` confirmed absent from git history or key rotated.

### NF-005 — ARB localization covers only 11 strings *(NEW FINDING)*

**Evidence:** [app_ar.arb](file:///e:/Projects/01-personal/Quran-App/lib/l10n/app_ar.arb) contains only 11 strings: `prayerTitle`, `prayerLoadError`, `retry`, `choosePrayerLocation`, `todayPrayerTimes`, `searchQuran`, `searchAyah`, `searchHint`, `searchEmpty`. Many screens still use inline Arabic string literals (e.g., Quran search hint at line 108: `'اسم السورة أو رقمها أو جزء من آية'`, all navigation labels, all settings labels, all error messages across features).  
**Impact:** Future localization/translation work is blocked; string inconsistency risk; difficult to audit all user-facing text.  
**Root Cause:** ARB was introduced for core prayer/search screens but not extended to other features.  
**Priority:** P2  
**Action:** Systematically extract all user-facing string literals to ARB. Prioritize: settings, navigation, error messages, feature titles, then content-adjacent text.  
**Acceptance:** All user-visible strings come from ARB resources; no inline Arabic string literals remain for UI text.

---

## 11. Regressions Discovered

| Regression | Type | Evidence | Severity |
|---|---|---|---|
| NF-001: Error handling removed from `selectLocation` | Error handling | prayer_times_provider.dart | P1 |
| NF-002: Tooltip removed from 3 back buttons | Accessibility/UX | duas/azkar screens | P2 |
| NF-003: 3 surah lookup tests fail | Test regression | quran_search_screen_test.dart | P1 |

No confirmed navigation, theme, RTL, Firebase, notification delivery, or data integrity regression beyond the above. Device-only regressions remain **Unable to Verify** without physical testing.

---

## 12. Current Production Blockers

| # | Blocker | Evidence | Required Fix | Acceptance Criterion |
|---|---|---|---|---|
| PB-1 | Identity/signing | `com.example.sakina_app` in [build.gradle.kts](file:///e:/Projects/01-personal/Quran-App/android/app/build.gradle.kts) L43; iOS `com.example.quranApp`; two Firebase projects; no key.properties | Approved IDs, single Firebase project, protected signing | Signed artifact installs, matches approved IDs, identity gate passes |
| PB-2 | Religious content approval | All 4 entries in [content_manifest.json](file:///e:/Projects/01-personal/Quran-App/content_manifest.json) show `"approvalStatus": "pending_owner_review"` | Qualified reviewer provides source, edition, license, approval | `verify_content.py --require-approved` passes |
| PB-3 | Notification delivery | No physical device evidence for permission, delivery, tap, reboot, timezone | Execute full device notification matrix | Each case has expected/actual result and evidence |
| PB-4 | Privacy/store readiness | No public privacy URL, no support contact, no store assets | Owner supplies policy URL, contact, screenshots, listing | Store checklist has no missing items |
| PB-5 | Physical reliability | No TalkBack/VoiceOver, Qibla sensor, large text, performance, or signed install evidence | Execute device QA matrix per [DEVICE_QA_AND_OPERATIONS.md](file:///e:/Projects/01-personal/Quran-App/docs/DEVICE_QA_AND_OPERATIONS.md) | Each case has expected/actual result and evidence |

---

## 13. Updated Priority Matrix

| Priority | Scope | Change from Previous |
|---|---|---|
| **P0** | Signing/identity (T03), content approval (T12), notification evidence (T14), privacy/store (T08/T33), device evidence (T31/T35), iOS Firebase (T34), final regression (T38), store release (T39) | Unchanged |
| **P1** | NF-001 error handling, NF-003 test fix, NF-004 API key rotation, FCM isolation (T11), monitoring verification (T06/T07), security review (T36), location/travel UX (T01/T02), integration validation (T32), store assets (T33), operations (T40) | NF-004 added |
| **P2** | NF-002 tooltip, NF-005 ARB expansion, profiling (T37), media stale/cache (T18), bidi cleanup (T24), analytics (T07) | NF-005 added |
| **P3** | Global search, quiet hours, richer offline media, post-release polish | Unchanged |

---

## 14. Current Production Readiness

### Status: **NOT READY**

| Area | Status | Evidence |
|---|---|---|
| Functionality | ⚠️ Needs Attention | Broad implementation; 3 test failures, prayer error handling regression |
| UI | ✅ Adequate | Material 3, light/dark themes, component themes, design tokens |
| UX | ⚠️ Needs Attention | Good settings/navigation; prayer location flow needs error handling fix |
| Accessibility | ❌ Insufficient Evidence | Automated checks only; no device screen-reader/large-text audit |
| RTL | ⚠️ Needs Attention | Global RTL configured; bidi/icon direction review pending |
| Religious Content | ❌ Blocked | Assets present; all sources `pending_owner_review` |
| Performance | ❌ Insufficient Evidence | Improvements made (fonts, splash); no profile measurements |
| Security | ⚠️ Needs Attention | Local checks done; API key exposure (NF-004); independent review pending |
| Reliability | ❌ Insufficient Evidence | No device notification/reboot/timezone/offline evidence |
| Notifications | ❌ Blocked | Code present; no physical delivery/tap/reboot evidence |
| Firebase | ⚠️ Needs Attention | Two projects in use; iOS is placeholder; monitoring is opt-in |
| Testing | ⚠️ Needs Attention | 217/220 pass; 3 surah lookup failures |
| Release Config | ❌ Blocked | Debug-fallback blocked; sample IDs remain; no signed artifact |
| Store Readiness | ❌ Blocked | Draft listing; no privacy URL, screenshots, or owner approval |

---

## 15. Updated Development Roadmap

### Phase 1 — Critical Fixes (Code)

- Fix NF-001: Restore error handling in `selectLocation`
- Fix NF-003: Resolve surah lookup test failures (make full suite green)
- Fix NF-004: Rotate YouTube API key if committed to git history; remove `.env` from any tracked state
- Restore tooltips (NF-002)

### Phase 2 — Core Functional Completion (Owner-Dependent)

- Finalize prayer method/madhab/timezone policy with content owner
- Obtain approved Android app ID, iOS bundle ID (if applicable), Firebase project
- Supply signing credentials
- Obtain religious content source/edition/license/reviewer approvals
- Supply public privacy URL and support contact
- Decide iOS launch scope

### Phase 3 — Technical Cleanup

- Isolate or remove dormant FCM code and `firebase_messaging` dependency (T11)
- Expand ARB localization to all features (NF-005)
- Complete bidi/icon direction audit (T24)
- Configure approved Firebase project for monitoring (T06/T07)

### Phase 4 — Performance & Polish

- Run profile-mode startup/frame/memory measurements on physical device (T37)
- Validate media cached/stale behavior (T18)
- Optimize any measured problems

### Phase 5 — QA & Stability

- Execute physical device notification matrix (T14): permission, delivery, tap, reboot, upgrade, timezone
- Execute TalkBack/VoiceOver/large text audit (T31)
- Test Qibla on physical compass sensor
- Run signed-build integration tests (T32)
- Test future-day prayer notification replenishment
- Complete security review (T36)

### Phase 6 — Production Preparation

- Build signed release artifact with approved IDs and Firebase config
- Install/upgrade/uninstall test
- Run full regression (T38) with zero failures
- Run content integrity verification with `--require-approved`
- Approve store listing assets and screenshots
- Configure production monitoring and alerts

### Phase 7 — Release & Post-Release

- Internal test track distribution
- Staged rollout with crash/ANR/notification thresholds
- Named operational ownership
- Corrective-build process documented

---

## 16. Updated Implementation Order

| Order | Task | Dependencies |
|---:|---|---|
| 1 | Fix NF-001, NF-002, NF-003 (code fixes, make suite green) | None |
| 2 | Fix NF-004 (rotate API key if needed) | Git history check |
| 3 | Owner decisions: platform, app IDs, Firebase project, signing credentials | Product owner |
| 4 | Owner decisions: prayer method policy, content approval, privacy URL | Content owner/scholar |
| 5 | Apply approved IDs, generate Firebase config, configure signing | #3 output |
| 6 | Isolate/remove FCM (T11) | Product decision from #3 |
| 7 | Expand ARB localization (NF-005) | None (can parallel with #3-5) |
| 8 | Profile performance on physical device (T37) | Device available |
| 9 | Physical notification/permission/reboot matrix (T14) | #5 (signed build) |
| 10 | Physical accessibility/Qibla/RTL audit (T31, T35) | #5 + device |
| 11 | Signed-build integration + final regression (T32, T38) | #5 + #9 + #10 |
| 12 | Store assets, monitoring activation, operations (T33, T40) | #5 + #11 |
| 13 | Internal test → staged rollout (T39) | All above |

---

## 17. Final Development Backlog

### B-01: Harden manual prayer failure handling

| Field | Value |
|---|---|
| **ID** | B-01 |
| **Title** | Harden manual prayer failure handling |
| **Category** | Prayer / Error Handling |
| **Priority** | P1 |
| **Current Status** | NF-001 confirmed |
| **Description** | `selectLocation()` in `PrayerTimesProvider` performs notification cancellation and 4 SharedPreferences writes without try-catch. Any failure propagates as an uncaught exception. |
| **Why Needed** | Users selecting a new prayer location must receive confirmation or localized retry, not a crash. |
| **Implementation Details** | Wrap lines 173-185 in try-catch with narrowly scoped error handling. On failure: keep previous state, set `_errorMessage` with localized text, call `notifyListeners()`. Add unit tests: scheduler-failure test, preference-write-failure test. |
| **Dependencies** | None |
| **Acceptance Criteria** | No uncaught exception from `selectLocation`; failed saves show localized retry; successful saves proceed to fetch; 2 new test cases pass |
| **Validation Method** | `flutter test test/features/prayers` passes with new tests |
| **Definition of Done** | Code, tests pass, failure/success states exercised |

---

### B-02: Fix Quran surah lookup test failures

| Field | Value |
|---|---|
| **ID** | B-02 |
| **Title** | Fix Quran surah lookup test failures |
| **Category** | Quran / Testing |
| **Priority** | P1 |
| **Current Status** | NF-003 — 3 tests fail deterministically |
| **Description** | `_loadSurahNames()` asynchronously loads 2.7MB `quran_master.json`. In tests, `_surahs` is not populated when query evaluation occurs despite `pumpAndSettle`. |
| **Why Needed** | Full test suite must be green. Surah name/number lookup is an advertised feature. |
| **Implementation Details** | Either: (a) ensure `_loadSurahNames` completes before the first build via `await` in `initState` + `FutureBuilder`, or (b) fix the test to properly await the async metadata loading. Verify the widget path produces matching `ListTile` results. |
| **Dependencies** | None |
| **Acceptance Criteria** | All 3 lookup tests pass (`الفاتحة`, `١`, `1`); full suite 220/220; each query renders one result with subtitle `سورة 1` |
| **Validation Method** | `flutter test test/features/quran/presentation/screens/quran_search_screen_test.dart` and `flutter test` |
| **Definition of Done** | Zero test failures; no production behavior change for verse search |

---

### B-03: Rotate or verify YouTube API key security

| Field | Value |
|---|---|
| **ID** | B-03 |
| **Title** | Rotate or verify YouTube API key security |
| **Category** | Security |
| **Priority** | P1 |
| **Current Status** | NF-004 — key found in `.env` in working tree |
| **Description** | `.env` file contains a YouTube API key. While `.gitignore` excludes `.env`, the key may exist in git history. |
| **Why Needed** | Exposed API keys can lead to unauthorized usage, quota abuse, or billing impact. |
| **Implementation Details** | Run `git log --all --diff-filter=A -- .env` to check if `.env` was ever committed. If yes: rotate the key in Google Cloud Console immediately. Ensure no secrets are tracked. |
| **Dependencies** | Git history access |
| **Acceptance Criteria** | API key not in any tracked git commit; if previously committed, key is rotated; `.env` confirmed absent from `git ls-files` |
| **Validation Method** | `git log --all -- .env` shows no results OR key has been rotated |
| **Definition of Done** | Verified + documented |

---

### B-04: Restore back-button tooltips

| Field | Value |
|---|---|
| **ID** | B-04 |
| **Title** | Restore back-button tooltips in duas/azkar screens |
| **Category** | Accessibility / UX |
| **Priority** | P2 |
| **Current Status** | NF-002 — tooltips absent |
| **Description** | `IconButton` back buttons in `duas_screen.dart`, `azkar_screen.dart`, and `azkar_details_screen.dart` have `Semantics` wrappers but no `tooltip` property. |
| **Why Needed** | Pointer/desktop hover guidance; consistent with other screens. |
| **Implementation Details** | Add `tooltip: 'الرجوع'` to each back `IconButton`. Consider extracting a shared `AppBackButton` widget. |
| **Dependencies** | None |
| **Acceptance Criteria** | Back buttons show tooltip on hover; semantic labels still work for screen readers |
| **Validation Method** | Manual hover test + existing accessibility tests pass |
| **Definition of Done** | Code change + no test regressions |

---

### B-05: Provision production identity and signing

| Field | Value |
|---|---|
| **ID** | B-05 |
| **Title** | Provision production identity and signing |
| **Category** | Release |
| **Priority** | P0 |
| **Current Status** | T03/T34 — blocked on owner credentials |
| **Description** | Android uses `com.example.sakina_app`, iOS uses `com.example.quranApp`, two different Firebase projects. Signing requires `key.properties` which doesn't exist. |
| **Why Needed** | Cannot publish to stores with `com.example.*` identifiers or debug signing. |
| **Implementation Details** | Owner supplies: approved Android app ID, iOS bundle ID (if applicable), single Firebase project, signing keystore. Update `build.gradle.kts`, `firebase_options.dart`, iOS config. Run `flutterfire configure`. |
| **Dependencies** | Product owner decision |
| **Acceptance Criteria** | `verify_release.py` passes; signed artifact installs correctly; Firebase initializes on device |
| **Validation Method** | Signed build + install test |
| **Definition of Done** | Signed artifact verified on physical device |

---

### B-06: Approve content provenance

| Field | Value |
|---|---|
| **ID** | B-06 |
| **Title** | Approve content provenance for all religious collections |
| **Category** | Content |
| **Priority** | P0 |
| **Current Status** | T12 — `pending_owner_review` for all 4 collections |
| **Description** | Quran, duas, prayers data, and hadith assets exist but have no approved source, edition, license, or reviewer. |
| **Why Needed** | Religious content must be from verified sources with proper attribution. |
| **Implementation Details** | Content owner/scholar provides: source URL/reference, edition/version, license, reviewer name, approval date. Update `content_manifest.json`. |
| **Dependencies** | Content owner + qualified reviewer |
| **Acceptance Criteria** | `verify_content.py --require-approved` passes; all approvals archived |
| **Validation Method** | Script passes + approval records exist |
| **Definition of Done** | All 4 collections approved and documented |

---

### B-07: Verify physical notification delivery

| Field | Value |
|---|---|
| **ID** | B-07 |
| **Title** | Complete physical notification delivery evidence |
| **Category** | Notifications |
| **Priority** | P0 |
| **Current Status** | T14 — 50% |
| **Description** | Notification scheduling and routing code exists but has never been verified on a physical device for permission denial/recovery, delivery timing, tap routing, reboot survival, timezone changes, or future-day replenishment. |
| **Why Needed** | Notification reliability is critical for a prayer app. |
| **Implementation Details** | Execute the full matrix in [DEVICE_QA_AND_OPERATIONS.md](file:///e:/Projects/01-personal/Quran-App/docs/DEVICE_QA_AND_OPERATIONS.md). Implement future-day prayer replenishment if not yet present. |
| **Dependencies** | B-05 (signed build), physical devices |
| **Acceptance Criteria** | Each notification case has recorded expected/actual result and evidence |
| **Validation Method** | Physical device test with evidence capture |
| **Definition of Done** | All cases pass with archived evidence |

---

### B-08: Complete privacy/store package

| Field | Value |
|---|---|
| **ID** | B-08 |
| **Title** | Complete privacy/store package |
| **Category** | Release |
| **Priority** | P0 |
| **Current Status** | T08/T33 — 50-75% |
| **Description** | Draft privacy policy and store listing copy exist but no public URL, support contact, or final screenshots. |
| **Why Needed** | Stores require privacy policy URL and complete listing. |
| **Implementation Details** | Owner provides: support email, hosts privacy policy, approves store copy, provides/approves screenshots. |
| **Dependencies** | Product owner |
| **Acceptance Criteria** | Public privacy URL resolves; store listing is complete; owner approves |
| **Validation Method** | URL check + listing review |
| **Definition of Done** | All store requirements met |

---

### B-09: Physical accessibility and reliability audit

| Field | Value |
|---|---|
| **ID** | B-09 |
| **Title** | Complete accessibility/Qibla/reliability device audit |
| **Category** | QA / Accessibility |
| **Priority** | P0 |
| **Current Status** | T31/T35 — blocked on devices |
| **Description** | No TalkBack/VoiceOver, Qibla sensor, large text, motion, or signed install evidence. |
| **Why Needed** | Accessibility compliance and sensor accuracy verification. |
| **Implementation Details** | Walk through all primary flows with TalkBack (Android) and VoiceOver (iOS if applicable). Test Qibla on physical compass. Record large text, reduced motion, both themes. |
| **Dependencies** | Physical devices, B-05 (signed build) |
| **Acceptance Criteria** | Each case has expected/actual/evidence |
| **Validation Method** | Physical device walk-through |
| **Definition of Done** | All cases pass with archived evidence |

---

### B-10: Isolate dormant FCM code

| Field | Value |
|---|---|
| **ID** | B-10 |
| **Title** | Isolate or remove dormant FCM code and dependency |
| **Category** | Architecture |
| **Priority** | P1 |
| **Current Status** | T11 (STATUS D) |
| **Description** | `firebase_messaging` in pubspec.yaml, `firebase_messaging_service.dart` (370 lines), and `firebaseMessagingBackgroundHandler` entry point remain despite production using local-only notifications. |
| **Why Needed** | Clean architecture, smaller bundle, no privacy/audit confusion. |
| **Implementation Details** | Remove `firebase_messaging` from dependencies, delete `firebase_messaging_service.dart`, update any remaining imports. If FCM might be needed later, document the decision and feature-flag it. |
| **Dependencies** | Product decision on push notifications |
| **Acceptance Criteria** | No `firebase_messaging` import in production code; startup/privacy tests pass; bundle size reduced |
| **Validation Method** | `dart analyze lib`, `flutter test`, grep for firebase_messaging imports |
| **Definition of Done** | Clean codebase with no dormant push notification code |

---

## 18. Acceptance Criteria

| Area | Criterion |
|---|---|
| Prayer | No silent fixed fallback; explicit location/method/timezone; localized recoverable errors for all configuration paths |
| Identity | All platform IDs match approved release matrix; no `com.example.*` |
| Signing | Release artifact not signed with debug keys; keystore is protected |
| Content | All collections have approved source/edition/license/reviewer |
| Notifications | Physical evidence for permission, delivery, tap, reboot, timezone, future-day |
| Privacy | Public URL resolves; data inventory is complete; opt-out verified |
| Accessibility | TalkBack/VoiceOver complete primary flows; large text at 360dp; touch targets ≥ 48dp |
| Search | Surah name, number, and verse queries all work offline with deterministic test results |
| Testing | Full suite green (220/220); no known failures |
| Security | No API keys in version control; no debug signing; HTTPS for all calls |
| FCM | No unsupported push claim; dormant code removed or feature-flagged |

---

## 19. Definition of Done

Code/configuration exists, focused checks pass, affected flows and failure states are exercised, Arabic/RTL/accessibility impact is reviewed, documentation is updated, and external dependencies have recorded evidence. Release work additionally requires: build SHA, version, device/OS, locale/timezone, permissions, expected/actual result, and archived artifact or logs.

---

## 20. Final Release Requirements

Per [RELEASE_REQUIREMENTS.md](file:///e:/Projects/01-personal/Quran-App/docs/RELEASE_REQUIREMENTS.md) and [DEVICE_QA_AND_OPERATIONS.md](file:///e:/Projects/01-personal/Quran-App/docs/DEVICE_QA_AND_OPERATIONS.md):

1. `dart format --set-exit-if-changed lib test integration_test` — zero changes
2. `dart analyze lib` — no issues ✅ (currently passing)
3. `flutter test` — zero failures ❌ (currently 3 failures)
4. Integration tests pass on device
5. `verify_content.py --require-approved` — passes ❌ (currently blocked)
6. `verify_release.py` — identity gate passes ❌ (currently blocked)
7. Signed build installs correctly
8. Full device QA matrix completed
9. Privacy URL resolves
10. Store listing approved
11. Monitoring configured on approved project
12. Evidence archive assembled

---

## 21. Post-Release Recommendations

1. Use internal testing track before any public staged rollout
2. Monitor: crashes, ANRs, notification failures, opt-in rates, user reports
3. Set crash/ANR thresholds; pause rollout if exceeded
4. Process religious content changes through source/reviewer workflow
5. Consider for future releases: global search, quiet hours, notification history, richer offline media, further architecture decomposition
6. Establish regular dependency update cadence

---

## 22. Final Master Action Plan

```mermaid
graph TD
    A[Fix NF-001, NF-002, NF-003<br>Make test suite green] --> B[Fix NF-004<br>API key security]
    B --> C[Owner Decisions<br>IDs, Firebase, signing,<br>privacy, content]
    C --> D[Apply Identity<br>Configure Firebase<br>Set up signing]
    C --> E[Content Approval<br>Scholar review]
    C --> F[Privacy URL<br>Store listing]
    D --> G[Isolate FCM T11]
    D --> H[Expand ARB<br>NF-005]
    D --> I[Physical Notification<br>Matrix T14]
    D --> J[Accessibility/Qibla<br>Device Audit T31]
    I --> K[Profile Performance T37]
    J --> K
    K --> L[Signed Build<br>Integration + Regression<br>T32, T38]
    L --> M[Store Assets<br>Monitoring<br>Operations T33, T40]
    M --> N[Internal Test →<br>Staged Rollout T39]
    E --> L
    F --> M
    G --> L
    H --> L
```

**Immediate code actions (no owner dependency):**
1. Fix `selectLocation` error handling (NF-001)
2. Fix Quran surah lookup test failures (NF-003)
3. Restore back-button tooltips (NF-002)
4. Verify API key git history and rotate if needed (NF-004)

**Owner-dependent actions (cannot proceed without external input):**
5. Approved Android app ID, iOS bundle ID (if applicable)
6. Single Firebase project + genuine per-platform configs
7. Signing credentials (keystore, key.properties)
8. Religious content source/edition/license/reviewer approvals
9. Public privacy URL and support contact
10. Store listing approval and screenshots

**After owner inputs are received:**
11. Apply identities, regenerate Firebase options, configure signing
12. Execute physical device matrix (notifications, accessibility, Qibla, performance)
13. Run complete signed-build regression
14. Assemble release evidence archive
15. Internal test → staged rollout

> **The project has made substantial progress since the original audit.** 17/40 tasks are complete, and the architecture, navigation, settings, prayer configuration, dark mode, and font infrastructure are significantly improved. The remaining work is primarily owner-dependent decisions (identity, content approval, privacy), device verification (notifications, accessibility, sensors), and fixing 3 test failures + 2 minor regressions. No fundamental architecture or product problems remain.
