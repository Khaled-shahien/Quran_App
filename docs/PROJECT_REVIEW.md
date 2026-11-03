# Sakina (`sakina_app`) — Project Review

**Review date:** 2026-11-03
**Reviewed revision:** `ab686ba` on `main` (working tree clean, level with `origin/main`)

## Scope and limitations

**This is a static review, not a complete line-by-line audit.** No tests, builds, analyzers, formatters, dependency resolution, or the app itself were run. Nothing here shows that behavior works at runtime. Test results quoted from older repository documents are those documents' claims and were not reproduced.

| Coverage | Files or areas |
| --- | --- |
| Read in full | Entry point, initializer, DI, `AppRoot`, router, notification routing, monitoring, environment and API configuration, WorkManager service, prayer API/repository/scheduler/replenishment, Android and iOS manifests and native code, Gradle config, CI workflows, release and content scripts, `pubspec.yaml`, `analysis_options.yaml` |
| Read in part or by targeted search | `notification_service.dart`, `prayer_times_provider.dart`, `home_screen.dart`, `surah_details_screen.dart` and its `reader_*` parts, Khatma, media, Qibla, onboarding, settings, Quran data sources, most of `docs/` |
| Inventoried only | `test/` and `integration_test/` (per-file test counts and targeted reads; most test bodies were not read) |
| Skipped | `DEVELOPMENT_PLAN.md` body (1,484 lines), generated `*.g.dart` and l10n output, images, religious text accuracy, `web/`, `windows/`, `macos/`, `linux/` internals, `pubspec.lock` beyond selected packages |

**Other checks made during the review**
- Resolved plugin source was read from the local pub cache to confirm WorkManager behavior.
- `gh repo view` was run once, read-only, to check repository visibility.
- Credential files were read only with masking or by local comparison. **No secret value appears in this report.** To test for exposure, the key in `.env` was compared locally with a value in git history; temporary files outside the repository held key values for that comparison and were deleted straight after it.

**Finding labels**

Each finding has a *certainty* and a *kind*.

| Certainty | Meaning |
| --- | --- |
| **Confirmed** | Directly supported by inspected code or configuration |
| **Likely** | Supported by evidence, but needs runtime or external confirmation |
| **Unknown** | Cannot be determined from the repository |

| Kind | Meaning |
| --- | --- |
| **Defect** | The code or configuration contradicts its own intent |
| **Exposure** | Security exposure |
| **Maintenance** | Technical debt that is not currently a fault |
| **Suspicion** | Unverified concern |

---

## 1. Executive summary

Sakina (سكينة) is an Arabic-only, local-first Islamic utility app built with Flutter. It offers a Quran reader and search, prayer times and reminders, adhkar and duas, hadith, a Khatma plan, Qibla, tasbeeh, the Names of Allah, and links to external media. It has no accounts, backend, payments, or push messaging. The repository holds one app and no local packages.

The code is broad and shows deliberate hardening: request-ID guards, opt-in monitoring, release gates, and 53 test files. The repository's own documents say it is **not ready for release**, and this review agrees.

**Most important findings**

1. **An API key is exposed in public git history (F1).** The key now in the local `.env` also appears in two commits of a since-removed file. Those commits are on `origin/main` of a **public** GitHub repository. Rotate it first.
2. **First-run state is probably broken for new installs (F2).** Splash checks a flag that only `NotificationPermissionDialog` sets, and nothing in `lib/` ever displays that dialog. New users would see onboarding on every launch and would not get the first-run notification prompt.
3. **The Android boot rescheduler uses outdated WorkManager keys (F3).** The resolved plugin would fail that job with "Dart task is null". Other mechanisms partly compensate.
4. **Tapping a notification when the app is closed appears unhandled (F4).** The code never calls `getNotificationAppLaunchDetails`.
5. **A startup failure in a required phase means no UI at all (F5).** The log says the app continues in degraded mode, but the error is rethrown and `main()` never reaches `runApp`.
6. **Release is externally blocked.** The app still uses `com.example.*` identifiers that differ between platforms, signing is not set up, iOS Firebase config is missing, religious-content approval is pending, and CI pins a Flutter **beta**.

---

## 2. Repository and architecture map

### Layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | The only app entry point: registers font licenses, runs `AppInitializer.initialize()`, then `runApp(AppRoot())` |
| `lib/core/` | Startup, DI, routing, theme, API base, notifications, background work, monitoring |
| `lib/features/` | `quran`, `prayers`, `duas`, `hadeath`, `khatma`, `media`, `qibla`, `settings`, `onboarding` (which also holds the home screen), `splash` |
| `lib/l10n/` | Arabic-only localization (`app_ar.arb` is the template; there is no English ARB) |
| `assets/`, `fonts/`, `content_manifest.json` | Bundled religious content, images, fonts, and a hash manifest |
| `android/`, `ios/` | Mobile platform code, including native Qibla compass and Android boot receiver |
| `web/`, `windows/`, `macos/`, `linux/` | Platform folders exist, but monitoring and Qibla are limited to Android and iOS in code |
| `test/`, `integration_test/`, `test_driver/` | Automated tests |
| `scripts/`, `.github/workflows/` | Release and content gates, CI |
| `docs/` | Audits, plans, privacy and store drafts, release requirements |

**One app, no local packages.** `pubspec.yaml` declares a single package with no path dependencies or workspace.

### Layers as implemented

The README describes "Feature-first + Clean Architecture". The real code is **feature-first with uneven layering**:

| Layer | Implementation | Departures from the layering |
| --- | --- | --- |
| Presentation | Screens and widgets with `ChangeNotifier` providers | `surah_details_screen.dart:277` and `reader_data.dart` load `assets/quran_master.json` directly, bypassing the repositories |
| Domain | Entities, repository interfaces, small services | Fullest in `media` and `quran`; `duas` has no domain layer, and `khatma` keeps its model in `domain` with a concrete repository in `data` |
| Data | Repositories, data sources, models | `khatma_quran_locator.dart:251` is a **domain** service that reads the asset bundle |
| Cross-cutting | `core/services`, `core/navigation` | `core/services/workmanager_service.dart:7-10` imports feature data classes, so core depends on features |

### State management and DI

- **State:** `provider` with `ChangeNotifier`. `_AppRootState` (`core/app/app_root.dart:104-150`) constructs and disposes the global providers. Media providers are route-scoped in `app_router.dart:262-290`.
- **DI:** `get_it`, in `setupServiceLocator()` (`core/di/service_locator.dart:53`). `AppInitializer._setupDependencyInjection` calls it before `runApp`.
- **Mixed access:** Some code bypasses both patterns:
  - `getIt` in a widget (`quran_search_screen.dart:80`)
  - `SharedPreferences.getInstance()` in `splash_screen.dart:53` and `onboarding_screen.dart`
  - raw preference writes through `settings.prefs` in `settings_controls.dart`
  - the `NotificationService.instance` singleton in settings

### Startup order

`AppInitializer.initialize` (`core/initialization/app_initializer.dart:40`) runs these steps in order:

1. Firebase, only if monitoring is configured
2. DI
3. `PreferenceSchema.migrate` (schema version 1, which only records the version)
4. `MonitoringService.initialize`, if Firebase is up
5. Notifications and WorkManager

### Navigation

`GoRouter` is defined in `core/navigation/app_router.dart`, starting at `/splash`.

| Group | Routes |
| --- | --- |
| Shell | `/home`, `/quran`, `/prayers`, `/duas`, `/settings` |
| Quran | `/quran/search`, `/quran/surah/:number`, `/tasbeeh`, `/asma` |
| Duas and hadith | `/duas/all`, `/duas/morning`, `/duas/evening`, `/azkar/details`, `/hadeath`, `/hadeath/details/:index` |
| Khatma | `/khatma`, `/khatma/location`, `/khatma/duration` |
| Media | `/media`, `/media/articles`, `/media/audio`, `/media/videos` |
| Other | `/splash`, `/onboarding`, `/qibla`, `/settings/data-sources`, debug-only `/settings/notification-test` |

`MainNavigationShell` (`main_navigation_shell.dart:14`) only returns its child, so **there is no bottom navigation**. Users move through home cards and the drawer. The router defines no `errorBuilder`.

### Key models and data movement

| Domain | Models | Flow |
| --- | --- | --- |
| Quran | `SurahModel`/`SurahEntity`, `AyahModel`/`AyahEntity` | Asset → data source → repository → screen; the reader reads the asset itself |
| Prayers | `PrayerTimesResponse` → `PrayerTimesEntity` | AlAdhan JSON → repository (mapping and cache) → `PrayerTimesProvider` → UI and scheduler |
| Khatma | `KhatmaModel`, `WirdReadingPosition` | Provider ↔ `KhatmaRepository` as JSON in SharedPreferences |
| Media | `*Model` → `Article`, `Reciter`, `SurahAudio`, `Video` | Remote data source and `CachedApiService` → repository → use case → route-scoped provider |

---

## 3. Main user flows

These are traced from code only. None was executed.

### Launch and onboarding
`main` → `AppInitializer` → `AppRoot` → `/splash`. After a 2-second delay, `splash_screen.dart:56` reads `has_seen_notification_permission` and goes to `/home` or `/onboarding`. Finishing onboarding writes a *different* key, `onboarding_complete` (`onboarding_screen.dart:55`), which no code reads. See F2.

### Quran reading
`QuranScreen` (`Consumer<SurahRepository>`) → `SurahRepositoryImpl.getAllSurahs` (24-hour SharedPreferences cache, then `LocalSurahDataSource`) → `/quran/surah/:number`. `SurahDetailsScreen._loadVerses` then reads the asset directly. Bookmarks go through `BookmarkProvider`. Khatma context arrives through route extras, and progress is saved through `KhatmaProvider`.

### Quran search
`/quran/search` → `getIt<AyahRepository>` → `searchQuran` (`domain/services/quran_search.dart`), which normalizes only the search index and leaves displayed text unchanged. Search works on bundled data, with no network call.

### Prayer times and reminders
1. The user picks a city from `assets/prayer_cities.json`, or uses device location (`useDeviceLocation` → `DevicePrayerLocationService`, using `geolocator`).
2. `selectLocation` cancels existing reminders and saves coordinates, label, and method, with rollback if a write fails.
3. `fetchPrayerTimes` → `PrayerTimesRepositoryImpl` (2-hour cache, stale fallback on network or API errors) → `PrayerTimesApiService` → AlAdhan `/timings/{date}`.
4. `_schedulePrayerNotifications` → `LocalPrayerNotificationScheduler` → `NotificationService.scheduleAllPrayersForDate`, then a one-off WorkManager job.
5. In the background, `PrayerReplenishmentService.replenish` queues today plus two days using saved coordinates, never background GPS. It runs from a 12-hour periodic task and one-off tasks.

Timing is computed in the API-returned timezone (`prayer_time_zone.dart`). `AppRoot` refreshes on resume and updates the clock every minute.

### Adhkar, duas, and hadith
`AzkarProvider` and `DuasProvider` load at startup (`app_root.dart:135-137`) from `assets/prayers_data.json` and `assets/quran_duas.json`. Hadith comes from `assets/hadeath/ahadeth.txt`, split on `#` (`local_hadeath_data_source.dart`).

### Khatma
`/khatma/location` → `/khatma/duration` → `KhatmaProvider.startNewKhatma` resolves the starting position with `KhatmaQuranLocator`, saves the plan, and schedules a daily reminder (ID 1205). The home widgets and reader then track daily wird progress.

### Qibla
`QiblaController` → `QiblaDeviceService` (permission and position through `geolocator`, heading through the `sakina/qibla_heading` EventChannel) → native `QiblaCompass.kt` or the Swift `QiblaCompass` in `AppDelegate.swift`.

### Media
Articles come from four RSS feeds, parsed with **regular expressions**. Audio uses the mp3quran API and opens an **external** app via `launchUrl` (`audio_player_sheet.dart:141`), because the project has no in-app audio package. Videos use YouTube Data API search and open externally. All three use a 6-hour cache.

### Reminders and notification taps
Settings or home controls → `SettingsProvider`/`NotificationSchedulingCoordinator` → `NotificationService`. A tap goes through `_onNotificationTapped` (`notification_service.dart:296`) → `NotificationRouter` → `handleNotificationNavigation` → `context.go`.

---

## 4. Integrations and data storage

| Integration | Status | Implementation | Configuration and credentials |
| --- | --- | --- | --- |
| AlAdhan prayer API | Present | `prayer_times_api_service.dart`, `base_api_service.dart` | Base URL overridable with `PRAYER_API_BASE_URL`; `PRAYER_API_KEY` is defined but not used by the code |
| AlQuran Cloud base URL | Default only | `api_constants.dart` | `ApiConstants.baseUrl` is used only as a `BaseApiService` fallback; Quran content is bundled. `QURAN_API_KEY` is also unused |
| YouTube Data API | Present | `video_remote_datasource.dart` | **Needs `YOUTUBE_API_KEY`** via dart-define; compiled into the client and sent as a query parameter. Missing key produces `MissingApiKeyException` |
| mp3quran | Present | `audio_remote_datasource.dart` | No credentials |
| RSS article feeds | Present | `articles_remote_datasource.dart` | Hard-coded URLs; no credentials |
| Local persistence | Present | `shared_preferences` only; no database | Settings, bookmarks, Khatma, caches, and **coordinates in plain storage** |
| Bundled content | Present | `assets/*`, `content_manifest.json` | All four manifest SHA-256 values match the current files; approval metadata is `pending_owner_review` |
| Firebase Analytics and Crashlytics | Present, opt-in | `monitoring_service.dart`, `monitoring_gateway.dart`, `firebase_options.dart` | Active only when `APP_ENV=production` or `ENABLE_FIREBASE_MONITORING=true`. Consent defaults to off (`monitoring_service.dart:34`). Native auto-collection is off in the manifest and plist. Only the error type and stack are sent |
| Firebase config files | Present on Android | `android/app/google-services.json`, `lib/firebase_options.dart` (both tracked) | Contain Firebase client configuration; values not reproduced. iOS has only `GoogleService-Info.plist.placeholder` |
| Local notifications | Present | `notification_service.dart`, `flutter_local_notifications` | Android channels and exact alarms |
| Background work | Present | `workmanager_service.dart`, `BootReceiver.kt` | No credentials |
| Location and compass | Present | `geolocator`, native channels | Android fine and coarse location; iOS when-in-use |
| Authentication | **Absent by design** | `docs/APP_SCOPE_AND_AUTH.md` | No login code found |
| Payments or subscriptions | **Absent** | No package or code | None |
| Remote push (FCM) | **Absent** | `docs/RELEASE_REQUIREMENTS.md` says it was removed; no package in `pubspec.yaml` | None |
| Deep links | **Absent** | Only MAIN/LAUNCHER intent filter; no URL scheme or associated domains found | The README's "deep links" means in-app notification routing |

**Permissions declared**
- **Android** (`AndroidManifest.xml:3-26`): `INTERNET`, `ACCESS_NETWORK_STATE`, coarse and fine location, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `FOREGROUND_SERVICE`, `WAKE_LOCK`.
- **iOS** (`Info.plist`): `NSLocationWhenInUseUsageDescription` and background mode `fetch`.

**Files that may contain secrets (contents not reproduced)**

| Path | Tracked | Risk |
| --- | --- | --- |
| `.env` | No (ignored; never committed under that name) | Holds the YouTube key; **the same key is in public history**, see F1 |
| `updated_development_plan.md` (history only) | Removed | Source of F1 |
| `android/app/google-services.json` | Yes | Firebase client config, including an API-key-format value |
| `lib/firebase_options.dart` | Yes | Same, for several platforms |
| `android/key.properties`, `*.jks`, `*.keystore` | No | Ignored; none found locally within the shallow search |

---

## 5. Dependencies and platform configuration

### Toolchain

| Item | Value | Source |
| --- | --- | --- |
| Dart constraint | `^3.8.0` | `pubspec.yaml:22` |
| Flutter constraint | None declared | `pubspec.yaml` |
| Lockfile effective minimums | Dart `>=3.13.0`, Flutter `>=3.44.0` | `pubspec.lock` |
| CI and local SDK | `3.48.0-0.5.pre`, **beta** channel | workflows, `.dart_tool/version` |
| Version management | No `.fvmrc` or `.tool-versions` | Repository root |

The declared `^3.8.0` understates what the lockfile requires. The README also presents `^3.8.0` as the *Flutter* version. A fresh contributor could pick an SDK that cannot resolve these dependencies.

### Key dependencies

Versions come from `pubspec.lock`.

| Package | Version | Observed use |
| --- | --- | --- |
| `provider`, `get_it` | 6.1.5+1, 7.7.0 | State and DI |
| `go_router` | 17.5.0 | Routing |
| `http`, `connectivity_plus` | 1.6.0, 5.0.2 | Network and connectivity |
| `shared_preferences` | 2.5.5 | All persistence |
| `flutter_local_notifications`, `timezone`, `flutter_timezone` | 18.0.1, 0.9.4, 4.1.1 | Reminders |
| `workmanager` (`_android`, `_apple`) | 0.9.3 (0.9.3, 0.9.6) | Background rescheduling |
| `geolocator` | 14.0.2 (exact pin) | Location |
| `firebase_core`, `firebase_crashlytics`, `firebase_analytics` | 3.15.2, 4.3.10, 11.6.0 (last two exact pins) | Opt-in monitoring |
| `url_launcher`, `share_plus` | 6.3.2, 12.0.2 | External media, sharing |
| `google_fonts` | 6.3.3 | Imported by two `lib` files, alongside bundled Cairo and Amiri |

### Worth investigating (not an upgrade recommendation)

- **`curved_navigation_bar` and `dartz`:** No `lib/` imports were found. Both look removable after checking.
- **`workmanager`:** `pubspec.yaml` allows `^0.9.0+3`, and the native keys in `BootReceiver.kt` no longer match the resolved plugin. This package's internals are not a safe thing to depend on directly (F3).
- **`flutter_lints ^3.0.0`:** Changing it can surface many new lints in one go. Treat any bump as its own change.
- **Broad upgrades are not recommended now.** The Firebase, notification, and WorkManager plugins touch native configuration, and their behavior can only be properly checked on devices. There is no device evidence yet, so a mass upgrade could not be validated.

### Android

| Item | Value |
| --- | --- |
| Namespace and application ID | `com.example.sakina_app` (`build.gradle.kts:26,43`) |
| Toolchain | AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, Java 17 |
| SDK levels | `compileSdk` and `targetSdk` from Flutter; `minSdk = maxOf(21, flutter.minSdkVersion)` |
| Flavors | None; runtime profile only through `APP_ENV` dart-define |
| Signing | `android/key.properties`; a release task fails without it, and debug signing is refused (`build.gradle.kts:19-23`) |
| Shrinking | Not explicitly configured |
| Native code | `MainActivity.kt`, `QiblaCompass.kt`, `BootReceiver.kt` |

### iOS

| Item | Value |
| --- | --- |
| Bundle ID | `com.example.quranApp`, **different from Android** |
| Deployment target | 13.0 |
| Signing | Automatic; no `DEVELOPMENT_TEAM` value found in `project.pbxproj` |
| Podfile | None tracked, and `ios/.gitignore` does not ignore one; no Swift Package reference in the project file |
| Firebase | Placeholder plist only |
| Native code | `AppDelegate.swift` holds the compass and WorkManager callback |

### Firebase project alignment

- Android and iOS options share one project, and `google-services.json` and `firebase.json` match it.
- Web, macOS, and Windows options point to a **second** project.
- Android's Firebase package matches its application ID, and Dart's `iosBundleId` matches Xcode. Both are `com.example.*` values.

---

## 6. Tests and delivery workflow

### Tests

There are **53 `*_test.dart` files under `test/`** with 266 test declarations by static count; loops can create more at run time. Numbers quoted in repository documents conflict: 220 tests with 3 failures on 2026-09-28 in `docs/production-fix-progress.md`, and 311 passing on 2026-09-29 in `docs/DEVELOPMENT_PLAN_AUDIT.md`. Neither covers the last commit, `ab686ba`, and neither was reproduced here.

| Type | Files | Coverage |
| --- | --- | --- |
| Unit and provider | Many | Prayer repository, replenishment and scheduler, media cache, Khatma model and locator, Quran search, monitoring, preference schema, settings, environment parsing, notification coordinator and provider |
| Widget | Many | Most main screens, RTL direction, tooltips, offline media |
| Golden | 1 | `settings_golden_test.dart`, light and dark; Windows-only baselines, skipped elsewhere |
| Integration | 5 | Smoke, Duas, prayer, Quran, and `production_flow_test.dart`; **none runs in CI** |
| Python gate tests | 1 | `scripts/tests/test_release_gates.py` |
| Native | `ios/RunnerTests` only (template-level, body not read) | No Android native tests tracked |

### Critical flows against test coverage

| Critical flow | Gap |
| --- | --- |
| First-run routing | No test file references `SplashScreen`. Onboarding tests **pre-seed** `has_seen_notification_permission` (`onboarding_screen_test.dart:16`), which hides F2 |
| Boot and background rescheduling | Nothing references `BootReceiver` or `callbackDispatcher`. `PrayerReplenishmentService` itself is tested |
| Notification tap | `NotificationRouter` is tested; the real tap handler and closed-app launch path are not |
| Startup failure | Only `integration_test/production_flow_test.dart` references `AppInitializer`, and not for failure |
| Exact alarm, timezone, reboot, and permission behavior | Needs devices; `docs/RELEASE_REQUIREMENTS.md` lists it as outstanding |
| Religious content | Hash integrity only; authenticity is deliberately out of scope for the script |

### Lint, formatting, and CI

- **Linting:** `analysis_options.yaml` includes `flutter_lints`. It **excludes the four `reader_*` part files**, so a large part of the Quran reader is not analyzed.
- **`flutter-quality.yml`** (PRs and pushes to `main`): format check, `verify_content.py`, gate unit tests, `flutter analyze`, `flutter test`, debug APK build, plus a Windows job for goldens.
- **`release-readiness.yml`** (tags `v*` and manual): the same quality checks plus `verify_release.py` and `verify_content.py --require-approved`. It builds **no release artifact**. It is designed to fail until identity and content approvals exist.
- **No deployment pipeline** was found (no Fastlane, store upload, or signing in CI).
- **Environment setup:** `.env.example` plus `--dart-define-from-file=.env`, and `android/key.properties` for release signing.

---

## 7. Findings, risks, and unknowns

### High priority

**F1. API key exposed in public git history — Confirmed, Exposure**
- Commits `1b31792` and `cbe5823` (both 2026-09-28) touch a Google-API-format key in `updated_development_plan.md`, a file no longer tracked.
- `1b31792` is on `origin/main`, and `gh repo view` reports the repository as **public**.
- That value is identical to the key in the current local `.env`.
- Removing the file did not remove it from history.
- *Unknown:* whether the key is still active, what restrictions it has, and whether it has been used by others. Treat it as compromised.

**F2. New users likely see onboarding on every launch, with no first-run notification prompt — Confirmed in code, Defect (runtime effect not observed)**
- Splash reads `has_seen_notification_permission` (`splash_screen.dart:57`).
- Its only production writer is `notification_permission_dialog.dart:120`, inside a widget that **nothing in `lib/` constructs**.
- `_finishOnboarding` writes `onboarding_complete` (`onboarding_screen.dart:55`), which nothing reads.
- Devices that already have the flag from an older build are not affected.
- As a result, notification permission is only requested from Settings, although prayer reminders default to enabled (`local_prayer_notification_scheduler.dart:70`).

**F3. Android `BootReceiver` job should fail in the resolved plugin — Confirmed in code, Defect (runtime effect not observed)**
- `BootReceiver.kt:29-31` writes `be.tramckrijte.workmanager.*` input keys.
- `workmanager_android` 0.9.3 reads `dev.fluttercommunity.workmanager.DART_TASK` (`BackgroundWorker.kt:35,42`) and returns `Result.failure()` when it is null.
- Partial compensation: the plugin's `ScheduledNotificationBootReceiver` restores persisted notifications, and the 12-hour periodic task should continue. Real-device behavior needs testing.

**F4. Notification tap from a terminated app likely does not navigate — absence Confirmed, effect Likely, Defect**
- `notification_service.dart` never calls `getNotificationAppLaunchDetails`, and only `onDidReceiveNotificationResponse` is registered (line 137).
- The launch would then follow the normal splash flow rather than opening the target screen.
- `docs/RELEASE_REQUIREMENTS.md` already lists a terminated-app tap as required device evidence.

**F5. Required startup failure results in no UI — Confirmed, Defect**
- `AppInitializer.initialize` logs "app will continue in degraded mode" (`app_initializer.dart:69`) and then rethrows (line 74).
- `main.dart:19` has no catch, so `runApp` is not reached.
- This affects DI, SharedPreferences, and the preference migration. Firebase, notification, and WorkManager failures are caught separately.
- No fallback error screen exists.

**F6. Release identity is unresolved — Confirmed, Maintenance (known release blocker)**
- Android uses `com.example.sakina_app` and iOS uses `com.example.quranApp`.
- iOS has no real Firebase plist, and content approval is pending.
- `scripts/verify_release.py` and `verify_content.py --require-approved` will block as designed.
- Changing the IDs later also means re-creating the Firebase app configuration. Do it before any store release.

**F7. CI and development pin a pre-release Flutter — Confirmed, Maintenance**
- `3.48.0-0.5.pre` on the beta channel is used by all CI jobs.
- `docs/RELEASE_REQUIREMENTS.md:17` itself says a production SDK must still be chosen.
- `AppDelegate.swift` uses `FlutterImplicitEngineDelegate`, and the lockfile needs Flutter `>=3.44.0`, so moving SDK may require native adjustments.

### Medium priority

**F8. `production_flow_test.dart` contradicts the current UI — Confirmed in code, Defect in the test**
- Line 23 expects one `NavigationBar`. `lib/` builds none, and `main_navigation_shell_test.dart:42` expects none.
- It is expected to fail if run. CI would not catch this because integration tests are not run there.

**F9. iOS background replenishment probably will not work as configured — Likely, Defect**
- `Info.plist` has `fetch` but no `BGTaskSchedulerPermittedIdentifiers`, and `AppDelegate.swift` registers no task identifiers.
- The Dart code calls `registerPeriodicTask` and `registerOneOffTask` on all platforms and swallows errors.
- If so, iOS prayer reminders would stop after the scheduled window unless the app is opened. Needs a device test.

**F10. Android manifest settings that may affect store review or privacy — Confirmed settings, effect Likely, Suspicion**
- `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM` are both declared. Google Play restricts `USE_EXACT_ALARM` to qualifying app types, so check current policy.
- `FOREGROUND_SERVICE` is declared, but the manifest declares no app-owned service. It may be unneeded, or needed by a plugin.
- `MainActivity` has `showWhenLocked` and `turnScreenOn` (lines 45-46), so the app's UI may be reachable over the lock screen.
- `fullScreenIntent: true` is used (`notification_service.dart:437,615`), but `USE_FULL_SCREEN_INTENT` is not declared.

**F11. iOS location text is too narrow — Confirmed, Defect (store and privacy)**
- `Info.plist:33` says location is used on the Qibla screen, but `useDeviceLocation` also uses it for prayer times.

**F12. Monitoring documentation disagrees with code — Confirmed, Defect (documentation)**
- `docs/RELEASE_REQUIREMENTS.md` says monitoring is disabled unless `ENABLE_FIREBASE_MONITORING=true`.
- `app_environment.dart:42` also enables it for any `APP_ENV=production` build.
- User consent is still required, so data collection stays opt-in.

**F13. Wrong-timezone fallback for reminders — Confirmed path, runtime frequency Unknown, Defect**
- If `FlutterTimezone` fails, `notification_service.dart:171` sets `Africa/Cairo`, so daily reminders outside that zone would fire at the wrong time.
- Prayer times are not affected in the same way because they use the API timezone.

**F14. `.env` starts with a UTF-8 BOM — BOM Confirmed, effect Likely, Defect**
- The first bytes are `EF BB BF`, and the first key is on the first line.
- With `--dart-define-from-file`, the key name may be misread, leaving `YOUTUBE_API_KEY` empty and the video screen showing a missing-key error.

**F15. Resume can trigger more background work than intended — Confirmed path, Maintenance**
- Each resume with a saved location calls `refresh()`. That reschedules and registers a one-off job with source `manual_settings_update`, which bypasses the background throttle (`workmanager_service.dart:71`).
- Prayer caching and the 20-second guard limit the cost.
- `fetchPrayerTimes` also clears `_prayerTimes`, so the UI may briefly show a loading state on each resume.

**F16. Quran JSON decoded in several places on the main isolate — Confirmed code, performance effect Likely, Maintenance**
- The 2.7 MB `quran_master.json` is loaded separately by `LocalQuranDataSource`, `LocalSurahDataSource`, the reader, and `KhatmaQuranLocator`. No `compute` or isolate was seen on these paths.
- Measure on a low-end device before changing anything.

### Lower priority

| ID | Finding | Certainty, kind |
| --- | --- | --- |
| F17 | **Likely dead code:** `NavigationHandler` duplicates `notification_handler.dart`; `QuranVersesDataSource` targets a nonexistent `assets/ayaat`; `SecurityUtils` is used only by `EnhancedErrorHandler`, which appears unused; `GetAllSurahsUsecase`, `PrayerTimesPerformanceWidget`, and `PlaceholderScreen` also show no external use. Symbol search can miss indirect use, so verify with the analyzer before removing | Likely, Maintenance |
| F18 | **Large files:** `home_screen.dart` (1,305 lines), `surah_details_screen.dart` (1,257 plus parts), `notification_service.dart` (1,066), `local_surah_data_source.dart` (1,070) | Confirmed, Maintenance |
| F19 | **Analyzer exclusion** of the four `reader_*` files hides issues in a critical screen | Confirmed, Maintenance |
| F20 | **Prayer cache growth:** per-day, per-location keys in SharedPreferences. `clearCache` is not on the repository interface, and no caller was found | Confirmed, Maintenance |
| F21 | **Local coordinate storage:** coordinates are unencrypted and backup is not explicitly disabled. Check against the privacy policy draft | Likely, Suspicion |
| F22 | **RSS parsed by regular expression:** fragile against feed format changes | Confirmed, Maintenance |
| F23 | **Stray repo items:** `android/build/reports/problems/problems-report.html` is tracked; `pubspec.yaml` description is still "A new Flutter project."; the README mentions AR/EN although only Arabic exists; `domain/Entities` has inconsistent casing | Confirmed, Maintenance |
| F24 | **Stale document references:** docs refer to `AUDIT_REPORT.md` and `updated_development_plan.md`, which are no longer tracked, so it is unclear which plan is authoritative | Confirmed, Maintenance |
| F25 | **`BootReceiver` is `exported="true"`:** it only reacts to specific actions, but consider whether export is needed | Confirmed, Suspicion |
| F26 | **Duplicate plugin registration on iOS:** `AppDelegate.swift:13,27` registers in both `didFinishLaunching` and the implicit-engine callback. Effect not determinable here | Unknown, Suspicion |

### Things that cannot be determined from the repository

- **Build health:** Whether the current revision builds or passes tests. No CI results were inspected.
- **iOS build setup:** Whether the app builds without a tracked Podfile, and how Firebase links. No macOS build evidence exists.
- **Device behavior:** Actual notification, exact-alarm, reboot, and OEM behavior.
- **External services:** YouTube quota and API restrictions, Firebase console state, and the reliability and terms of use of RSS, mp3quran, and AlAdhan.
- **Content:** Whether bundled Quran, hadith, and adhkar text is authentic and licensed. The manifest shows approval as pending.
- **Fonts:** Whether `google_fonts` fetches fonts at runtime in release builds. This was not traced.
- **Publication:** Whether the app has already shipped. This changes how identifiers can be migrated.

---

## 8. Questions for you

In order of how much the answer affects future work:

1. **Is this app already published anywhere, under any ID?** This determines whether identifiers can simply change or need a migration, and whether F2 affects real users.
2. **What is the goal: a public store release, a personal or portfolio app, or further feature work?** Release means the identity, signing, and device-evidence gates come first; otherwise much of that can wait.
3. **Which platforms matter?** Android only would remove F9 and the iOS gates from the near term.
4. **Is the repository meant to be public?** This affects how to handle F1, tracked Firebase config, and the missing license.
5. **Was the skipped first-run permission dialog intentional?** The answer decides whether the F2 fix should restore the dialog or just use one onboarding flag.
6. **Who approves the religious content and prayer calculation policy?** The release gate cannot pass without named sources and a reviewer. The app currently offers three methods, defaulting to the Egyptian method.
7. **Should monitoring ship at all?** If not, removing Firebase would simplify configuration and privacy disclosures.
8. **Is external-only media the intended experience?** This shapes whether audio playback, the YouTube key, and RSS parsing deserve investment.
9. **Which Flutter version do you want to standardize on?** Beta is workable for development but should be a conscious choice for release.
10. **Which plan document is authoritative?** The candidates are `DEVELOPMENT_PLAN.md`, `docs/DEVELOPMENT_PLAN_AUDIT.md`, and `docs/production-fix-progress.md`.

---

## 9. Recommended next step

**Revoke the exposed YouTube API key and issue a replacement (F1).**

In the Google Cloud console, revoke the key, create a new one limited to the YouTube Data API and to your app identifiers where practical, review recent usage, and update your local `.env`.

- **Why this first:** It is the only finding with an active external risk, and it does not depend on any product decision.
- **Why it is low risk:** It needs no change to tracked files. In the worst case, the video screen shows its existing missing-key error until the new key is in place.
- **What it leaves for later:** Rewriting git history is a separate, disruptive decision, and it is not needed to make the old key useless. Any key compiled into a client can still be extracted, so restrictions matter even after rotation.

This step was not carried out as part of the review.

---

## 10. Remediation status (2026-11-03)

Sections 1–9 are the original review and are unchanged. This section records what happened next. The changes are uncommitted on top of `ab686ba`; file deletions and renames are staged, and everything else is unstaged.

**"Fixed" means the repository change is made and checked as listed below. It does not mean the behavior was seen on a device.** No phone, emulator, or iOS build was used.

### Corrections to the original review

| Finding | Correction |
| --- | --- |
| F14 | **Not a defect on this toolchain.** A local check showed Dart's UTF-8 decoding drops the BOM, and Flutter's `.env` key pattern also accepts a leading BOM. `.env` was left untouched |
| F19, section 2, section 6 | The four `reader_*` files were **not part of the reader**. They were `part of` a library that never declared them, so they were never compiled. The real reader is `surah_details_screen.dart` alone |
| New: F27 | **iOS periodic runs would do nothing.** The iOS plugin passes the task's unique name to Dart, and `callbackDispatcher` only handled `reschedule_alarms`. The run was logged as unknown and reported as success |
| New: F28 | **`FOREGROUND_SERVICE_LOCATION` reaches the merged manifest** from `geolocator_android`, although the app sets no `foregroundNotificationConfig`. This may need a Play Console declaration |

### Status by finding

| ID | Status | What changed | Evidence |
| --- | --- | --- | --- |
| F1 | **Partially fixed; rotation blocked on you** | Added `scripts/check_secrets.dart` to both CI workflows; it reports only file, line, and rule. Removed unused `QURAN_API_KEY` and `PRAYER_API_KEY` | Scan passes; `test/scripts/check_secrets_test.dart`. The key stays in public history until revoked |
| F2 | **Fixed** | Added `first_run_state.dart`. Splash now reads `onboarding_complete` and still honors the older flag. Onboarding stays free of permission prompts, as existing tests require; the existing dialog now appears once, after a prayer location first loads | `splash_screen_test.dart`, `notification_permission_prompt_test.dart` |
| F3 | **Fixed; device check needed** | `BootReceiver` uses the plugin's `DART_TASK_KEY` and `PAYLOAD_PREFIX`, so a future rename fails at compile time | Debug APK compiled; `native_config_test.dart` |
| F4 | **Fixed; device check needed** | `deliverLaunchNotification()` reads the launch details. `NotificationRouter` holds taps until splash has routed, then delivers them. A held tap is dropped if the user still needs onboarding | `notification_launch_test.dart`, `splash_screen_test.dart` |
| F5 | **Fixed** | `startApp` shows `StartupFailureApp` with retry. `setupServiceLocator` resets first, so a retry cannot fail on earlier registrations. The misleading log text is gone | `app_startup_test.dart` |
| F6 | **Blocked on you** | No change | See "Decisions and actions needed" |
| F7 | **Partially fixed; SDK choice blocked** | Declared `flutter: ">=3.44.0"` and corrected the README. CI still pins beta. The Dart `^3.8.0` floor was kept because raising it changes language version behavior | Analyzer and tests pass |
| F8 | **Fixed in code; not verified by running** | Removed the `NavigationBar` expectation | The test failed while loading on `-d windows`, before any test code ran. Needs a device run |
| F9 | **Fixed in code; not compiled or device-tested** | Added `BGTaskSchedulerPermittedIdentifiers` and a launch-time handler in `AppDelegate.swift` | `native_config_test.dart` is a static check only. Needs a Mac build |
| F10 | **Partially fixed; policy blocked** | Removed the app's `FOREGROUND_SERVICE` line (WorkManager still provides it), `showWhenLocked`, `turnScreenOn`, and `fullScreenIntent`. `USE_EXACT_ALARM` is unchanged | Merged manifest inspected; reminders no longer attempt full-screen display |
| F11 | **Fixed; wording needs your review** | Location text now covers Qibla and prayer times. `docs/PRIVACY_AND_CONTENT.md` updated | `Info.plist` |
| F12 | **Fixed** | Corrected `RELEASE_REQUIREMENTS.md` and `PRIVACY_AND_CONTENT.md` | Matches `app_environment.dart:42` |
| F13 | **Fixed** | `fallbackLocationForOffset` matches the device's UTC offset instead of assuming Cairo. A future DST change can still differ until the timezone resolves | `local_timezone_fallback_test.dart` |
| F14 | **No change needed** | See corrections above | Local check |
| F15 | **Fixed** | Added `refreshIfNeeded()` for resume. Fresh timings cause no fetch, rescheduling, or loading state. Explicit `refresh()` is unchanged | `prayer_refresh_if_needed_test.dart` |
| F16 | **Deferred** | No change; the review said to measure first | Needs a low-end device profile |
| F17 | **Fixed** | Removed the eight unreferenced files, plus the unused `dartz` and `curved_navigation_bar`. `path` is now only a transitive dependency. Lockfile: removals and that one dependency-type change, no version changes | Analyzer clean; tests pass |
| F18 | **Deferred** | No change; splitting these files is the unrelated refactor you asked to avoid | None |
| F19 | **Fixed** | Removed the exclusions and the four orphaned files | Analyzer clean with nothing excluded from `lib` |
| F20 | **Fixed** | Saving timings removes dated cache entries older than two days and never the entry just written | `prayer_times_repository_impl_test.dart` |
| F21 | **Blocked on your decision** | No change | See "Decisions and actions needed" |
| F22 | **Deferred** | No change; a real XML parser means adding a dependency | Existing feed tests remain |
| F23 | **Fixed** | Untracked the Gradle report and ignored `android/build`, updated the `pubspec.yaml` description, corrected the README, and renamed `domain/Entities` to `domain/entities` | Analyzer clean |
| F24 | **Partially fixed** | The README now says the two old files exist only in git history. Historical documents were not rewritten | Which plan is authoritative remains your call |
| F25 | **Fixed; device check needed** | `BootReceiver` is `exported="false"`, matching the plugin's own boot receiver | Merged manifest; `native_config_test.dart` |
| F26 | **Fixed in code; not compiled** | Removed the extra registration, matching the Flutter SDK's current iOS template | `native_config_test.dart` |
| F27 | **Fixed in code; device check needed** | `callbackDispatcher` also handles the periodic unique name | Compiles; analyzer clean. The private dispatcher has no direct test |
| F28 | **Blocked on policy check** | No change | See below |

### Checks run

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | No issues |
| `dart format --output=none --set-exit-if-changed lib test integration_test scripts/check_secrets.dart` | No changes needed |
| `dart run scripts/check_secrets.dart` | Passed |
| `flutter test` on `test/scripts`, `test/core`, `test/platform`, `test/features/splash`, `onboarding`, `prayers`, `settings`, and `test/widget_test.dart` | 144 passed (includes the settings goldens) |
| `flutter test test/features/quran test/features/khatma` | 75 passed |
| `flutter build apk --debug --no-pub` | Built; compiles the Kotlin changes |
| `flutter gen-l10n`, `flutter pub get --offline` | Completed; no versions changed |
| `flutter test integration_test/production_flow_test.dart -d windows` | **Failed while loading**, before any test code ran. Cause not investigated |
| `python3 -m unittest discover -s scripts/tests`, `scripts/verify_*.py` | **Not run**: no Python on this machine. Those scripts were not changed |
| Remaining `test/` folders (`duas`, `hadeath`, `media`, `l10n`) | Not run; their code was not changed |

### Rotating the exposed key (F1)

Do this in the Google Cloud console, in the project that owns the key:

1. Open **APIs & Services → Enabled APIs → YouTube Data API v3 → Metrics** and look for usage you don't recognize.
2. Open **APIs & Services → Credentials → Create credentials → API key** to create the replacement.
3. Edit the new key and set **API restrictions → Restrict key → YouTube Data API v3**.
4. Leave **Application restrictions** off for now. The app calls the REST API with plain `http` and does not send the `X-Android-Package` and `X-Android-Cert` headers, so an Android-app restriction would likely return 403. Consider a lower daily quota under **Quotas** instead.
5. Put the new key in your local `.env`, run with `--dart-define-from-file=.env`, and confirm the video screen loads.
6. Back in **Credentials**, **delete the old key**. Any older build containing it stops loading videos.

Until step 6, the key in public history still works. Deleting the key is what ends the exposure; rewriting history is optional and was not done. Any key compiled into a client can still be extracted, so a backend proxy is the only full protection if that risk ever matters.

### Decisions and actions needed

| Finding | What's needed | Why |
| --- | --- | --- |
| F6 | Final Android application ID and iOS bundle ID | Both are `com.example.*` and differ. Changing them after publishing means shipping a new app |
| F6 | Android keystore plus `android/key.properties`; Apple team and provisioning | Release builds are blocked without signing |
| F6 | Firebase apps registered for the final IDs, a real `GoogleService-Info.plist`, regenerated `firebase_options.dart`, and one project across platforms | Web, macOS, and Windows use a second project |
| F6 | Named sources, licenses, and a reviewer in `content_manifest.json` | `verify_content.py --require-approved` blocks until then |
| F7 | The Flutter version to release on | CI pins a pre-release; moving may require native changes |
| F10 | Whether Sakina qualifies for `USE_EXACT_ALARM` under current Play policy | If not, remove it and rely on `SCHEDULE_EXACT_ALARM`, plus handling for when that access is denied |
| F11 | Review of the Arabic location text | It is user-facing and store-visible |
| F21 | Keep Android backup or disable it | Disabling keeps coordinates out of backups, but users lose bookmarks and Khatma progress when restoring a device |
| F24 | Which plan document is authoritative | Three candidates remain |
| F28 | Keep or remove `FOREGROUND_SERVICE_LOCATION` | Removing it should be safe because no foreground location is configured, but test Qibla and prayer location on a device |

### Device verification needed

**Android**
- Fresh install: onboarding appears once, and is skipped on the next launch.
- Upgrade from an older build: goes straight to home.
- Permission dialog appears once after the first location loads, then allow and deny both behave.
- Reboot and app update: the `reschedule_alarms` job succeeds (check Logcat) and reminders are still queued.
- Notification tap with the app foregrounded, backgrounded, and fully closed, for each reminder type. Also check the back button after a closed-app tap, because the app opens directly on the target screen.
- Reminders still alert properly on a locked screen now that full-screen display is off.
- Resume no longer flashes a loading state, and timings update after midnight.
- Force a startup failure in a debug build: the recovery screen appears and retry works.

**iOS (needs a Mac)**
- The app builds. `AppDelegate.swift` and the missing Podfile have never been compiled in this review.
- No launch crash from `BGTaskScheduler`, and plugins work with single registration.
- The periodic task runs; it can be triggered from the Xcode debugger. iOS decides when it really runs, so reminders may still lapse if the app stays closed.
- Closed-app notification taps, and the new location text in the permission prompt.

**Run on any device**
- All five `integration_test/` files, including the corrected `production_flow_test.dart`.

---

## 11. Production Readiness Audit and Remediation (2026-11-03)

Sections 1–10 are preserved as history. Where they disagree with this section, this section reflects the code as of this audit. In particular, section 10's "uncommitted on top of `ab686ba`" is out of date: that work is now in commit `cfc5f8c`.

### 11.1 Verdict

**Not production-ready.** The code is in better shape, and all automated checks that can run on this machine pass, but device behavior is unverified, iOS has never been built here, and store, identity, and content approvals are outstanding.

| Area | Status | Basis |
| --- | --- | --- |
| Repository/code | **Passing local checks; not release-approved** | Analyzer, formatter, secret scan, and 375 tests pass. Audit coverage was partial (see 11.3). GitHub CI has not been re-run on these uncommitted changes |
| Android build | **Debug builds; release not attempted** | `flutter build apk --debug` succeeded. Release needs `android/key.properties`, which does not exist |
| Android device behavior | **Unverified** | No test or scenario finished on a device in this audit |
| iOS build | **Unverified** | Needs a Mac. There is no tracked Podfile, Swift package reference, or real Firebase plist |
| iOS device behavior | **Unverified** | Needs a Mac and a device |
| Store/account/policy | **Blocked** | `com.example.*` IDs, no signing, exact-alarm eligibility and other declarations open |
| Content approval | **Blocked** | `content_manifest.json` approval is pending; no named sources or reviewer |

### 11.2 Baseline and how existing work was preserved

| Item | Value |
| --- | --- |
| Branch and commit | `main` at `cfc5f8c`, level with `origin/main` |
| Staged changes | None at the start; none added. Nothing was committed, pushed, or published |
| Existing unstaged changes | `lib/features/onboarding/presentation/screens/home_screen.dart` and `test/features/onboarding/presentation/screens/home_screen_test.dart`: drawer links replaced by a "coming soon" message, with a test |
| Preservation | A baseline diff was saved before any edit and compared after formatting and all code changes, ignoring whitespace: identical. All other edits avoid these two files |
| Host | Windows 11, Flutter `3.48.0-0.5.pre` (beta), Dart 3.14.0. No working Python (the Microsoft Store alias only). No Mac |

### 11.3 Scope and limits

- **Read in full:** startup, notification service and routing, WorkManager service, prayer provider, repository, API, scheduler and replenishment, Khatma provider and repository, Qibla controller and device service, media data sources, base API service, monitoring service, manifest, Gradle config, `Info.plist`, `AppDelegate.swift`, `BootReceiver.kt`.
- **Read in part or by targeted search:** `home_screen.dart`, `surah_details_screen.dart`, `settings_*`, `khatma_duration_screen.dart`, `khatma_model.dart`, `khatma_quran_locator.dart`, and the accessibility and navigation patterns found by search.
- **Not reviewed line by line:** `QiblaCompass.kt`, `qibla_screen.dart`, `prayer_times_screen.dart`, `prayer_location_dialog.dart`, `quran_screen.dart`, Quran data sources, Quran search internals, hadith and duas features, `DEVELOPMENT_PLAN.md`, and `web/`, `windows/`, `macos/`, `linux/`. The Phase B journeys for these are therefore **not** fully traced.
- **UI/UX:** assessed from code only. No screen was inspected visually, so contrast, RTL rendering, and layout have no visual evidence beyond the widget tests.
- **Religious content:** no text was changed or assessed for authenticity.

### 11.4 New findings

Severity reflects the effect on users or release. "Fixed" means changed in the repository and checked as listed. It does not mean seen working on a device.

| ID | Finding | Category, severity | Status | Evidence and change | Tests |
| --- | --- | --- | --- | --- | --- |
| A1 | **A 60-hizb Khatma plan ended about halfway through the Quran.** The data has 240 quarters (1 hizb = 4), but units were computed as `(quarter - 1) ~/ 2 + 1` and starts as `(unit - 1) * 2 + 1`. Hizb 60 resolved to quarter 119, Surah 18 | Confirmed defect, code. **Critical** | Fixed; see limitation | `khatma_quran_locator.dart:51,227`, `surah_details_screen.dart:210` now use 4. Checked against `assets/quran_master.json`. No text changed | `khatma_hizb_mapping_test.dart` |
| A2 | **Back after a notification tap had no page to return to.** `context.go` left one page, and target screens' back buttons call `Navigator.pop` | Confirmed defect from code, code. **High** | Fixed; needs device check | `notification_handler.dart:9` now opens the target above `/home`, also giving the system back button a home to return to | `notification_handler_test.dart`, using a test router, not the app's real screens |
| A3 | **Reminders could fail entirely when exact alarms are denied.** Scheduling always requested exact mode, and the plugin throws without access. `SCHEDULE_EXACT_ALARM` is denied by default on Android 14+, so removing `USE_EXACT_ALARM` (F10) would have broken every reminder for new installs | Confirmed defect, code and policy. **High** | Fixed; needs device check | `notification_service.dart` `scheduleModeFor`, `_androidScheduleMode` fall back to inexact timing, which can arrive late | `notification_scheduling_rules_test.dart` covers mode selection only |
| A4 | **CI fails on every push.** The secret scanner flagged its own test at `check_secrets_test.dart:21`, stopping the latest run (`cfc5f8c`) before analyze and test. The last six runs all failed; only the latest cause was inspected | Confirmed defect, test. **High** | Fixed locally; CI not re-run | Header string split so the file no longer matches | Scan passes locally. Later CI steps needing Python are unverified |
| A5 | **All prayer API requests could wait forever.** `BaseApiService` set no timeout, so its `TimeoutException` handler could not run. Non-socket `ClientException` also skipped stale fallback, and its text can include the request URL with coordinates | Confirmed defect, code. **High** | Fixed | `base_api_service.dart`: 15-second timeout, mapped to `NetworkException` | `base_api_service_test.dart` |
| A6 | **RSS feeds using numeric date offsets were likely dropped whole.** `HttpDate.parse` expects GMT and throws `HttpException`, which the code did not catch. Whether live feeds use such dates was not checked | Likely defect, code. **Medium** | Fixed | `articles_remote_datasource.dart` `_parseRfc822Date` | New case in `articles_remote_datasource_test.dart` |
| A7 | **Feed-supplied links could launch any URL scheme**, such as `intent:` or `file:`. Audio also used a throwing `Uri.parse` | Confirmed security issue, code. **Medium** | Fixed | New `core/utils/external_links.dart` allows only `http`/`https` with a host; used by all three media widgets. A rejected article or video link now shows the existing error | `external_links_test.dart` covers the helper, not the widgets |
| A8 | **Malformed or incomplete prayer responses bypassed usable cached timings**, and incomplete days were cached | Confirmed defect, code. **Medium** | Fixed | `prayer_times_repository_impl.dart`: requires all five timings; generic failures try the stale cache | `prayer_times_stale_fallback_test.dart` |
| A9 | **Khatma reminder text went stale.** Its body names the range, but finishing a wird did not reschedule it. A scheduling failure also interrupted plan creation after the plan was saved | Confirmed defect, code. **Medium** | Fixed | `khatma_provider.dart` | `khatma_reminder_lifecycle_test.dart` |
| A10 | **A Khatma reminder could be set with no permission request.** The explanation appeared only after choosing a prayer location | Confirmed defect, code. **Medium** | Fixed | `khatma_duration_screen.dart` shows the existing one-time dialog after creating a plan | No test through this screen; the dialog itself is tested |
| A11 | **Refused permission looked like success.** The switch stayed on with no explanation | Confirmed defect, UX. **Medium** | Partially fixed | `settings_controls.dart` `requestNotificationPermissionWithFeedback`, plus new Arabic text for your review | `notification_dialog_layout_test.dart` |
| A12 | **The home drawer's reminder switches never request permission** (`home_screen.dart:943-971`) | Confirmed defect, code. **Medium** | Deferred | Not changed because this file holds your in-progress edits. Call `requestNotificationPermissionWithFeedback` when enabling, as `settings_screen.dart` does | None |
| A13 | **Quick reminder toggles could race**, leaving a disabled reminder scheduled. Failures in these unawaited calls were also uncaught | Confirmed from code, code. **Medium** | Fixed | `notification_service.dart` serializes `updateAllAlarms`; `settings_provider.dart` catches and logs | Failure handling tested in `settings_provider_alarm_failure_test.dart`. Serialization has no direct test |
| A14 | **Daily reminders could fire an hour off once across a DST change**, from adding 24 hours | Confirmed defect, code. **Low** | Fixed | `nextDailyOccurrence` uses calendar arithmetic | `notification_scheduling_rules_test.dart` |
| A15 | **`initialize(requestPermissions: true)` as the first call would deadlock.** No current caller does this | Confirmed latent defect, code. **Low** | Fixed | Request moved outside the initialization future | `notification_scheduling_rules_test.dart` |
| A16 | **Wrongly typed stored values could break launch**, as typed getters throw during routing and root widget setup | Likely defect, code. **Low** | Partially fixed | `first_run_state.dart`, `prayer_times_provider.dart` constructor. `ThemeProvider`, `FavoritesProvider`, and replenishment still use typed getters | `startup_corrupted_preferences_test.dart` |
| A17 | **The permission dialog could overflow** with large text on a small screen | Likely defect, accessibility. **Low** | Fixed | Scrollable content, minimum instead of fixed button heights | `notification_dialog_layout_test.dart` at 320×480, 2× text |
| A18 | **Advertising-related permissions reach the merged manifest**: `AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_AD_ID`, and install referrer, presumably from Firebase Analytics. This matters for Play declarations and the privacy draft | Confirmed configuration, policy. **Medium** | Blocked on decision | Debug merged manifest inspected. No change | None |
| A19 | **Your in-progress home change leaves `share_plus` unused** in `lib/`, if kept. The drawer would also ship several "coming soon" items, which a store reviewer may question | Maintenance, product. **Low** | Your decision | `pubspec.yaml:57`. No change | None |
| A20 | **No iOS privacy manifest in `ios/Runner`.** Apple's page could not be read by the fetch tool, so the exact requirement is **not confirmed** from an official source here | Unknown, policy. **Medium** | Blocked | Confirm in Apple's docs and App Store Connect | None |
| A21 | **Existing hizb plans keep stored positions from the old mapping** until the next finished wird, and their progress was counted under the old mapping | Migration concern from the A1 fix. **Medium** | Decision needed if already published | Not migrated. No effect on unpublished builds | None |
| A22 | **Media caches are deleted on expiry before refetching**, so expired content is lost offline. Up to four sequential feed timeouts can also delay the article screen by about a minute | Maintenance, code. **Low** | Deferred | `cached_api_service.dart`, `articles_remote_datasource.dart` | Existing tests only |
| A23 | **No `errorBuilder` on the router.** No deep links exist, so only an internal bug could reach it | Maintenance. **Low** | Deferred | `app_router.dart` | None |

### 11.5 Prior findings, re-verified

"Fixed" is carried over only where this audit re-read the evidence.

| ID | Status | Evidence now |
| --- | --- | --- |
| F1 | **Partially fixed; see 11.13** | Key rotated and restricted by the owner. Deletion of the old key is still to be confirmed by the owner |
| F2 | Fixed; needs device verification | `first_run_state.dart`, `splash_screen.dart:59`; tests pass |
| F3 | Fixed; needs device verification | `BootReceiver.kt:60-61` uses plugin constants; compiled in the debug build |
| F4 | Fixed; needs device verification | `deliverLaunchNotification`, `NotificationRouter.hold/release`. See A2 for back behavior |
| F5 | Fixed | `app_startup.dart`, tests pass |
| F6 | **Blocked** | Unchanged |
| F7 | Partially fixed; blocked | CI still pins beta `3.48.0-0.5.pre` |
| F8 | Fixed in code; needs device verification | No `NavigationBar` reference remains in `production_flow_test.dart`. Not run |
| F9 | Fixed in code; cannot verify here | The `registerPeriodicTask(withIdentifier:earliestBeginInSeconds:)` signature exists in `workmanager_apple` 0.9.6, and the identifier is in `Info.plist`. Never compiled |
| F10 | Partially fixed; policy blocked | Merged manifest still has both exact-alarm permissions. See 11.9 |
| F11 | Fixed; wording blocked on your approval | `Info.plist:33` |
| F12 | Fixed | `docs/RELEASE_REQUIREMENTS.md:15` names both enabling flags and the opt-in. `app_environment.dart` itself was not re-read in this audit |
| F13 | Fixed | `notification_service.dart`, existing tests |
| F14 | Not reproduced | Per section 10; not re-tested |
| F15 | Fixed | `refreshIfNeeded`, `app_root.dart:82`; tests pass |
| F16 | Deferred, hypothesis | See 11.8 |
| F17 | Fixed | Removed files are absent; analyzer clean |
| F18 | Deferred | Largest: `home_screen.dart` 1,225 lines, `surah_details_screen.dart` 1,160 |
| F19 | Fixed | No reader files excluded; analyzer clean |
| F20 | Fixed | `_removeExpiredDays`; tests pass |
| F21 | **Blocked on decision** | `allowBackup` is still not set in the app manifest |
| F22 | Partially addressed, deferred | Still regex parsing. A6 fixes one fragility |
| F23 | Fixed | No `android/build` files tracked |
| F24 | Partially fixed; decision needed | Recommendation in 11.10 |
| F25 | Fixed; needs device verification | Manifest `exported="false"` |
| F26 | Fixed in code; cannot verify here | One registration remains in `AppDelegate.swift:33`, plus the background registrant callback. Never compiled |
| F27 | Fixed in code; needs device verification | `workmanager_service.dart:34-36` |
| F28 | **Blocked on policy** | Still in merged manifest. See 11.9 |

### 11.6 Critical journeys: what each kind of evidence covers

| Journey | Code reviewed | Automated tests | Still needs a device or service |
| --- | --- | --- | --- |
| First launch, onboarding | Yes | Splash, onboarding, prompt | Fresh install, upgrade |
| Quran reader, bookmarks | Partly | Screen and provider tests | Performance, restoration. Search internals not reviewed |
| Prayer times | Provider, repository, API | Offline, stale, malformed, timeout | Live AlAdhan, location, DST |
| Reminders | Yes | Mode choice, next occurrence, ID logic | Exact alarms, reboot, OEM battery limits |
| Qibla | Controller and device service; native Android not reviewed | Controller tests | Sensor accuracy, calibration |
| Khatma | Provider, repository, locator | Lifecycle, hizb mapping | Reminder delivery. Reading a full hizb range in the reader |
| Notification taps | Yes | Router, handler, launch details | Foreground, background, terminated |
| Media | Data sources, link handling | Parsing, cache, links | Live feeds, YouTube quota, new key |

### 11.7 Security and privacy

- **F1 remains the top external risk.** A key compiled into a mobile client can always be extracted. Restrictions and quotas limit the damage but do not make it secret.
- **Monitoring:** consent defaults to off and native collection is off in both platform configs. Only error type and stack are sent, and events are limited to an allowlist (`monitoring_service.dart`). A18 still affects declarations.
- **Logging:** prayer request logs exclude the query string holding coordinates. A5 removes a path where a URL could enter an exception. Four `debugPrint` calls remain; none logs coordinates directly. The RSS one logs an error object, which could include a public feed URL.
- **Location:** foreground only in Dart, no background permission declared. Coordinates are stored in plain `SharedPreferences` and may be backed up (F21).
- **Scanner limits:** `check_secrets.dart` covers tracked files for two patterns. It does not scan git history or other credential formats.
- **No secret values were printed or written.** CI log output was filtered to redact Google-format keys, and `.env` was not read.

### 11.8 Performance

| Item | Measured or inferred | Result |
| --- | --- | --- |
| `jsonDecode` of `quran_master.json` | **Measured on this desktop host only**, in the Dart VM | 95 ms first run, then 30–38 ms. Says nothing reliable about a low-end phone |
| Repeated decoding on the main isolate (F16) | Inferred | Hypothesis. Profile opening a surah on a low-end Android device in profile mode before adding isolates or caching |
| Large HTTP bodies in `SharedPreferences` | Inferred | Hypothesis. Check the prefs file size after visiting media screens, then startup time |

No optimizations were made.

### 11.9 Policy sources consulted (2026-11-03)

| Topic | What the source says | Consequence |
| --- | --- | --- |
| [Play exact alarm policy](https://support.google.com/googleplay/android-developer/answer/16558241) | `USE_EXACT_ALARM` is for alarm or timer apps and calendar apps showing event notifications, with a Play Console declaration and review | **Eligibility of a prayer-reminder app is not clear.** You decide; Google makes the final call |
| [Android 14 exact alarm change](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms) | `SCHEDULE_EXACT_ALARM` is denied by default for most new installs; apps should check and degrade gracefully | Basis for A3 |
| [Play target API requirement](https://support.google.com/googleplay/android-developer/answer/11926878) | API 36 for new apps and updates from August 31, 2026 | The merged manifest targets 36: currently met |
| [Foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types) | Types must be declared, and Play Console declarations apply when targeting Android 14+ | `FOREGROUND_SERVICE_LOCATION`, `DATA_SYNC`, and `SHORT_SERVICE` are merged in; review with F28 |
| [Apple privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) | **Could not be read** | A20 stays unconfirmed |

### 11.10 Validation

Results are from the final code state, except the search and policy steps above.

| Command | Result |
| --- | --- |
| `flutter analyze --no-pub` | **Passed:** no issues |
| `dart format --output=none --set-exit-if-changed lib test integration_test scripts/check_secrets.dart` | **Passed:** 261 files, 0 changed |
| `dart run scripts/check_secrets.dart` | **Passed.** Failed at baseline (A4) |
| `flutter test --no-pub` | **Passed:** 375. Baseline was 343 |
| `flutter build apk --debug --no-pub` | **Passed:** APK built. The output included a Kotlin Gradle plugin version warning that should be read before upgrading tools |
| `flutter gen-l10n` | Completed; only the new message was intended to change |
| `flutter test integration_test/*` on `emulator-5554` | **Not run to completion, no results.** First attempt could not start because the emulator had exited. The second was stopped by you. The third was stopped by me because your VS Code debug session was using the emulator |
| `flutter test integration_test/...` on Windows | Not re-run; failed while loading in the earlier remediation, which is not a test failure |
| `python3 scripts/verify_content.py`, `verify_release.py`, gate tests | **Not run:** no working Python. CI runs them, so CI could still fail on them. `verify_release.py` and `--require-approved` are expected to block by design |
| `flutter build apk --release`, app bundle | **Not run:** no signing config |
| iOS build | **Not run:** needs macOS |
| GitHub Actions | Not re-run; nothing was pushed |

### 11.11 Actions and decisions needed from you

Recommendations below are not applied.

| Item | Needed | Recommendation |
| --- | --- | --- |
| F1 | Revoke the YouTube key and issue a replacement, using the steps in section 10 | Do this first. History rewriting is optional, disruptive, and does not replace revocation |
| A1, A21 | Was any build with hizb plans released? | If so, I can add a migration. If not, no action |
| F6 | Publication status, final app and bundle IDs, target platforms, signing, Apple team | Choose before registering Firebase apps |
| F7 | Flutter version to release on | A stable channel release, tested before release |
| F10, A3 | Are exact prayer alarms a required feature? | Decide with Play's policy page. If you doubt eligibility, remove `USE_EXACT_ALARM`; A3 now gives a late-reminder fallback, but test it first |
| F21 | Backup scope | Keep bookmarks and Khatma progress, exclude coordinates, using rules or separate storage |
| F28, A18 | Should monitoring ship, and which permissions stay? | If there are no ads, consider removing advertising permissions, then match the privacy policy and Play Data safety form |
| F11, A11 | Approve the Arabic location text and the new permission-denied message | |
| Content | Sources, licenses, named reviewer | Also have the reviewer confirm the hizb boundaries used by A1 |
| A12, A19 | Finish or adjust your home screen change | Add the drawer permission request; remove `share_plus` if sharing stays out |
| F24 | Plan authority | `DEVELOPMENT_PLAN.md` as roadmap, this file as remediation log. No plans were changed |
| A20 | Apple privacy manifest | Confirm on the Mac build |

### 11.12 Device verification matrix

Nothing below has been verified.

| Check | Android | iOS |
| --- | --- | --- |
| All five integration tests | Required | Required |
| Fresh install and upgrade from an older build | Required | Required |
| Notification permission: grant, deny, revoke | Required, API 33+ | Required |
| Enable reminder after refusal shows the new message | Required | Required |
| Tap in foreground, background, terminated, for each type; then back to home | Required | Required |
| Locked-screen delivery | Required | Required |
| Exact access removed: reminder still arrives, possibly late | Required, with `USE_EXACT_ALARM` removed in a test build | Not applicable |
| Battery restrictions, OEM behavior | Required | Not applicable |
| Reboot and app update rescheduling (Logcat `reschedule_alarms`) | Required | Not applicable |
| Background refresh | WorkManager | `BGTaskScheduler`, debugger-triggered |
| Location and compass: grant, deny, permanent denial, no sensor | Required | Required |
| Offline: stale prayer times, media errors, recovery | Required | Required |
| Hizb Khatma: unit 60 opens at Surah 87 and completion reaches the end | Required | Required |
| Small screen, large text, TalkBack or VoiceOver, RTL | Required | Required |
| App launches at all, `AppDelegate` and plugins work | Required | **Required first** |

### 11.13 F1 follow-up: key rotation and leak prevention (2026-11-03)

No key value appears in this report. Key checks printed only lengths, match counts, HTTP status codes, and Google's error reason.

**Status**
- The owner created a replacement key restricted to YouTube Data API v3.
- The old key remains in the public history of commits `1b31792` and `cbe5823`. History was not rewritten.
- A live request with the old key returned HTTP 400 (`badRequest`). This suggests Google no longer accepts it, but **deletion is for the owner to confirm in Google Cloud**.

**Incident found during this work (A24, fixed)**
- The new key was in the working copy of the tracked `.env.example`, and `.env` still held the old key.
- It was unstaged and appears in no commit, so it was not published.
- With the owner's approval, a script moved the value into `.env` without displaying it, and `.env.example` now has an empty value.

**Prevention measures**

| Area | Change |
| --- | --- |
| Ignore rules | `.env` and `.env.*` were already ignored, except `.env.example`. Added `*.local` and `key.properties` at any depth |
| Key transport | `video_remote_datasource.dart` sends the `X-Goog-Api-Key` header instead of the `key=` query parameter. A key in the URL could reach `http.ClientException` text. No active log, monitoring, or cache path exposing it was found: the repository maps these errors to fixed messages, monitoring sends only the error type and stack, and cache keys use the search query |
| Scanner | `scripts/check_secrets.dart` covers all tracked text outside generated files, plus private keys, tracked signing and env files, and env-style secret assignments. It adds `--staged`, which reads the index. Git failure is an error, not a clean scan |
| Hook | `.githooks/pre-commit`, enabled per clone with `git config core.hooksPath .githooks` |
| CI | Both workflows already ran the scanner before analyze and test; `scripts` was added to their format checks. A history scanner was not added, because the old key would need a baseline |

**Header support:** [Google's API key guide](https://docs.cloud.google.com/docs/authentication/api-keys-use) says to use `x-goog-api-key` for REST calls and warns that the query parameter exposes keys through URL scans. The [YouTube API reference](https://developers.google.com/youtube/v3/docs) documents only the `key` parameter, so a live search request with the header was also tried: HTTP 200 with a result. If Google changes this undocumented-for-YouTube behavior, the video screen would need to return to the parameter.

**Residual risk:** any key compiled into the app can be extracted from the APK. The API restriction and a daily quota are the real protection, and a backend proxy is the only full fix if that risk ever matters. The scanner also does not read history, and it recognizes only the listed credential formats.
