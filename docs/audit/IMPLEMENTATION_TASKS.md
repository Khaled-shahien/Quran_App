# Sakina – Implementation Tasks

Execution-oriented task list for a coding agent. Task IDs are identical to [IMPROVEMENT_ROADMAP.md](IMPROVEMENT_ROADMAP.md); finding IDs refer to [COMPREHENSIVE_AUDIT_REPORT.md](COMPREHENSIVE_AUDIT_REPORT.md); blockers (`B-xx`) to [EXTERNAL_BLOCKERS.md](EXTERNAL_BLOCKERS.md).

## Global rules for every task

- One task = one branch = one reviewable change. Do not combine tasks.
- Do not upgrade dependencies, rename notification channel IDs, preference keys or adhan voice IDs unless the task says so. Channel sound/attributes are immutable on Android: changing them always needs a new channel ID and retirement of the old one.
- Settings stays reachable only from the side drawer; do not add a second path.
- Commits are authored by the repository owner; add no AI attribution lines. Commit only when the standard checks pass.
- Never use debug signing for a release build; never commit `.env`, `android/key.properties` or keystores.
- Religious text is never edited by an agent. Content changes need owner approval (B-05).

**Standard checks** (run for every task unless stated otherwise):

```bash
dart format --output=none --set-exit-if-changed lib test integration_test scripts
```
```bash
flutter analyze
```
```bash
flutter test
```

**Release-build check** (any task touching Android config, plugins, resources or notifications):

```bash
flutter build apk --release
```

---

## Phase 0 – Critical risks and release blockers

### P0-01 Record content-owner approval for religious collections
- **Objective**: make `verify_content.py --require-approved` pass. Resolves REL-01.
- **Scope**: `content_manifest.json` metadata only; no asset edits.
- **Files**: `content_manifest.json`, `docs/CONTENT_SOURCES_REVIEW_AR.md`.
- **Instructions**: wait for B-05. For each of the 6 collections fill `source`, `edition`, `license`, `reviewer`, `approvalDate` (ISO), `evidenceUrl` exactly as supplied by the owner; set `approvalStatus: "approved"` only when all six are approved. Do not change `sha256`.
- **Constraints**: never invent values; if any value is missing, stop and report.
- **Acceptance**: `py -3 scripts/verify_content.py --require-approved` exits 0; hashes unchanged.
- **Verification**: `py -3 scripts/verify_content.py --require-approved`; `python3 -m unittest discover -s scripts/tests -v`.
- **Regression tests**: existing `scripts/tests`.

### P0-02 Document adhan recording rights (or replace recordings)
- **Objective**: resolve REL-02.
- **Scope**: documentation; audio replacement only if the owner provides replacements.
- **Files**: `ADHAN_AUDIO_LIBRARY.md`, `docs/THIRD_PARTY_ASSETS.md`; if replacing: `android/app/src/main/res/raw/adhan_*.mp3`, `lib/features/prayers/domain/adhan_voices.dart`, `lib/features/prayers/presentation/adhan_voice_labels.dart`, `lib/l10n/app_ar.arb`.
- **Instructions**: record per recording the rights holder, permission evidence and date (B-06). For a replaced file with the same id, bump `channelId` to `_v2` and add the `_v1` id to `retiredChannelIds`; update size/duration and SHA-256 table.
- **Acceptance**: each recording has licence + evidence; `test/features/prayers/adhan_voices_test.dart` passes.
- **Verification**: standard checks + release-build check.
- **Regression tests**: `adhan_voices_test.dart`, `prayer_alert_planner_test.dart`.

### P0-03 Align release identity and Firebase configuration
- **Objective**: make `scripts/verify_release.py` pass. Resolves REL-03.
- **Scope**: identifiers and generated Firebase config.
- **Files**: `android/app/build.gradle.kts` (`applicationId`), `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`), `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, GitHub repository variables.
- **Instructions**: with B-01/B-02/B-04 decided, run `flutterfire configure` for exactly the approved Android and iOS IDs and project; remove obsolete clients (`com.example.sakina_app`, unused ones) from the Firebase project; set `RELEASE_ANDROID_ID`, `RELEASE_IOS_ID`, `RELEASE_FIREBASE_PROJECT` variables. Keep the Kotlin `namespace` unless the owner asks (it does not affect the store identity).
- **Constraints**: changing `applicationId` after a Play release creates a new app — confirm with the owner.
- **Acceptance**: `py -3 scripts/verify_release.py` exits 0 locally with the variables exported; release-readiness workflow green.
- **Verification**: standard checks + release-build check; `dart run scripts/check_secrets.dart`.
- **Regression tests**: `test/core/config/*`, `test/platform/*`.

### P0-04 Commit the pending adhan-voice work
- **Objective**: resolve REPO-01 so CI covers the audited code.
- **Scope**: the existing uncommitted changes only.
- **Instructions**: owner reviews `git diff` and untracked files (`ADHAN_AUDIO_LIBRARY.md`, `res/raw/adhan_*.mp3`, three `assets/images/*.png`, `adhan_voices.dart`, `adhan_preview_player.dart`, `adhan_voice_labels.dart`, `adhan_voices_test.dart`); run standard + release-build checks; commit on a feature branch; open a PR.
- **Constraints**: do not commit `build/`, `.env`, `key.properties`, `docs/header-trial/` or `docs/new-category-icons/` unless the owner wants them.
- **Acceptance**: `git status` clean apart from intentionally ignored files; CI green on the PR.

### P0-05 Make scheduling single-owner across isolates
- **Objective**: eliminate concurrent cancel/schedule of the same IDs by UI and background isolates. Resolves NOTIF-01.
- **Scope**: scheduling triggers only; keep IDs, channels and planner unchanged.
- **Files**: `lib/core/di/service_locator.dart` (`onScheduled`), `lib/features/prayers/data/services/local_prayer_notification_scheduler.dart`, `lib/core/providers/settings_provider.dart` (toggle methods), `lib/core/services/notification_scheduling_coordinator.dart`, `lib/core/services/workmanager_service.dart`.
- **Instructions**:
  1. Foreground prayer scheduling: after a successful foreground schedule, do not enqueue the immediate background task; instead schedule the next 2 days in the foreground (reuse `PrayerReplenishmentService` with the foreground scheduler) so the window is complete without the background isolate.
  2. Settings toggles: keep the foreground `updateAllAlarms`; remove the parallel `requestReschedule` call (the periodic task remains the safety net).
  3. Add a persisted `scheduling_generation` integer, incremented by every foreground schedule; the background handler reads it at start and aborts before writing if it changed (reuse the existing "settings changed" abort pattern in `prayer_replenishment_service.dart:83-95`).
  4. Keep boot and periodic tasks unchanged.
- **Constraints**: no change to notification IDs or WorkManager unique names; do not remove the 45 s throttle.
- **Acceptance**: no code path enqueues a background reschedule within 60 s of a successful foreground schedule; background run aborts when the generation changed.
- **Verification**: standard + release-build checks; device check per [NOTIFICATIONS_AND_BACKGROUND_AUDIT.md](NOTIFICATIONS_AND_BACKGROUND_AUDIT.md) §9 item 6.
- **Regression tests**: new unit tests (fake WorkManager/gateway) for (a) no enqueue after foreground success, (b) generation abort; existing `notification_scheduling_coordinator_test.dart`, `settings_provider_alarm_failure_test.dart`, prayer scheduler tests.

## Phase 1 – Core architecture and reliability

### P1-01 Shared, off-isolate Quran text store
- **Objective**: decode `assets/quran_master.json` once, off the UI isolate. Resolves PERF-01.
- **Files**: new `lib/features/quran/data/data_sources/quran_text_store.dart`; callers `surah_details_screen.dart:541`, `quran_search_screen.dart:55`, `local_surah_data_source.dart:16`, `local_quran_data_source.dart:12`, `khatma_quran_locator.dart:253`; register in `service_locator.dart`.
- **Instructions**: load the string with `rootBundle.loadString`, decode with `Isolate.run`, build immutable indexes (by surah, page, juz); expose a `Future` that completes once; inject into the five callers; keep their public APIs.
- **Constraints**: no change to the asset or its hash; preserve current ordering and fields.
- **Acceptance**: `grep -rn "quran_master.json" lib` finds only the store; all tests pass.
- **Verification**: standard checks; P4-03 for timing.
- **Regression tests**: all `test/features/quran/**`, khatma locator tests, Islamic guide tests; add a store test (114 surahs, 6,236 ayahs, single decode).

### P1-02 Remove silent surah-metadata fallback
- **Objective**: surface asset failures. Resolves ARCH-01. **Depends on**: P1-01.
- **Files**: `lib/features/quran/data/data_sources/local_surah_data_source.dart`, `SurahRepositoryImpl`.
- **Instructions**: delete `_generateSurahMetadata` and the catch-all; return `Err(StorageFailure)`; ensure the Quran screen shows the existing error state.
- **Acceptance**: a test with a corrupt asset bundle shows the error UI; file shrinks by ~1,000 lines.
- **Regression tests**: quran screen tests; new corrupt-asset test.

### P1-03 Stable identifiers instead of display strings
- **Objective**: resolves ARCH-02.
- **Files**: `notification_service.dart` (`_prayerNotificationIdsByName`, `scheduleAllPrayersForDate`), `local_prayer_notification_scheduler.dart` (`buildPrayerSchedule`), `prayer_notification_scheduler.dart` gateway signatures, `app_root.dart` (`_onPrayerArrived`), `app_router.dart` (`/duas/morning|evening`), azkar repository lookup.
- **Instructions**: change the schedule map to `Map<DailyPrayer, DateTime>`; derive names via `appL10n.prayerName(prayer)` only for content; make `NextPrayer` carry `DailyPrayer?`; give azkar categories stable ids (`morning`, `evening`) mapped in the repository.
- **Constraints**: notification payload `prayerName` stays a display string for routing compatibility, or add `prayerId` alongside (keep reading both).
- **Acceptance**: no prayer/category lookup compares localized strings.
- **Regression tests**: new test with a fake `AppLocalizations` whose prayer names differ → five prayers scheduled; planner, content and routing tests.

### P1-04 Always-on local diagnostics
- **Objective**: resolves OBS-01.
- **Files**: `lib/core/services/monitoring_service.dart`, new `lib/core/services/diagnostics_log.dart`, `app_startup.dart`/`main.dart`, `workmanager_service.dart`, settings about/data-sources screen.
- **Instructions**: install `FlutterError.onError` and `PlatformDispatcher.instance.onError` before `startApp`, always; write `runtimeType`, timestamp, short stack hash to a bounded (e.g. 50 entries) prefs list; in the background handler record `last_reschedule_ok_at` / `last_reschedule_error_type`; show both plus counts in a "diagnostics" section with a share/copy button; forward to Crashlytics only when consent is on (existing logic).
- **Constraints**: no coordinates, search text or reading history in entries.
- **Acceptance**: uncaught test error is recorded; background outcome visible in settings.
- **Regression tests**: `monitoring_service` tests; new diagnostics log tests.

### P1-05 React to timezone and clock changes
- **Objective**: resolves NOTIF-02.
- **Files**: `AndroidManifest.xml`, `BootReceiver.kt` (or new `TimeChangeReceiver.kt`), `notification_service.dart` (`_configureLocalTimezone` made re-callable), `app_root.dart` (`didChangeAppLifecycleState`).
- **Instructions**: register `android.intent.action.TIMEZONE_CHANGED` and `android.intent.action.TIME_SET` (not exported) to enqueue the existing reschedule work; on resume compare `FlutterTimezone.getLocalTimezone()` with `tz.local.name`, and if different reconfigure tz, then `updateAllAlarms` (force, bypassing the signature) and `PrayerTimesProvider.refresh()`.
- **Acceptance**: unit test of the resume comparison; device test (zone change → reminders at new local time).
- **Regression tests**: notification service tests; release-build check.

### P1-06 Localized router error page
- **Objective**: resolves ARCH-05.
- **Files**: `lib/core/navigation/app_router.dart`, `lib/l10n/app_ar.arb`.
- **Instructions**: add `errorPageBuilder` reusing `_RouteDataErrorScreen` with a "back to home" action.
- **Acceptance**: widget test navigating to `/unknown` shows the Arabic page and returns home.

### P1-07 Split the notification service; remove dead code
- **Objective**: resolves ARCH-03, ARCH-04. **Depends on**: P0-05, P6-01.
- **Files**: `lib/core/services/notification_service.dart` → `notification_platform.dart`, `prayer_alert_scheduler.dart`, `daily_reminder_scheduler.dart`, `notification_tap_router.dart`; remove redundant facades after migrating callers; `main_navigation_shell.dart` and its `ShellRoute` (or document why kept); empty `lib/core/helper_functions/`, `lib/core/testing/`; stale comment `notification_channels.dart:70`.
- **Instructions**: move code without behaviour change; resolve all through GetIt (no `NotificationService.instance` in widgets).
- **Constraints**: no ID/channel/key changes; one commit per extracted unit is acceptable within the task branch.
- **Acceptance**: each new file < 400 lines; all notification tests unchanged and passing.
- **Regression tests**: entire `test/core/services/**`, prayers and khatma tests; release-build check.

### P1-08 Atomic, validated bookmark
- **Objective**: resolves DATA-02.
- **Files**: `lib/features/quran/presentation/providers/bookmark_provider.dart`.
- **Instructions**: store a single JSON value `bookmark_v2` `{surah, ayah, page, name}` with one `setString`; on load, migrate from the legacy four keys once; validate surah 1–114 and ayah within the surah (via P1-01 store or `numberOfAyahs`).
- **Acceptance**: legacy bookmark migrates; out-of-range values are dropped.
- **Regression tests**: existing bookmark tests + migration tests.

### P1-09 Versioned stored blobs, migration fixtures, backup rules
- **Objective**: resolves DATA-01, PLAT-A-03.
- **Files**: `preference_schema.dart`, `khatma_model.dart`, `wird_reading_position.dart`, `tasbih_repository_impl.dart`, `adhkar_progress_controller.dart`, `AndroidManifest.xml`, new `android/app/src/main/res/xml/backup_rules.xml` and `data_extraction_rules.xml`.
- **Instructions**: add a `v` field to each JSON blob (default 1 when absent); add a test fixture of prefs from the current release (1.0.0+3) that must load; add backup rules excluding `flutter_local_notifications` caches and `last_background_reschedule_at_ms`.
- **Acceptance**: fixture test passes; manifest references the rules.
- **Regression tests**: `settings_provider_test`, khatma model tests; release-build check.

## Phase 2 – Core Islamic features

### P2-01 iOS prayer-alert durability
- **Objective**: resolves NOTIF-03 (iOS part).
- **Files**: `prayer_replenishment_service.dart`, `notification_service.dart`, `adhan_preferences.dart`, ARB.
- **Instructions**: on iOS compute `days = floor((64 − dailyReminders − verse − khatma − 1) / alertsPerDay)` capped at 7; schedule that many days in the foreground on each launch/resume; schedule one "open Sakina to keep prayer alerts" notification after the last scheduled day; show an iOS note in adhan settings.
- **Acceptance**: unit test proves pending count ≤ 64 for every settings combination.
- **External**: device test on iOS (B-03).

### P2-02 iOS one-off background tasks
- **Objective**: resolves NOTIF-04.
- **Files**: `workmanager_service.dart`, `app_initializer.dart`, optionally `Info.plist`.
- **Instructions**: skip `registerBootRescheduleTask` and `registerImmediateRescheduleTask` on iOS (`defaultTargetPlatform == TargetPlatform.iOS`); keep the periodic task. Do not set `_isDegradedBoot` for an intentional skip.
- **Acceptance**: unit test of the platform branch.

### P2-03 Decide and implement the adhan audio stream
- **Objective**: resolves NOTIF-05. **Depends on**: B-09 decision, P0-02.
- **Files**: `notification_channels.dart`, `adhan_voices.dart` (`channelId` → `_v2`, retire `_v1`), `notification_style.dart`, `ADHAN_AUDIO_LIBRARY.md`, `adhan_preferences.dart`.
- **Instructions**: if "alarm-like": create `_v2` channels with `audioAttributesUsage: AudioAttributesUsage.alarm`, add `_v1` ids to `retiredChannelIds`. If "notification-like": keep channels and add a visible note that silent mode/DND mute the adhan.
- **Acceptance**: documented choice; tests for channel ids/attributes updated.
- **Verification**: device test in normal/vibrate/silent/DND.

### P2-04 More calculation methods and per-prayer adjustments
- **Objective**: resolves PRAY-01. **Depends on**: B-10 for defaults.
- **Files**: `prayer_calculation_policy.dart`, `prayer_times_repository_impl.dart`, `prayer_replenishment_service.dart`, settings UI, ARB.
- **Instructions**: add methods supported by `adhan_dart` (Karachi, North America, Dubai, Kuwait, Qatar, Singapore, Turkey, Moonsighting Committee, Tehran) with new stable integer ids that do not collide with 3/4/5; add per-prayer minute offsets (−30…+30) stored per prayer; apply them in `calculate` before formatting; include them in the replenishment "settings changed" check.
- **Acceptance**: reference-time tests per method against published timetables (owner-provided references); existing saved method ids still load.

### P2-05 Move hard-coded religious content into gated assets
- **Objective**: resolves CONT-01. **Depends on**: P1-01, P1-02.
- **Files**: `asma_al_husna_screen.dart`, `lib/features/quran/domain/daily_verses.dart`, new assets, `content_manifest.json`, `scripts/verify_content.py` (`REQUIRED_COLLECTIONS`), `pubspec.yaml` assets.
- **Instructions**: copy the literals byte-for-byte into JSON assets, load them, add to the manifest with `pending_owner_review`, extend the script and its unit tests.
- **Constraints**: no text changes; diff the rendered strings in a test against the old literals before deleting them.
- **Acceptance**: `verify_content.py` lists 8 collections; screens render identical text.

### P2-06 Timezone database freshness
- **Objective**: resolves PRAY-02. **Depends on**: P5-07.
- **Instructions**: add a test that loads the bundled database and asserts a known recent rule (choose a zone whose rules changed in the newest IANA release available at implementation time) or the embedded version string ≥ the chosen minimum.
- **Acceptance**: test fails on the old package version and passes after P5-07.

### P2-07 Exact-alarm status awareness
- **Objective**: resolves NOTIF-06.
- **Files**: `adhan_settings_controller.dart`, `adhan_preferences.dart`, `app_root.dart`.
- **Instructions**: re-query `canScheduleExactAlarms` on resume; when false and any prayer is in sound/adhan mode, show a persistent hint with the existing request action; reschedule after the permission is granted.
- **Acceptance**: widget test with a fake platform toggling the permission.

## Phase 3 – UI/UX and accessibility

### P3-01 Screen-reader and accessibility pass
- **Objective**: resolves UX-01 (a11y part). **External**: B-03 devices.
- **Instructions**: TalkBack and VoiceOver walkthrough of: onboarding, home, reader (both modes), search, prayer times + adhan settings, azkar counter, tasbeeh, qibla, recitation player, settings. Fix missing labels, traversal order (`OrdinalSortKey`), touch targets < 48 dp, and reduced-motion handling; confirm `AppTextScale` multiplies rather than replaces the system scale.
- **Acceptance**: findings list with fixes merged; new semantics tests for each fixed widget.

### P3-02 Splash colours from the active design
- **Objective**: resolves UX-02.
- **Files**: `splash_screen.dart`, `app_design.dart`.
- **Acceptance**: golden or widget test for two designs; native launch theme colours match the default design.

### P3-03 Remaining UI strings into ARB
- **Objective**: resolves UX-03.
- **Instructions**: classify each Arabic literal found by `grep -rnP "[\x{0600}-\x{06FF}]" lib --include=*.dart` outside `lib/l10n` as UI text, content or identifier; move UI text into `app_ar.arb`; leave content to P2-05 and identifiers to P1-03.
- **Acceptance**: a test (in `test/l10n`) fails on new Arabic UI literals in `presentation/` outside an allow-list.

### P3-04 Visual review in light/dark and all designs
- **Objective**: resolves UX-01 (visual part).
- **Instructions**: on an emulator, capture every route at 360×640 and 800×1280, light and dark and each `AppDesign`; store under `docs/audit/screens/`; log contrast failures (WCAG AA 4.5:1 body, 3:1 large) and fix tokens.
- **Acceptance**: screenshot set committed; contrast issues fixed or ticketed.

## Phase 4 – Performance and resources

### P4-01 Startup budget
- **Objective**: resolves ARCH-06 (measure-first).
- **Instructions**: profile cold start of a release build (`flutter run --profile --trace-startup` on a mid-range Android); record time-to-first-frame; make providers lazy only where the trace shows cost (e.g. `AzkarProvider.loadAzkar`, `DuasProvider.loadDuas`).
- **Acceptance**: documented baseline and target (e.g. first frame < 1.5 s on the reference device); no regression in tests.

### P4-02 Artifact size budget and adhan audio size
- **Objective**: resolves PLAT-A-01. **Depends on**: P0-02.
- **Instructions**: record AAB size and Play per-device download estimate (`bundletool get-size total`); if rights allow, re-encode adhan MP3s (mono, 64–96 kbit/s) with owner listening approval and new `_v2` channel ids; add a size check to CI (P7-02).
- **Acceptance**: documented sizes; CI fails if AAB grows > 10 % without an explicit budget change.

### P4-03 Reader frame profiling
- **Objective**: verify PERF-01 fix. **Depends on**: P1-01.
- **Instructions**: DevTools timeline on a low-end device: open Al-Baqarah from index and from search; record worst frame and time to first verse.
- **Acceptance**: no frame > 32 ms attributable to JSON decode; time to first verse < 300 ms after the store is warm.

## Phase 5 – Security, privacy and compliance

### P5-01 Restrict the YouTube API key
- **Objective**: resolves SEC-01. **External**: B-07.
- **Instructions**: in Google Cloud restrict the key to YouTube Data API v3, Android apps (package + release SHA-1) and iOS bundle ID; set a daily quota; document in README "API keys".
- **Acceptance**: console screenshot/evidence recorded in `docs/` (no key value).

### P5-02 Drop precise location
- **Objective**: resolves PLAT-A-02.
- **Files**: `AndroidManifest.xml`.
- **Instructions**: remove `ACCESS_FINE_LOCATION`; confirm geolocator works with coarse only on Android 12+; update privacy/Data-safety text if it mentions precise location.
- **Acceptance**: device test of "my location" and qibla; release-build check.

### P5-03 iOS privacy manifest and export compliance
- **Objective**: resolves PLAT-I-02, PLAT-I-03. **Depends on**: P7-01 for verification.
- **Files**: `ios/Runner/PrivacyInfo.xcprivacy` (added to the Runner target), `ios/Runner/Info.plist`.
- **Instructions**: declare required-reason API usage of the app target (UserDefaults: `CA92.1`), no tracking, no collected data unless crash reporting opt-in (declare crash data, not linked, not tracking); add `ITSAppUsesNonExemptEncryption = false`.
- **Acceptance**: Xcode privacy report generated without missing reasons.

### P5-04 Scan git history for secrets
- **Objective**: close the "NOT VERIFIED" history check in [SECURITY_AUDIT.md](SECURITY_AUDIT.md) §9.
- **Instructions**: run a history scanner (e.g. gitleaks) locally; if anything is found, rotate the credential (B-07) before any history rewrite, and ask the owner before rewriting.
- **Acceptance**: report stored (without secret values).

### P5-05 Firebase key restrictions and stale clients
- **Objective**: resolves SEC-02. **Depends on**: P0-03.
- **Instructions**: restrict Firebase API keys to the app identifiers; remove unused Firebase apps; consider App Check for Crashlytics if available.
- **Acceptance**: console evidence recorded.

### P5-06 Upgrade flutter_local_notifications (18 → current)
- **Objective**: part of DEP-01. **Depends on**: P0-05, P6-01.
- **Instructions**: follow each major's changelog (initialization API, `zonedSchedule` signature, Android manifest receivers, desugaring); keep the R8/Gson rules; re-run all notification tests; device smoke test of every channel and tap path.
- **Acceptance**: standard + release-build checks; device checklist §9 items 1, 3, 7.

### P5-07 Upgrade timezone and flutter_timezone
- **Objective**: part of DEP-01; enables P2-06.
- **Acceptance**: prayer reference tests pass; P2-06 test passes.

### P5-08 Upgrade workmanager (0.9 → 0.10)
- **Objective**: part of DEP-01. **Depends on**: P6-01.
- **Instructions**: re-check `BootReceiver.kt` imports (`BackgroundWorker.DART_TASK_KEY`, `PAYLOAD_PREFIX`) and iOS `AppDelegate` registration API.
- **Acceptance**: release-build check; reboot device test.

### P5-09 Upgrade Firebase (core 3 → 5, crashlytics 4 → 6)
- **Objective**: part of DEP-01. **Depends on**: P0-03.
- **Acceptance**: monitoring tests pass; opt-in crash appears in console from a release build.

### P5-10 Remaining upgrades and dependency hygiene
- **Objective**: rest of DEP-01 and DEP-02.
- **Instructions**: `get_it` 7 → 9, `go_router` 17 → 18, `flutter_lints` 3 → 6 (fix new lints), `cupertino_icons`; document reasons for each exact pin (`geolocator`, `adhan_dart`, `firebase_crashlytics`) or relax them; replace `intl: any` with the SDK-compatible range.
- **Acceptance**: `flutter pub outdated` shows no avoidable major lag; reasons recorded in `docs/DEPENDENCIES_AND_LICENSES.md`.

## Phase 6 – Testing and QA

### P6-01 Tests for the background reschedule path
- **Objective**: resolves TEST-01.
- **Instructions**: extract `_handleRescheduleAlarms` dependencies (prefs, notification gateway, repository, clock) behind parameters with production defaults; test throttle, manual bypass, success timestamp, failure rethrow → `executeTask` returns false, settings-change abort.
- **Acceptance**: `workmanager_service.dart` coverage ≥ 70 %.

### P6-02 Integration tests in CI
- **Objective**: resolves TEST-02.
- **Instructions**: add a workflow job using an Android emulator action (API 34, x86_64) running `flutter test integration_test`; mark it required once stable.
- **Acceptance**: job green for 5 consecutive runs.

### P6-03 Coverage reporting
- **Objective**: resolves TEST-03.
- **Instructions**: `flutter test --coverage` in CI; publish `lcov.info` as an artifact and a summary; fail if `lib/core/services` or `lib/features/prayers` coverage drops below the current baseline.

### P6-04 Scheduling-ownership and timezone regression suite
- **Objective**: guard P0-05 and P1-05.
- **Acceptance**: tests fail if a foreground schedule enqueues an immediate background job, or if a zone change on resume does not trigger a reschedule.

### P6-05 Router, AppRoot and location-dialog widget tests
- **Objective**: cover `app_router.dart`, `app_root.dart` banner logic and `prayer_location_dialog.dart`.
- **Acceptance**: each route builds with and without extras; banner pauses recitation and opens `/after-adhan`; dialog validates coordinates.

### P6-06 Device QA matrix execution
- **Objective**: execute the matrix in [TESTING_AND_QUALITY_REPORT.md](TESTING_AND_QUALITY_REPORT.md) §8 and the notification device list. **External**: B-03.
- **Acceptance**: signed release build tested; results recorded in `docs/RELEASE_VALIDATION_MATRIX.md`.

## Phase 7 – Production and store release

### P7-01 iOS build pipeline
- **Objective**: resolves PLAT-I-01. **External**: B-02, B-03, B-08.
- **Instructions**: on macOS run `flutter build ios --release --no-codesign`; commit generated `Podfile`/SwiftPM changes; add a `macos-latest` CI job running that build; then configure signing with the owner's team.
- **Acceptance**: CI iOS job green; archive uploads to TestFlight.

### P7-02 CI: AAB build, size budget, advisories
- **Objective**: resolves CI-01.
- **Instructions**: build `flutter build appbundle --release` with the throwaway key; record size; run `flutter pub outdated --json` and fail on advisories/discontinued direct deps.
- **Acceptance**: workflow updated and green.

### P7-03 Store compliance package
- **Objective**: resolves PLAT-A-04 and store items. **External**: B-11, B-12, B-13.
- **Instructions**: Play: foreground-service (media playback) declaration with video, exact-alarm justification if asked, Data safety form (location on-device only; crash data optional), content rating, privacy URL (`site/privacy.html` published), support email; App Store: privacy nutrition labels, screenshots for required sizes.
- **Acceptance**: checklist in [PRODUCTION_READINESS_CHECKLIST.md](PRODUCTION_READINESS_CHECKLIST.md) §Store all PASS.

### P7-04 Documentation consolidation
- **Objective**: resolves DOC-01, README drift.
- **Instructions**: update README (offline prayer times, real folder tree, CI Flutter version, design palette); move superseded plans/audits into `docs/archive/` with a one-line status header (do not delete); keep `docs/audit/` as the current source of truth and link it from README.
- **Acceptance**: README statements verified against code; no two "current" plans for the same area.

### P7-05 Release candidate validation and sign-off
- **Objective**: final gate. **Depends on**: all Phase 0 tasks, P6-06, P7-03.
- **Instructions**: tag a candidate; run release-readiness workflow; execute `docs/RELEASE_VALIDATION_MATRIX.md`; owner sign-off.
- **Acceptance**: every CRITICAL/HIGH finding closed or explicitly accepted by the owner in writing.
