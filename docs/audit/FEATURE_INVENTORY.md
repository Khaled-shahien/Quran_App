# Sakina – Feature Inventory

Audit date: 2026-11-17. Status values: **Fully Implemented**, **Implemented with Issues**, **Partially Implemented**, **Not Implemented**, **Requires Verification**. "Fully Implemented" is used only where code, tests and data flow were traced and no open finding applies; on-device behaviour was not observed in this audit (see [UI_UX_AUDIT.md](UI_UX_AUDIT.md) §1).

Finding IDs refer to [COMPREHENSIVE_AUDIT_REPORT.md](COMPREHENSIVE_AUDIT_REPORT.md); task IDs to [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md). Coverage figures come from the run in [TESTING_AND_QUALITY_REPORT.md](TESTING_AND_QUALITY_REPORT.md).

## Summary

| # | Feature | Status | Key findings |
|---|---|---|---|
| 1 | Splash & startup | Implemented with Issues | OBS-01, UX-02 |
| 2 | Onboarding & first run | Fully Implemented | — |
| 3 | Home hub & side drawer | Fully Implemented | ARCH-04 |
| 4 | Quran index & surah reader (scroll/page modes) | Implemented with Issues | PERF-01, ARCH-01, REL-01 |
| 5 | Quran search | Implemented with Issues | PERF-01 |
| 6 | Bookmark | Implemented with Issues | DATA-02 |
| 7 | Khatma / daily wird | Implemented with Issues | DATA-01, PERF-01 |
| 8 | Prayer times (offline calculation) | Implemented with Issues | PRAY-01, PRAY-02 |
| 9 | Prayer location (city list / GPS / manual) | Fully Implemented | PLAT-A-02 |
| 10 | Prayer alerts, reminders, adhan voices | Implemented with Issues | NOTIF-01..06, REL-02, ARCH-02 |
| 11 | Adhan preview | Fully Implemented (Android) | iOS: n/a by design |
| 12 | After-adhan adhkar | Fully Implemented | ARCH-02 |
| 13 | Daily reminders (morning/evening adhkar, Mulk, Baqarah, daily verse) | Implemented with Issues | NOTIF-01, NOTIF-02 |
| 14 | Khatma reminder | Fully Implemented | NOTIF-02 |
| 15 | Azkar & adhkar progress | Fully Implemented | ARCH-02 |
| 16 | Duas | Fully Implemented | REL-01 |
| 17 | Hadith | Fully Implemented | REL-01 |
| 18 | Islamic guide | Fully Implemented | REL-01 |
| 19 | Asma al-Husna | Implemented with Issues | CONT-01 |
| 20 | Tasbeeh | Fully Implemented | — |
| 21 | Qibla compass | Requires Verification | device sensors |
| 22 | Hijri / dual date with offset | Fully Implemented | — |
| 23 | Quran recitation (stream, background, downloads) | Requires Verification | device/background audio |
| 24 | Articles (RSS) | Fully Implemented | SEC-03 |
| 25 | Videos (YouTube) | Implemented with Issues | SEC-01 |
| 26 | Settings (appearance, text size, digits, designs, reminders) | Fully Implemented | — |
| 27 | Crash reporting (opt-in) | Partially Implemented | REL-03, OBS-01 |
| 28 | Data sources / licences / about | Fully Implemented | — |
| 29 | Notification test screen (debug only) | Fully Implemented | debug-only route |
| 30 | iOS platform build | Requires Verification | PLAT-I-01 |
| 31 | Multiple bookmarks / notes | Not Implemented | DATA-02 |
| 32 | Backup / export of user data | Not Implemented | DATA-01 |
| 33 | Authentication / sync | Not Implemented (by design, `docs/APP_SCOPE_AND_AUTH.md`) | — |
| 34 | Non-Arabic localization | Not Implemented (by scope; locale fixed to `ar`, `app_root.dart:353`) | — |

Counts (34 rows): Fully Implemented 16 · Implemented with Issues 10 · Partially Implemented 1 · Requires Verification 3 · Not Implemented 4 (two of them by product scope).

## Details

### 1. Splash & startup
- **Entry**: `/splash` → `SplashScreen` (`lib/features/splash/presentation/screens/splash_screen.dart`).
- **Flow**: `main()` → `startApp()` → `AppInitializer.initialize()` → `AppRoot`; splash waits for `SharedPreferences`, reads `hasCompletedOnboarding`, `go('/home' | '/onboarding')`, then `NotificationRouter.release(dropPending: !completed)`.
- **Platform**: Firebase (optional), notifications, WorkManager. **Tests**: `test/core/app/*`, `test/features/splash/*`.
- **Issues**: OBS-01 (no error capture unless monitoring is on), UX-02 (fixed colours).

### 2. Onboarding & first run
- **Entry**: `/onboarding` → `OnboardingScreen`; widgets `onboarding_page.dart`, `notification_permission_dialog.dart`.
- **State**: `first_run_state.dart` keys (`has_seen_notification_permission`). Notification permission is requested from a dialog with explanation, not at launch (`notification_permission_dialog.dart:118`).
- **Tests**: `test/features/onboarding/presentation/screens/*`.

### 3. Home hub & drawer
- **Entry**: `/home` → `HomeScreen`; `home_drawer_lists.dart` (Settings reachable only via the drawer — owner decision), `category_grid_widget.dart`, `prayer_time_header.dart`, `current_wird_widget.dart`, `daily_verse_section_widget.dart`.
- **Tests**: `home_screen_test.dart`, widget tests. Coverage: `current_wird_widget.dart` 13 %, `home_wird_sheet.dart` 0.8 %.

### 4. Quran index & reader
- **Entry**: `/quran` → `QuranScreen`; `/quran/surah/:number` → `SurahDetailsScreen` (910 lines) with `surah_reader/*` (page, text, chrome, buttons), `quran_page_layout.dart`, `reader_layout.dart`, `basmala.dart`.
- **Data**: `assets/quran_master.json` (2.7 MB), `SurahRepositoryImpl` ← `LocalSurahDataSource`; reader decodes the asset itself (`surah_details_screen.dart:541`). Fonts: AmiriQuran / Amiri (OFL).
- **Tests**: 12 screen test files under `test/features/quran/presentation/screens`, `quran_page_fit_test.dart` (every page fits 360×640 at ≥12 px). Coverage `surah_details_screen.dart` 51 %.
- **Issues**: PERF-01, ARCH-01, REL-01 (text source approval), CONT-01.

### 5. Quran search
- **Entry**: `/quran/search` → `QuranSearchScreen`; `quran_search.dart` (Arabic normalisation, Arabic/Western numerals). Offline. **Issues**: PERF-01.

### 6. Bookmark
- `BookmarkProvider` (SharedPreferences keys `bookmark_*`), opened with `openBookmark` route extra. Single bookmark. **Issues**: DATA-02.

### 7. Khatma / daily wird
- **Entry**: `/khatma`, `/khatma/location`, `/khatma/duration`; `KhatmaProvider` (411 lines), `KhatmaRepositoryImpl` (JSON in prefs), `khatma_quran_locator.dart`, `wird_reading_position.dart`; reminder id 1205.
- **Tests**: model, services, `khatma_reminder_lifecycle_test.dart`. Coverage `khatma_provider.dart` 53 %. **Issues**: DATA-01, PERF-01.

### 8. Prayer times
- **Entry**: `/prayers` → `PrayerTimesScreen`; `PrayerTimesProvider` (628 lines) → `PrayerTimesRepositoryImpl` (adhan_dart, offline) → `prayerInstant` (zone-aware).
- **Settings**: method (3 options), Asr madhab, location, timezone of chosen city. High-latitude rule = `recommended`, polar = `aqrabYaum`.
- **Tests**: repository reference-time tests, provider tests (88.5 % coverage). **Issues**: PRAY-01, PRAY-02.

### 9. Prayer location
- `prayer_location_dialog.dart` (bundled `assets/prayer_cities.json`, manual coordinates), `DevicePositionResolver` (cached ≤30 min, medium accuracy, 30 s limit). Permission requested only on "my location". Coverage `prayer_location_dialog.dart` 0 % (**untested**). **Issues**: PLAT-A-02.

### 10. Prayer alerts, reminders and adhan voices
- **UI**: `adhan_preferences.dart` (per-prayer mode: silent / notification-only / sound / adhan; per-prayer voice; reminder minutes; exact-alarm and battery guidance; test alert).
- **State**: `AdhanSettingsController` ← `AdhanSettingsStore` (prefs).
- **Logic**: `planPrayerAlerts` (`prayer_alert_planner.dart`) → `NotificationService.scheduleAllPrayersForDate` → `zonedSchedule` on channel per mode/voice (`notification_channels.dart`, `adhan_voices.dart`).
- **Background**: `PrayerReplenishmentService` (3 days) from WorkManager periodic 12 h, boot and immediate tasks; `BootReceiver.kt`.
- **Tests**: planner, voices, channels, content, scheduler tests. Coverage `notification_service.dart` 19.7 %, `workmanager_service.dart` 3.6 %.
- **Issues**: NOTIF-01..06, REL-02, ARCH-02. See [NOTIFICATIONS_AND_BACKGROUND_AUDIT.md](NOTIFICATIONS_AND_BACKGROUND_AUDIT.md).

### 11. Adhan preview
- `adhan_preview_player.dart` (just_audio, `android.resource:///raw/…`), pauses recitation first. iOS: voice row hidden by design.

### 12. After-adhan adhkar
- `/after-adhan?prayer=` → `AfterAdhanScreen` (`AdhanAdhkarRepository`, `assets/adhan_adhkar.json`); opened from prayer alert taps and from the in-app banner (`app_root.dart:119-173`). **Issues**: ARCH-02 (banner matches prayer by display name).

### 13. Daily reminders
- Morning (07:00), evening (17:30), Mulk (21:00), Baqarah (20:30), daily verse (09:00, 7 days ahead, ids 4001–4007); IDs 1001–1004. `SettingsProvider` → `NotificationSchedulingCoordinator` → `AlarmScheduler` → `NotificationService.updateAllAlarms`. **Issues**: NOTIF-01, NOTIF-02.

### 14. Khatma reminder
- `KhatmaProvider.refreshReminder()` after first frame and on resume (`app_root.dart:94-96, 178-181`). Test: `khatma_reminder_lifecycle_test.dart`.

### 15–18. Azkar, duas, hadith, Islamic guide
- Azkar: `/duas` → `AzkarScreen`, `/azkar/details`, `AzkarRepositoryImpl` (`assets/prayers_data.json`), `adhkar_progress_controller.dart`.
- Duas: `/duas/all` → `DuasScreen` (`assets/quran_duas.json`).
- Hadith: `/hadeath`, `/hadeath/details/:index` (`assets/hadeath/ahadeth.txt`).
- Guide: `/guide?section=` (`assets/islamic_guide.json`, validated by `islamic_guide_asset_test.dart`).
- All offline; all pending content approval (REL-01).

### 19. Asma al-Husna
- `/asma` → `AsmaAlHusnaScreen` with the 99 names as Dart literals. **Issues**: CONT-01.

### 20. Tasbeeh
- `/tasbeeh` → `TasbeehScreen`, `TasbihController`, `SharedPreferencesTasbihRepository`. Tests present.

### 21. Qibla
- `/qibla` → `QiblaScreen`, `QiblaController`, native `QiblaCompass` (Android rotation vector / accel+mag with declination; iOS `CLHeading.trueHeading`) on `EventChannel("sakina/qibla_heading")`. Listens only while subscribed; stops on pause. Coverage controller 90 %, `qibla_device_service.dart` 4.8 %. **Requires Verification** on physical devices (calibration, accuracy).

### 22. Hijri / dual date
- `dual_date.dart`, `hijri` package, user offset `setHijriOffsetDays` (`settings_provider.dart:52`). Tests: `date_card_widget_test.dart`.

### 23. Quran recitation
- `/recitation`, `/recitation/downloads`; `RecitationController` (402 lines), `JustAudioRecitationEngine` (audio_service + `AudioSessionConfiguration.speech()`), `QuranCdnRecitationSource` (api.quran.com, https only), downloads to app-support with `.part` files. Pauses at prayer time (`app_root.dart:130-134`). Coverage engine 0 %, controller 87.5 %. **Requires Verification**: background/lock-screen playback, interruptions, Bluetooth controls.

### 24–25. Media
- Articles: `/media/articles`, 4 RSS feeds, 15 s timeout, cache with expiry. Videos: `/media/videos`, YouTube search with key header; without a key shows a "missing key" message (`video_remote_datasource.dart:27-29`). **Issues**: SEC-01.

### 26. Settings
- `/settings` (drawer only) → `SettingsScreen`, `settings_controls.dart`, `reading_preferences.dart`; `ThemeProvider` (designs incl. dark-only), `TextSizeController`, `DigitStyleController`, `ReadingModeController`. Golden test `settings_golden_test.dart`.

### 27. Crash reporting
- `MonitoringService` (opt-in, default off, persisted consent, unsent reports deleted on opt-out). Only active when built with `APP_ENV=production` or `ENABLE_FIREBASE_MONITORING=true`. **Partially Implemented** because the Firebase identity does not match the shipping package (REL-03) and background isolates are not covered (OBS-01).

### 28–29. Data sources, licences, debug screen
- `/settings/data-sources` (reads `content_manifest.json`), `showAboutDialog` with registered OFL font licences (`main.dart:9-15`). `/settings/notification-test` exists only when `kDebugMode` (`app_router.dart:328-333`).
