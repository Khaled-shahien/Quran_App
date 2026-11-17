# Sakina – Testing & Quality Report

Audit date: 2026-11-17 · Host: Windows 11, Flutter 3.47.9 stable, Dart 3.13.7. Findings: [COMPREHENSIVE_AUDIT_REPORT.md](COMPREHENSIVE_AUDIT_REPORT.md) §4.11. Passing tests are not evidence of production readiness: no device, release-build or background test was executed.

## 1. Execution results

| Command | Result |
|---|---|
| `flutter analyze` | No issues found (28.0 s) |
| `flutter test` | **+774, all passed** (≈3 min 54 s). Expected log noise: RSS "feed failed" lines from offline/503 fakes |
| `flutter test --coverage` | passed; 68.4 % line coverage of instrumented files (8,812 / 12,881 lines) |
| `dart run scripts/check_secrets.dart` | pass |
| `py -3 scripts/verify_content.py` | pass (hashes) |
| `py -3 scripts/verify_content.py --require-approved` | **fail** (REL-01) |
| `py -3 scripts/verify_release.py` | **fail** (REL-03) |
| `dart format --set-exit-if-changed` | not run in this audit (CI runs it) |
| `integration_test/*` | not run (requires a device) |
| `scripts/tests` (python unittest) | not run in this audit (CI runs it) |

Coverage counts only files imported by at least one test; files never imported are absent from `lcov.info`, so the true figure is lower.

## 2. Coverage hot spots (critical paths)

| File | Lines | Coverage |
|---|---|---|
| `lib/core/services/notification_service.dart` | 478 | **19.7 %** |
| `lib/core/services/workmanager_service.dart` | 84 | **3.6 %** |
| `lib/core/navigation/app_router.dart` | 186 | 0.5 % |
| `lib/core/app/app_root.dart` | 172 | 0.6 % |
| `lib/core/audio/just_audio_recitation_engine.dart` | 90 | 0 % |
| `lib/features/prayers/presentation/screens/prayer_location_dialog.dart` | 104 | 0 % |
| `lib/features/quran/data/data_sources/local_surah_data_source.dart` | 239 | 2.9 % |
| `lib/features/onboarding/presentation/widgets/current_wird_widget.dart` | 262 | 13 % |
| `lib/features/quran/presentation/screens/surah_details_screen.dart` | 416 | 51 % |
| `lib/features/khatma/presentation/providers/khatma_provider.dart` | 191 | 53 % |
| `lib/features/prayers/presentation/providers/prayer_times_provider.dart` | 295 | 88.5 % |
| `lib/features/recitation/presentation/providers/recitation_controller.dart` | 216 | 87.5 % |
| `lib/core/services/monitoring_service.dart` | 55 | 90.9 % |

Low coverage of `notification_service.dart` is partly structural (plugin calls); its pure helpers (`nextDailyOccurrence`, `prayerNotificationContent`, routing) are tested.

## 3. Test inventory

114 test files. Areas: accessibility (2), core app/navigation/services/providers/theme/utils (~25), duas (7), hadith (5), Islamic guide (2), khatma (6), media (5), onboarding (6), prayers (11), qibla (2), quran (21, of which 12 screen tests), recitation (3), settings (4), splash, l10n, platform, scripts. 10 golden PNGs (settings goldens run on the Windows CI job). 5 integration tests (`app_smoke`, `duas_flow`, `prayer_times_flow`, `production_flow`, `quran_flow`).

Strong areas: prayer calculation reference times, alert planner, adhan voice catalogue vs files and keep rules, notification content, notification tap routing and dedupe, monitoring consent races, media cache failure matrix, Quran page fit, large-text audit, khatma reminder lifecycle.

## 4. Untested critical flows

| Flow | Gap | Task |
|---|---|---|
| Background reschedule (`callbackDispatcher`, throttle, manual bypass, failure → retry) | no test references it (TEST-01) | P6-01 |
| `BootReceiver.kt` enqueue | no Android instrumentation test | P6-01 |
| Foreground ↔ background double scheduling | not modelled (NOTIF-01) | P6-04 |
| Timezone change / manual clock change | none (NOTIF-02) | P6-04 |
| Router: every route builds; unknown route | `app_router.dart` 0.5 % | P1-06, P6-05 |
| `AppRoot` prayer-arrival banner and recitation pause | 0.6 % | P6-05 |
| Prayer location dialog (city search, manual entry validation) | 0 % | P6-05 |
| Recitation audio engine (background, interruptions) | 0 %; device only | P6-06 |
| Integration flows in CI | never executed in CI (TEST-02) | P6-02 |
| Data migration across released versions | no fixtures (DATA-01) | P1-09 |

## 5. Regression risks

- Changing ARB strings (ARCH-02) → silent loss of prayer alerts.
- Plugin upgrades (DEP-01) → release-only R8/Gson failures (already seen in this project; keep the CI release build) and channel/permission behaviour changes.
- Reworking Quran loading (PERF-01) touches reader, search, khatma and guide simultaneously.
- Adhan audio replacement without a channel version bump → old sound keeps playing.

## 6. Recommended automated tests

1. Unit: background handler with fake prefs/notification gateway/clock (P6-01).
2. Unit: scheduling ownership — foreground success does not enqueue an immediate background job (P6-04).
3. Unit: a renamed display string still schedules five prayers (after P1-03).
4. Unit: iOS pending-budget calculator (P2-01).
5. Widget: each `GoRoute` builds with no extra and with malformed extras; unknown route shows the localized error page (P6-05).
6. Widget: `PrayerLocationDialog` search, manual coordinate validation (P6-05).
7. Integration on an Android emulator in CI: the 5 existing flows (P6-02).
8. Coverage report published per PR with a non-decreasing threshold for `lib/core/services` and `lib/features/prayers` (P6-03).

## 7. Manual testing requirements

Use `docs/MANUAL_QA_CHECKLIST_AR.md` plus the device list in [NOTIFICATIONS_AND_BACKGROUND_AUDIT.md](NOTIFICATIONS_AND_BACKGROUND_AUDIT.md) §9. Every release candidate must be tested as a **signed release build**.

## 8. Device / OS matrix

| Device class | OS | Focus |
|---|---|---|
| Pixel (emulator + physical) | Android 10, 13, 14, 15/16 | exact alarms, POST_NOTIFICATIONS, Doze |
| Samsung mid-range | One UI on Android 14+ | battery optimisation, adhan length |
| Xiaomi / Redmi | MIUI/HyperOS | autostart/background kill |
| Low-end 2–3 GB RAM | Android 10–12 | reader open time (PERF-01), memory |
| Tablet | Android 13+ | layouts, landscape |
| iPhone SE / small | iOS 16–18 | layout, notifications, 64 limit |
| Recent iPhone | latest iOS | background refresh, VoiceOver |
| iPad | iPadOS | landscape |

Each with TalkBack/VoiceOver once per release, text scale 1.0 / 1.3 / 2.0, light/dark.
