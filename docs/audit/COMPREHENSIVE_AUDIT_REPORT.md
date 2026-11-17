# Sakina – Comprehensive Audit Report

Audit date: 2026-11-17 · Scope: the working tree of `main` at `ffb7bdb` **plus the uncommitted changes present at audit time** (26 modified files, untracked adhan MP3s, images and Dart files; see REPO-01).
Companion documents: [Executive summary](EXECUTIVE_SUMMARY.md) · [Feature inventory](FEATURE_INVENTORY.md) · [UI/UX](UI_UX_AUDIT.md) · [Security](SECURITY_AUDIT.md) · [Notifications](NOTIFICATIONS_AND_BACKGROUND_AUDIT.md) · [Testing](TESTING_AND_QUALITY_REPORT.md) · [Readiness checklist](PRODUCTION_READINESS_CHECKLIST.md) · [Roadmap](IMPROVEMENT_ROADMAP.md) · [Tasks](IMPLEMENTATION_TASKS.md) · [External blockers](EXTERNAL_BLOCKERS.md)

## 1. Method

- Read the source of startup, DI, routing, notifications, WorkManager, prayer calculation, Quran data, persistence, recitation, media, monitoring, Android/iOS native code and configuration, CI workflows and existing project documentation.
- Executed (Windows 11, Flutter 3.47.9 stable, Dart 3.13.7):

| Command | Result |
|---|---|
| `flutter analyze` | **No issues found** (28 s) |
| `flutter test` | **774 tests, all passed** (~4 min) |
| `flutter test --coverage` | see [Testing report](TESTING_AND_QUALITY_REPORT.md) §2 |
| `flutter pub outdated` | 12 direct and 3 dev dependencies behind; several major versions (DEP-01) |
| `flutter doctor -v` | OK except Visual Studio (Windows desktop only; irrelevant to mobile) |
| `dart run scripts/check_secrets.dart` | "No credentials found in tracked files." |
| `py -3 scripts/verify_content.py` | Integrity passed for 6 assets |
| `py -3 scripts/verify_content.py --require-approved` | **Exit 1** – all 6 collections pending owner approval (REL-01) |
| `py -3 scripts/verify_release.py` | **Exit 1** – release identity blocked (REL-03) |

- **Not executed**: release builds (not needed to audit; an existing `app-release.apk` from 2026-11-17 04:42 and `app-release.aab` from 2026-11-11 were inspected for size only), integration tests (need a device), iOS builds (no macOS host), on-device notification/adhan/reboot behaviour, screen-reader review, profiling. Every finding that depends on them is marked *Probable* or *Potential*.
- No source, configuration or dependency was modified. Temporary outputs were written only to the session scratchpad.

Severity and confidence follow the definitions in the audit brief. A finding is *Confirmed* when the cited code/config/command output shows it directly.

## 2. Architecture overview (Section A)

- **Shape**: feature-first folders (`lib/features/<feature>/{data,domain,presentation}`) with a shared `lib/core`. 236 Dart files under `lib/`, 114 test files.
- **Startup**: `main()` → `startApp()` (`lib/core/app/app_startup.dart`) → `AppInitializer.initialize()` (Firebase if monitoring configured → GetIt `setupServiceLocator()` → `PreferenceSchema.migrate` → `MonitoringService` → notifications + WorkManager) → `AppRoot`. A failed required phase shows `StartupFailureApp` with retry. Well structured.
- **State/DI**: GetIt for repositories/services; `provider` (`ChangeNotifier`) for UI state; `AppRoot` constructs ~15 providers eagerly (`app_root.dart:207-251`).
- **Navigation**: single `GoRouter` (`lib/core/navigation/app_router.dart`), `initialLocation: '/splash'`, a `ShellRoute` whose shell is now a pass-through (ARCH-04). Notification taps go through `NotificationRouter` (hold/release until splash decides) → `handleNotificationNavigation` (`go('/home')` then `push(target)`), which gives a correct back stack.
- **Data**: all user data in `SharedPreferences`; content in bundled JSON/TXT assets; recitation downloads in the app-support directory.
- **External**: api.quran.com (recitation), 4 RSS feeds, YouTube Data API (key at build time), optional Firebase Crashlytics. Prayer times are computed offline with `adhan_dart`.

Assessment: the architecture is appropriate for a local-first app of this size and is **not** a candidate for replacement. Weaknesses are local: duplicated Quran loading (PERF-01/ARCH-01), stringly-typed keys (ARCH-02), and an oversized notification service with redundant facades (ARCH-03).

## 3. Strengths observed (evidence)

- Defensive startup with retry screen (`app_startup.dart:10-34`); DI reset for retries (`service_locator.dart:69`).
- Notification tap routing deduplicates launch/response double delivery (`notification_service.dart:386-407`) and holds taps until splash routing finishes (`notification_router.dart:16-34`).
- DST-safe daily occurrence arithmetic (`notification_service.dart:349-371`); per-weekday prayer ID slots avoid cross-day replacement (`prayer_notification_ids.dart`).
- Adhan fallback when the raw sound is missing (`notification_service.dart:743-756`) and `keep.xml` resource keep rules; R8/Gson keep rules (`proguard-rules.pro`).
- Release signing guard forbids debug-signed release builds (`android/app/build.gradle.kts`, `taskGraph.whenReady`).
- Privacy-preserving crash reporting: opt-in, off by default, only `runtimeType` + stack sent (`monitoring_service.dart:112-119`).
- External links restricted to http/https with confirmation (`lib/core/utils/external_links.dart`).
- Recitation downloads use `.part` files with length check and cleanup (`recitation_repository_impl.dart:117-150`).
- CI builds a real R8 release APK on every change, scans for secrets and verifies content hashes (`.github/workflows/flutter-quality.yml`).
- 774 passing tests, clean analyzer with `unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `use_build_context_synchronously` enabled.

## 4. Findings

Index (most severe first). Task column links to [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md).

| ID | Sev. | Conf. | Title | Task |
|---|---|---|---|---|
| REL-01 | CRITICAL | Confirmed | Religious content not approved for release | P0-01 |
| REL-02 | CRITICAL | Confirmed | Adhan recording redistribution rights unverified | P0-02 |
| REL-03 | CRITICAL | Confirmed | Release identity gate fails (IDs, Firebase config) | P0-03 |
| NOTIF-01 | HIGH | Probable | Foreground and background isolates reschedule the same notifications concurrently | P0-05 |
| NOTIF-03 | HIGH | Confirmed | iOS: prayer alerts lapse after 3 days without app launch; no adhan audio | P2-01 |
| PLAT-I-01 | HIGH | Confirmed | iOS target never built or verified | P7-01 |
| REPO-01 | MEDIUM | Confirmed | Large uncommitted change set, incl. untracked assets referenced by code | P0-04 |
| NOTIF-02 | MEDIUM | Probable | Timezone / clock changes are not handled | P1-05 |
| NOTIF-04 | MEDIUM | Probable | iOS one-off WorkManager tasks are not permitted identifiers | P2-02 |
| NOTIF-05 | MEDIUM | Confirmed | Adhan uses the notification audio stream (muted by silent mode/DND) | P2-03 |
| PERF-01 | MEDIUM | Confirmed | 2.7 MB Quran JSON decoded on the UI isolate, repeatedly, in 5 places | P1-01 |
| ARCH-01 | MEDIUM | Confirmed | Silent hard-coded fallback masks a broken Quran asset | P1-02 |
| ARCH-02 | MEDIUM | Confirmed | Prayer and route logic keyed on localized Arabic display strings | P1-03 |
| OBS-01 | MEDIUM | Confirmed | No error capture unless crash reporting is opted in; background failures invisible | P1-04 |
| SEC-01 | MEDIUM | Confirmed | YouTube API key compiled into the binary | P5-01 |
| PRAY-01 | MEDIUM | Confirmed | Only 3 calculation methods; no per-prayer adjustments | P2-04 |
| PRAY-02 | MEDIUM | Potential | Bundled IANA timezone database may be stale | P2-06 |
| CONT-01 | MEDIUM | Confirmed | Religious content hard-coded in Dart, outside the integrity gate | P2-05 |
| DEP-01 | MEDIUM | Confirmed | Core plugins several major versions behind | P5-06 – P5-10 |
| TEST-01 | MEDIUM | Confirmed | Background reschedule path and BootReceiver have no tests | P6-01 |
| TEST-02 | MEDIUM | Confirmed | Integration tests never run in CI | P6-02 |
| PLAT-I-02 | MEDIUM | Probable | No app privacy manifest (`PrivacyInfo.xcprivacy`) | P5-03 |
| UX-01 | MEDIUM | Potential | No visual / screen-reader verification in this audit; a11y review outstanding | P3-01, P3-04 |
| NOTIF-06 | LOW | Potential | Exact-alarm denial silently degrades to inexact delivery | P2-07 |
| PLAT-A-01 | LOW | Confirmed | Large release artifacts (85.9 MB APK); 13 MB of adhan audio | P4-02 |
| PLAT-A-02 | LOW | Confirmed | `ACCESS_FINE_LOCATION` declared though only medium accuracy is used | P5-02 |
| PLAT-A-03 | LOW | Confirmed | Android auto-backup implicit; no backup/data-extraction rules | P1-09 |
| PLAT-I-03 | LOW | Confirmed | No `ITSAppUsesNonExemptEncryption` key | P5-03 |
| ARCH-03 | LOW | Confirmed | 1,381-line notification service with redundant facade layers | P1-07 |
| ARCH-04 | LOW | Confirmed | Dead or no-op code and empty folders | P1-07 |
| ARCH-05 | LOW | Confirmed | Router has no localized error page | P1-06 |
| DATA-01 | LOW | Confirmed | Preference schema migration is a no-op; no user data export | P1-09 |
| DATA-02 | LOW | Confirmed | Bookmark writes are non-atomic and unvalidated; single bookmark only | P1-08 |
| DEP-02 | LOW | Confirmed | Unexplained exact pins, `intl: any`, discontinued transitive `js` | P5-10 |
| TEST-03 | LOW | Confirmed | No coverage report or threshold tracked | P6-03 |
| UX-02 | LOW | Confirmed | Splash uses hard-coded colours outside the design system | P3-02 |
| UX-03 | LOW | Probable | Some UI strings outside the ARB file | P3-03 |
| DOC-01 | LOW | Confirmed | Documentation sprawl; README out of date | P7-04 |
| CI-01 | LOW | Confirmed | CI lacks AAB build, size budget and dependency advisories | P7-02 |
| ARCH-06 | INFO | Confirmed | All app-wide providers created eagerly at startup | P4-01 |
| PLAT-A-04 | INFO | Confirmed | Media-playback foreground service needs a Play Console declaration | P7-03 |
| SEC-02 | INFO | Confirmed | Firebase client configuration is tracked; key restrictions unverified | P5-05 |
| SEC-03 | INFO | Confirmed | Third-party RSS parsed with regex (mitigated) | — |

Totals: 43 findings — 3 Critical, 3 High, 17 Medium, 16 Low, 4 Informational; 35 Confirmed, 5 Probable, 3 Potential.

---

### 4.1 Release blockers

#### REL-01 — Religious content not approved for release
- **Category**: Islamic content / Release · **Severity**: CRITICAL (release-blocking) · **Confidence**: Confirmed
- **Description**: `content_manifest.json` lists the six religious collections (`quran_master.json`, `quran_duas.json`, `prayers_data.json`, `hadeath/ahadeth.txt`, `islamic_guide.json`, `adhan_adhkar.json`) with `approvalStatus: "pending_owner_review"`, and `source`, `edition`, `license`, `reviewer`, `approvalDate`, `evidenceUrl` all null.
- **Evidence**: `py -3 scripts/verify_content.py --require-approved` → "Release requires content-owner approval: …" (exit 1). The `release-readiness.yml` workflow runs the same check, so a tagged release fails.
- **User impact**: an unverified Quran text or hadith collection is a religious-accuracy and reputational risk; the Tanzil licence (proposed source) requires attribution and forbids modification.
- **Root cause**: owner review not yet performed (external).
- **Recommendation**: complete the review in `docs/CONTENT_SOURCES_REVIEW_AR.md`; compare the Quran text against the stated Tanzil edition; fill the manifest; keep the hash gate.
- **Dependencies**: none (external reviewer). **Verification**: `verify_content.py --require-approved` exits 0.

#### REL-02 — Adhan recording redistribution rights unverified
- **Severity**: CRITICAL (release-blocking) · **Confidence**: Confirmed
- **Evidence**: `ADHAN_AUDIO_LIBRARY.md` §"Source and licence status": "Licence / redistribution rights: **pending verification**" for all four MP3s in `android/app/src/main/res/raw/`.
- **Impact**: publishing copyrighted recordings without permission risks store takedown.
- **Recommendation**: obtain written permission per recording or replace with recordings under a known licence; record it in `ADHAN_AUDIO_LIBRARY.md` and `docs/THIRD_PARTY_ASSETS.md`. Replacing audio for an existing id requires a new channel version (`AdhanVoice.channelId` `_v2`).
- **Verification**: document lists licence + evidence for each file; `test/features/prayers/adhan_voices_test.dart` passes.

#### REL-03 — Release identity gate fails
- **Severity**: CRITICAL (release-blocking) · **Confidence**: Confirmed
- **Evidence**: `py -3 scripts/verify_release.py` → RELEASE_ANDROID_ID / RELEASE_IOS_ID / RELEASE_FIREBASE_PROJECT unset; "Android applicationId differs from approved identity"; "Android Firebase project mismatch"; "Android Firebase package mismatch"; "Missing or invalid platform configuration (FileNotFoundError)". Android `applicationId = "io.github.khaledshahien.sakina"` (`android/app/build.gradle.kts`) while iOS uses `app.sakina.quran` (`ios/Runner.xcodeproj/project.pbxproj`) and `lib/firebase_options.dart` declares `iosBundleId: 'app.sakina.quran'`. `android/app/google-services.json` contains three clients (`app.sakina.quran`, `com.example.sakina_app`, `io.github.khaledshahien.sakina`). `ios/Runner/GoogleService-Info.plist` is absent (only `.placeholder`).
- **Impact**: tagged release workflow fails; if monitoring is enabled, the Dart-side `DefaultFirebaseOptions.android.appId` may belong to a different package than the shipped app, so Crashlytics data can be mis-attributed or rejected (*Probable*; verify in Firebase console).
- **Recommendation**: owner decides final identifiers (EXTERNAL_BLOCKERS B-01/B-02/B-04); regenerate `firebase_options.dart` with `flutterfire configure` for exactly those IDs; remove stale clients; set GitHub repository variables.
- **Verification**: `verify_release.py` exits 0 in CI with the variables set.

#### REPO-01 — Large uncommitted change set
- **Severity**: MEDIUM · **Confidence**: Confirmed
- **Evidence**: `git status` at audit start: 26 modified tracked files (notification service, channels, adhan settings, ARB/l10n, tests) and untracked `ADHAN_AUDIO_LIBRARY.md`, 4 `adhan_*.mp3`, 3 images in `assets/images/`, `lib/features/prayers/domain/adhan_voices.dart`, `presentation/adhan_preview_player.dart`, `adhan_voice_labels.dart`, `test/features/prayers/adhan_voices_test.dart`. Each new image name is referenced from `lib/` (1 reference each).
- **Impact**: the audited behaviour (adhan voices) exists only in this working copy; CI has never run it; a checkout/clean loses it.
- **Recommendation**: after the owner reviews the diff and tests pass, commit it on a branch (owner-authored; see project rule on commits only on green tests). **Verification**: `git status` clean; CI green on the branch.

### 4.2 Notifications and background execution (Section E)

Detailed lifecycle in [NOTIFICATIONS_AND_BACKGROUND_AUDIT.md](NOTIFICATIONS_AND_BACKGROUND_AUDIT.md).

#### NOTIF-01 — Concurrent rescheduling from two isolates
- **Severity**: HIGH · **Confidence**: Probable (code path confirmed; data loss requires device reproduction)
- **Description**: The same notification IDs are cancelled and re-created by the UI isolate and, seconds later, by a WorkManager background isolate, with no cross-isolate coordination.
- **Evidence**:
  - Every foreground prayer schedule ends with `_onScheduled` (`local_prayer_notification_scheduler.dart:107`), wired to `WorkManagerService().registerImmediateRescheduleTask()` (`service_locator.dart:204-205`), which enqueues a one-off task 3 s later (`workmanager_service.dart:253-260`).
  - Settings toggles run the foreground `updateAllAlarms` **and** `requestReschedule` (`settings_provider.dart:151-157` and siblings).
  - The background task bypasses its throttle for `source == 'manual_settings_update'` (`workmanager_service.dart:73-75`), then cancels/reschedules all daily reminders (`:87-93`) and three days of prayers (`:95-99`). Its `NotificationService` has a fresh `_lastAppliedAlarmStateSignature`, so it never skips.
  - The only serialisation (`_alarmUpdates`, `notification_service.dart:1116-1132`) is per-isolate.
- **Technical impact**: on Android, `flutter_local_notifications` persists scheduled notifications in a shared-preferences-backed list that each engine reads, modifies and writes. Two engines doing cancel+schedule concurrently can overwrite each other's list (lost entries are not re-registered after reboot) and can briefly leave a prayer cancelled. Also doubles battery/CPU work on every settings change.
- **User impact**: intermittently missing prayer or adhkar alerts, especially after reboot.
- **Recommendation**: make one owner per change: the foreground schedules and does **not** enqueue an immediate background run when it has just scheduled successfully (keep the periodic + boot tasks as safety nets); or enqueue only and let the background own scheduling. Add a persisted "scheduling generation" so a stale run aborts.
- **Verification**: unit test that a foreground schedule does not enqueue a duplicate run; device test toggling settings repeatedly then `adb shell dumpsys alarm` / pending list check, then reboot and confirm all expected IDs.

#### NOTIF-02 — Timezone and clock changes not handled
- **Severity**: MEDIUM · **Confidence**: Probable
- **Evidence**: `tz.setLocalLocation` is called once per process in `_configureLocalTimezone` (`notification_service.dart:176-196`); no `ACTION_TIMEZONE_CHANGED` / `ACTION_TIME_CHANGED` receiver exists (`AndroidManifest.xml`, `BootReceiver.kt`), and no Dart code reacts to a zone change. Daily reminders repeat with `matchDateTimeComponents: DateTimeComponents.time` in the zone used when scheduled (`notification_service.dart:556-566`).
- **Impact**: after travel, morning/evening adhkar reminders keep firing at the old zone's wall time until the next process start *and* reschedule; a long-running process keeps formatting times in the old zone. Prayer alerts use absolute instants computed for the prayer location (`prayerInstant`), so they stay correct for a saved city but a device-zone location keeps the old zone until recalculated.
- **Recommendation**: add a manifest receiver for `TIMEZONE_CHANGED`/`TIME_SET` that enqueues the existing reschedule task; on app resume compare `FlutterTimezone.getLocalTimezone()` with `tz.local.name` and reconfigure + reschedule.
- **Verification**: unit test for the resume comparison; device test changing zone in system settings.

#### NOTIF-03 — iOS prayer alerts lapse; no adhan audio on iOS
- **Severity**: HIGH (for iOS users) · **Confidence**: Confirmed (code); platform behaviour documented by Apple
- **Evidence**: `PrayerReplenishmentService(days: 3)` (`prayer_replenishment_service.dart:19`); iOS background refresh is opportunistic (`AppDelegate.swift` registers a 12 h periodic task). `ADHAN_AUDIO_LIBRARY.md` §iOS: recordings are 2–3.5 min, iOS limits notification sounds to 30 s, so iOS uses the default sound.
- **Impact**: an iOS user who does not open the app for ~3 days stops receiving prayer alerts without warning; the "adhan" mode is not an adhan on iOS.
- **Recommendation**: compute a schedule budget within the 64-pending limit (e.g. 5 prayers × N days + reminders + daily reminders) and use the maximum safe window; schedule a final "open Sakina to keep prayer alerts" notification at the end of the window; optionally ship ≤30 s adhan excerpts as `.caf` for iOS (rights permitting).
- **Verification**: unit test of the budget calculation; iOS device test with app not opened for the window length.

#### NOTIF-04 — iOS one-off WorkManager identifiers not permitted
- **Severity**: MEDIUM · **Confidence**: Probable (requires an iOS run)
- **Evidence**: `Info.plist` `BGTaskSchedulerPermittedIdentifiers` contains only `reschedule_alarms_periodic_task`; `UIBackgroundModes` has `audio`, `fetch` (no `processing`). The app also calls `registerOneOffTask` with `reschedule_alarms_boot_task` (`workmanager_service.dart:210-219`, called from `app_initializer.dart:140`) and `reschedule_alarms_boot_task_manual` (`:253-260`). On iOS, workmanager maps one-off tasks to `BGProcessingTask`s whose identifiers must be permitted.
- **Impact**: registration errors on every iOS launch (caught; `_isDegradedBoot = true`), and no immediate reschedule after settings changes on iOS.
- **Recommendation**: on iOS skip one-off registration (the foreground already schedules) or add the identifiers and `processing` mode.
- **Verification**: iOS run without the "boot reschedule unavailable" log; unit test of platform branching.

#### NOTIF-05 — Adhan routed through the notification audio stream
- **Severity**: MEDIUM · **Confidence**: Confirmed (configuration); behaviour is documented Android behaviour
- **Evidence**: `NotificationChannels.adhan()` (`notification_channels.dart:124-133`) sets `sound` and `Importance.max` but no `audioAttributesUsage`; `buildNotificationDetails` (`notification_style.dart`) sets none either; `ADHAN_AUDIO_LIBRARY.md` states the sound "follows the notification volume and Do Not Disturb".
- **Impact**: a phone on silent/vibrate or DND plays no adhan; some OEMs cut long notification sounds. This may or may not match product intent — it needs an explicit decision.
- **Recommendation**: product decision (EXTERNAL_BLOCKERS B-09). If the adhan should behave like an alarm, create `_v2` adhan channels with `AudioAttributesUsage.alarm` (channel sound attributes are immutable, so new IDs plus retirement of `_v1`), and document it. Otherwise surface the limitation in the adhan settings UI.
- **Verification**: device test in silent, vibrate and DND modes on at least Pixel + Samsung.

#### NOTIF-06 — Exact-alarm denial degrades silently
- **Severity**: LOW · **Confidence**: Potential
- **Evidence**: `scheduleModeFor` falls back to `inexactAllowWhileIdle` when exact alarms are not permitted (`notification_service.dart:314-318`); on Android 14+ `SCHEDULE_EXACT_ALARM` is not granted by default for new installs. The adhan settings expose `canScheduleExact`/`requestExact` (`app_root.dart:327-330`), but nothing re-checks after the user revokes the permission.
- **Impact**: alerts may arrive minutes late in Doze.
- **Recommendation**: re-check on resume and show a persistent hint in prayer settings when inexact.
- **Verification**: device test with permission revoked.

### 4.3 Performance (Section H)

#### PERF-01 — Quran JSON decoded on the UI isolate in five places
- **Severity**: MEDIUM · **Confidence**: Confirmed (code); jank magnitude not measured
- **Evidence**: `assets/quran_master.json` is 2.7 MB. It is loaded with `rootBundle.loadString` and `jsonDecode` on the main isolate, without a shared cache, in: `surah_details_screen.dart:541-549` (every time a surah is opened, then `firstWhere` over all surahs), `quran_search_screen.dart:55-58`, `local_surah_data_source.dart:16-19`, `local_quran_data_source.dart:12-22`, `khatma_quran_locator.dart:253-255`. No `compute`/`Isolate.run` exists in `lib/`.
- **Impact**: a multi-hundred-millisecond main-thread stall is plausible on low-end devices when opening a surah or search; repeated allocation of the full Quran.
- **Recommendation**: one `QuranTextStore` (GetIt singleton) that decodes once with `Isolate.run`, exposes indexed lookups by surah/page/juz, and is used by all five call sites.
- **Verification**: widget tests keep passing; DevTools timeline on a low-end Android device shows no frame >16 ms attributable to decode after the first load; target "surah open < 300 ms" on a mid-range device.

### 4.4 Architecture and code quality (Sections A, B)

#### ARCH-01 — Silent hard-coded fallback for Quran metadata
- **Severity**: MEDIUM · **Confidence**: Confirmed
- **Evidence**: `LocalSurahDataSource.loadAllSurahs` catches any error and returns `_generateSurahMetadata()` (`local_surah_data_source.dart:29-32`), a ~1,000-line literal list with `'ayahs': []`.
- **Impact**: a corrupt or missing asset presents an app with surah names and no verses instead of an error; the fallback duplicates religious metadata outside the integrity gate.
- **Recommendation**: remove the fallback; return a typed failure and show the existing error state; integrity is guaranteed by the content hash gate.
- **Verification**: test that a broken asset yields an error state.

#### ARCH-02 — Localized display strings used as identifiers
- **Severity**: MEDIUM · **Confidence**: Confirmed
- **Evidence**: `_prayerNotificationIdsByName` keyed by `'الفجر'…'العشاء'` (`notification_service.dart:71-77`) while the schedule map is built from `appL10n.prayerTimesWidgetMessage8..12` (`local_prayer_notification_scheduler.dart:134-138`); unknown keys are skipped with a log (`notification_service.dart:836-843`). `AppRoot._onPrayerArrived` maps back by `appL10n.prayerName(p) == prayer.name` (`app_root.dart:120-123`). Routes `/duas/morning` and `/duas/evening` pass the literal category names `'أذكار الصباح'`/`'أذكار المساء'` (`app_router.dart:219-232`).
- **Impact**: editing a translation string (or adding a locale) silently stops prayer notifications — tests would only catch it if they compare the exact strings.
- **Recommendation**: key everything by `DailyPrayer` and stable category IDs; derive display names at the edge.
- **Verification**: unit test that changes a display name in a fake localization and asserts all five prayers are still scheduled.

#### ARCH-03 — Oversized notification service and redundant facades
- **Severity**: LOW · **Confidence**: Confirmed
- **Evidence**: `notification_service.dart` is 1,381 lines (init, channels, permissions, routing, prayers, daily reminders, verse, test helpers). Scheduling is reachable through `NotificationService`, `AlarmScheduler`/`NotificationAlarmScheduler`, `NotificationSchedulingCoordinator`, `LocalNotificationGateway`/`NotificationServiceGateway`, `PrayerNotificationGateway`, `NotificationProvider`, `SettingsProvider`. `AppRoot` uses `NotificationService.instance` directly (`app_root.dart:327-334`) while GetIt also registers it (`service_locator.dart:197-199`).
- **Impact**: high regression risk on change; harder to reason about NOTIF-01.
- **Recommendation**: split into `NotificationPlatform` (plugin, channels, permissions), `PrayerAlertScheduler`, `DailyReminderScheduler`, `NotificationTapRouter`; resolve via GetIt only. Do this after P0-05 and with tests first.
- **Verification**: all notification tests pass unchanged; file sizes < 400 lines each.

#### ARCH-04 — Dead or no-op code
- **Severity**: LOW · **Confidence**: Confirmed
- **Evidence**: `MainNavigationShell.build` returns `child` and `paths` is unused outside its own test (`main_navigation_shell.dart:11-14`; `ShellRoute` at `app_router.dart:79-81`); empty `lib/core/helper_functions/` and `lib/core/testing/`; stale comment "Platform default sound until a licensed adhan is bundled" (`notification_channels.dart:70`); debug-only `NotificationProvider` test helpers used only by `NotificationTestScreen`.
- **Recommendation**: remove or document each; keep the debug screen behind `kDebugMode` as today.

#### ARCH-05 — No localized router error page
- **Severity**: LOW · **Confidence**: Confirmed
- **Evidence**: `GoRouter(...)` (`app_router.dart:75-78`) has no `errorBuilder`/`errorPageBuilder`; grep finds none.
- **Impact**: an unknown location (e.g. a stale payload) shows GoRouter's default English page.
- **Recommendation**: add an Arabic error page with "go home". **Verification**: widget test navigating to `/does-not-exist`.

#### ARCH-06 — Eager provider construction
- **Severity**: INFO · **Confidence**: Confirmed
- **Evidence**: `_initializeProviders` (`app_root.dart:207-251`) builds every app-wide provider and loads azkar and duas assets at startup.
- **Recommendation**: measure first (P4-01); make only measurable costs lazy.

### 4.5 Data and persistence (Section I)

#### DATA-01 — No-op migration; no user data export
- **Severity**: LOW · **Confidence**: Confirmed
- **Evidence**: `PreferenceSchema.migrate` only writes the version number (`preference_schema.dart:8-21`). Khatma, wird position, tasbih and adhkar progress are JSON blobs without a version field (`khatma_repository.dart`, `tasbih_repository_impl.dart`, `adhkar_progress_controller.dart`). No export/import feature exists.
- **Impact**: the first incompatible model change has no migration path; users cannot move progress between devices except through OS backup.
- **Recommendation**: add a `schema` field to each blob and a migration test fixture per released version; consider an export/import (JSON file) feature.

#### DATA-02 — Bookmark integrity
- **Severity**: LOW · **Confidence**: Confirmed
- **Evidence**: `saveBookmark` writes 3–4 keys sequentially (`bookmark_provider.dart:81-102`); `_validatedInt` accepts any integer (no 1–114 / ayah range check) (`:31-54`); only one bookmark exists.
- **Impact**: process death between writes leaves a mixed bookmark; an out-of-range value reaches the reader.
- **Recommendation**: store one JSON value atomically; validate ranges against the Quran store.

#### PLAT-A-03 — Implicit Android auto-backup
- **Severity**: LOW · **Confidence**: Confirmed
- **Evidence**: `<application>` in `AndroidManifest.xml` sets neither `android:allowBackup` nor `android:dataExtractionRules`/`fullBackupContent`, so the default (backup enabled) applies; this includes saved coordinates and the plugin's scheduled-notification cache.
- **Recommendation**: add explicit rules: include user preferences, exclude plugin caches and `last_background_reschedule_at_ms`; the privacy policy already mentions device backups.

### 4.6 Observability (Section Q)

#### OBS-01 — Errors are captured only when crash reporting is on
- **Severity**: MEDIUM · **Confidence**: Confirmed
- **Evidence**: `FlutterError.onError` / `PlatformDispatcher.onError` are installed only inside `MonitoringService.initialize`, which returns early unless `AppConfig.enableFirebaseMonitoring` (production or override) and on Android/iOS (`monitoring_service.dart:23-49`; `app_initializer.dart:55-58`); reports are sent only after the user opts in. The WorkManager isolate never initialises monitoring and only logs (`workmanager_service.dart:47-55`). `developer.log` output is not visible in release builds.
- **Impact**: notification/background failures in the field are invisible; uncaught async errors in non-production profiles go to the default handler only.
- **Recommendation**: always install handlers that write a small rotating local diagnostics log (no PII), viewable/shareable from Settings → About; record background task outcomes (last success time, last error type) in preferences and show them on the existing data/diagnostics screen.

### 4.7 Security (Section G) — summary; details in [SECURITY_AUDIT.md](SECURITY_AUDIT.md)

#### SEC-01 — YouTube API key in the binary
- **Severity**: MEDIUM · **Confidence**: Confirmed
- **Evidence**: `ApiKeys.youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY')` (`api_keys.dart:8`) injected via `--dart-define-from-file=.env` (README); sent as `X-Goog-Api-Key` header (`video_remote_datasource.dart`). `.env` is git-ignored and not tracked.
- **Impact**: anyone can extract the key from the APK and consume the quota (videos then fail for everyone).
- **Recommendation**: restrict the key in Google Cloud to the YouTube Data API **and** to the Android package + signing SHA-1 / iOS bundle ID; set a quota; or proxy via a small backend.

#### SEC-02 — Firebase client config tracked
- **Severity**: INFO · **Confidence**: Confirmed — `android/app/google-services.json` and `lib/firebase_options.dart` are tracked. These are client identifiers, not secrets; ensure API-key restrictions and remove stale clients (see REL-03).

#### SEC-03 — RSS parsed with regular expressions
- **Severity**: INFO · **Confidence**: Confirmed — `articles_remote_datasource.dart` validates the envelope, strips HTML, and links are opened only via `openWebUrl` (http/https only, confirmation). Acceptable; no code execution path.

#### PLAT-A-02 — Unneeded precise location
- **Severity**: LOW · **Confidence**: Confirmed — `ACCESS_FINE_LOCATION` is declared (`AndroidManifest.xml`) while `DevicePositionResolver` requests `LocationAccuracy.medium` (`device_position_resolver.dart:58-64`). Declare only `ACCESS_COARSE_LOCATION` (data minimisation; simpler Play data-safety answers). Verify qibla accuracy remains city-level.

### 4.8 Islamic features (Section K)

#### PRAY-01 — Limited calculation methods
- **Severity**: MEDIUM · **Confidence**: Confirmed
- **Evidence**: `PrayerCalculationPolicy.methods` = Muslim World League, Umm al-Qura, Egyptian (`prayer_calculation_policy.dart:7-18`); `_parameters` maps only those (`prayer_times_repository_impl.dart:111-118`). No per-prayer minute offsets. High-latitude rule `recommended` and polar `aqrabYaum` are set (good).
- **Impact**: users in South Asia (Karachi), North America (ISNA), Gulf (Dubai/Kuwait/Qatar), Turkey, Singapore etc. get times that differ from their local mosque.
- **Recommendation**: add the `adhan_dart` methods with stable IDs, per-prayer adjustments, and a note on Umm al-Qura's Ramadan Isha convention; religious review for defaults (EXTERNAL_BLOCKERS B-10).
- **Verification**: reference-time tests per method against published timetables.

#### PRAY-02 — Timezone database freshness
- **Severity**: MEDIUM · **Confidence**: Potential
- **Evidence**: `timezone: ^0.9.4` resolves to 0.9.4 (latest 0.11.2). Prayer wall-clock times are converted with this bundled IANA database (`prayer_times_repository_impl.dart:90-94`), as are notification instants.
- **Impact**: wrong times by one hour for regions whose DST rules changed after the bundled data.
- **Recommendation**: upgrade (with P5-07) and add a test that asserts the bundled tzdata version ≥ a minimum.

#### CONT-01 — Religious content outside the integrity gate
- **Severity**: MEDIUM · **Confidence**: Confirmed
- **Evidence**: 99 Arabic literals in `asma_al_husna_screen.dart`, 18 in `lib/features/quran/domain/daily_verses.dart`, surah metadata in `local_surah_data_source.dart`; none are covered by `content_manifest.json`/`verify_content.py`.
- **Recommendation**: move into JSON assets listed in the manifest (requires extending `REQUIRED_COLLECTIONS`) and remove the duplicates.

### 4.9 Platforms (Sections M, N)

#### PLAT-I-01 — iOS never built or verified
- **Severity**: HIGH (blocks an iOS release) · **Confidence**: Confirmed
- **Evidence**: no `ios/Podfile`; no CI job on macOS; no `DEVELOPMENT_TEAM` in `project.pbxproj`; no entitlements file; `GoogleService-Info.plist` missing; deployment target 13.0; `docs/DEVELOPMENT_PLAN_AUDIT.md` marks TASK-002 BLOCKED "Not verifiable on Windows".
- **Recommendation**: macOS build host or CI runner; `flutter build ios --release --no-codesign` in CI; then signing (external).

#### PLAT-I-02 — No app privacy manifest
- **Severity**: MEDIUM · **Confidence**: Probable — no `PrivacyInfo.xcprivacy` under `ios/`. Apple requires declared reasons for required-reason APIs (e.g. `UserDefaults` via `shared_preferences`); plugins ship their own manifests, but the app's own manifest and App Store privacy answers must be prepared. Verify with Xcode's privacy report.

#### PLAT-I-03 — Export compliance key missing
- **Severity**: LOW · **Confidence**: Confirmed — `Info.plist` lacks `ITSAppUsesNonExemptEncryption` (app uses only HTTPS → typically `false`), so every upload asks.

#### PLAT-A-01 — Artifact size
- **Severity**: LOW · **Confidence**: Confirmed — `build/app/outputs/flutter-apk/app-release.apk` 85.9 MB (universal APK); `app-release.aab` 64.5 MB (2026-11-11, before the 13 MB of adhan MP3s); `res/raw` = 13 MB (4 stereo 128–171 kbit/s MP3s). Recommend measuring Play's per-device download size, an AAB size budget in CI, and re-encoding adhan audio (e.g. mono 64–96 kbit/s) — rights permitting and with `_v2` channel IDs.

#### PLAT-A-04 — Foreground-service declaration
- **Severity**: INFO · **Confidence**: Confirmed — `FOREGROUND_SERVICE_MEDIA_PLAYBACK` + `AudioService` require the Play Console foreground-service declaration (with video). Unused FGS types are already stripped (good).

### 4.10 Dependencies (Section P)

#### DEP-01 — Major-version lag
- **Severity**: MEDIUM · **Confidence**: Confirmed (`flutter pub outdated`)

| Package | Current | Latest | Note |
|---|---|---|---|
| flutter_local_notifications | 18.0.1 | 23.0.2 | Core to the product; 5 majors behind |
| firebase_core / firebase_crashlytics | 3.15.2 / 4.3.10 | 5.2.0 / 6.1.0 | |
| workmanager | 0.9.3 | 0.10.10 | Background scheduling |
| timezone / flutter_timezone | 0.9.4 / 4.1.1 | 0.11.2 / 5.1.1 | See PRAY-02 |
| get_it / go_router | 7.7.0 / 17.5.0 | 9.3.0 / 18.1.4 | |
| flutter_lints (dev) | 3.0.2 | 6.0.0 | Newer lint set |

Recommendation: upgrade one family per task with a release build (R8/Gson rules) and device notification smoke test (P5-06 notifications, P5-07 timezone, P5-08 workmanager, P5-09 Firebase, P5-10 the rest). Do not batch.

#### DEP-02 — Pins and loose constraints
- **Severity**: LOW · **Confidence**: Confirmed — exact pins without recorded reason (`geolocator: 14.0.2`, `firebase_crashlytics: 4.3.10`, `adhan_dart: 2.0.1`), `intl: any`; transitive `js 0.6.7` is discontinued. Document reasons in `docs/DEPENDENCIES_AND_LICENSES.md` or relax.

### 4.11 Testing (Section O) — details in [TESTING_AND_QUALITY_REPORT.md](TESTING_AND_QUALITY_REPORT.md)

- **TEST-01** (MEDIUM, Confirmed): no test references `callbackDispatcher`, `_handleRescheduleAlarms` or `WorkManagerService`; `BootReceiver.kt` untested.
- **TEST-02** (MEDIUM, Confirmed): `integration_test/` (5 files) is not run by any workflow; golden tests run only on the Windows job.
- **TEST-03** (LOW, Confirmed): no coverage reporting/threshold in CI.

### 4.12 UI/UX, accessibility, localization (Sections C, L) — details in [UI_UX_AUDIT.md](UI_UX_AUDIT.md)

- **UX-01** (MEDIUM, Potential): screens were not visually inspected on a device in this audit; screen-reader review is outstanding (`DEVELOPMENT_PLAN_AUDIT.md` TASK-013 PARTIAL). Code shows 52 `Semantics` widgets, 21 semantic labels, 37 tooltips; large-text tests exist (`test/accessibility/large_text_audit_test.dart`).
- **UX-02** (LOW, Confirmed): `splash_screen.dart:85-86` hard-codes `0xFF5E3B29`/`0xFFE7C37A` regardless of the chosen design/dark mode.
- **UX-03** (LOW, Probable): Arabic literals outside ARB in UI files (`duas_screen.dart`, `onboarding_page.dart`, `surah_details_screen.dart`, `app_router.dart`) — some are content keys (ARCH-02), some may be UI text.

### 4.13 Documentation, build and CI (Sections R, S)

- **DOC-01** (LOW, Confirmed): >30 planning/audit documents at the root and in `docs/` (e.g. `DEVELOPMENT_PLAN.md` 1,484 lines, `docs/PROJECT_REVIEW.md` 803 lines, several AUDIT/PLAN pairs). README is out of date: says prayer times are fetched via API (now offline, `prayer_times_repository_impl.dart:16`), lists `lib/core/api/` (absent), says CI pins `3.48.0-0.5.pre` beta (workflow uses 3.47.9 stable), colour palette differs from `SAKINA_DESIGN_SYSTEM.md`.
- **CI-01** (LOW, Confirmed): CI builds an APK but not the AAB that is uploaded, enforces no size budget, has no dependency-advisory step and no iOS job (`flutter-quality.yml`).

## 5. Areas reviewed with no significant finding

- Startup failure handling, DI reset, notification tap deduplication and hold/release, route extra hardening (`_routeExtra`, `_routeInt`), media cache resilience, recitation download integrity, audio session configuration (`AudioSessionConfiguration.speech()`), compass sensor lifecycle on both platforms, release signing guard, R8 rules, cleartext HTTP (none in code; Android default blocks it), exported components (only those required by `audio_service` and the launcher activity), secrets in tracked files (none found by the scanner), privacy policy coverage of external services (`site/privacy.html`).
