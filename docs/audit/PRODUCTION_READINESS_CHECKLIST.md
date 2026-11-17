# Sakina – Production Readiness Checklist

Audit date: 2026-11-17. Status: **PASS**, **FAIL**, **PARTIAL**, **NOT VERIFIED**, **NOT APPLICABLE**. Evidence refers to [COMPREHENSIVE_AUDIT_REPORT.md](COMPREHENSIVE_AUDIT_REPORT.md) findings and executed commands; actions to [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md).

| # | Area | Item | Status | Evidence | Action |
|---|---|---|---|---|---|
| 1 | Functionality | All features build and unit/widget tests pass | PASS | `flutter test`: 774 passed; `flutter analyze`: no issues | — |
| 2 | Functionality | End-to-end flows pass on a device | NOT VERIFIED | `integration_test/` not run | P6-02, P6-06 |
| 3 | Functionality | Audited code is committed | FAIL | REPO-01 | P0-04 |
| 4 | Islamic content | Content integrity hashes | PASS | `verify_content.py` | — |
| 5 | Islamic content | Content source/licence approved | FAIL | REL-01 | P0-01 |
| 6 | Islamic content | All religious text under the gate | FAIL | CONT-01 | P2-05 |
| 7 | Prayer times | Offline calculation, zone-aware, high-latitude rule | PASS | `prayer_times_repository_impl.dart` + reference tests | — |
| 8 | Prayer times | Method coverage for target regions | PARTIAL | PRAY-01 | P2-04 |
| 9 | Prayer times | Timezone data current | NOT VERIFIED | PRAY-02 | P5-07, P2-06 |
| 10 | UI/UX | Visual review light/dark on devices | NOT VERIFIED | UI_UX_AUDIT §1 | P3-04 |
| 11 | UI/UX | Large-text and page-fit automated checks | PASS | `large_text_audit_test.dart`, `quran_page_fit_test.dart` | — |
| 12 | Accessibility | Screen-reader walkthrough | NOT VERIFIED | UX-01 | P3-01 |
| 13 | Localization | Arabic RTL throughout | PASS | locale `ar` (`app_root.dart:353`) | — |
| 14 | Localization | Logic independent of display strings | FAIL | ARCH-02 | P1-03 |
| 15 | Security | No secrets in tracked files | PASS | `check_secrets.dart` | — |
| 16 | Security | No secrets in git history | NOT VERIFIED | not scanned | P5-04 |
| 17 | Security | HTTPS only / cleartext blocked | PASS | SECURITY_AUDIT §4 | — |
| 18 | Security | API keys restricted | NOT VERIFIED | SEC-01, SEC-02 | P5-01, P5-05 |
| 19 | Privacy | Privacy policy drafted and accurate | PARTIAL | `site/privacy.html` (publication unverified) | P7-03 |
| 20 | Privacy | Crash reporting opt-in, PII-free | PASS | `monitoring_service.dart` | — |
| 21 | Privacy | Backup rules explicit | FAIL | PLAT-A-03 | P1-09 |
| 22 | Permissions | Minimal set | PARTIAL | PLAT-A-02 (FINE location) | P5-02 |
| 23 | Permissions | Requested in context, not at launch | PASS | notification dialog; location on demand | — |
| 24 | Permissions | Denial handled | PASS (code) / NOT VERIFIED (device) | inexact fallback; location errors | P6-06 |
| 25 | Notifications | Stable IDs, no collisions | PASS | NOTIFICATIONS §2 | — |
| 26 | Notifications | No concurrent rescheduling | FAIL | NOTIF-01 | P0-05 |
| 27 | Notifications | Timezone/clock change handling | FAIL | NOTIF-02 | P1-05 |
| 28 | Notifications | Delivery after reboot | NOT VERIFIED | code present (`BootReceiver.kt`) | P6-06 |
| 29 | Notifications | Adhan audio behaviour matches product intent | NOT VERIFIED | NOTIF-05, B-09 | P2-03 |
| 30 | Notifications | iOS durability | FAIL | NOTIF-03 | P2-01 |
| 31 | Background | WorkManager path tested | FAIL | TEST-01 | P6-01 |
| 32 | Background | iOS background task identifiers | FAIL | NOTIF-04 | P2-02 |
| 33 | Performance | Startup measured against a budget | NOT VERIFIED | ARCH-06 | P4-01 |
| 34 | Performance | No heavy work on UI isolate in reader | FAIL | PERF-01 | P1-01, P4-03 |
| 35 | Performance | Artifact size budget | PARTIAL | APK 85.9 MB, AAB 64.5 MB (pre-adhan) | P4-02, P7-02 |
| 36 | Data integrity | Corrupt stored values tolerated | PASS | validated reads (bookmark, khatma `Result`) | — |
| 37 | Data integrity | Versioned migration path | PARTIAL | DATA-01 | P1-09 |
| 38 | Data integrity | Atomic writes for multi-key records | FAIL | DATA-02 | P1-08 |
| 39 | Android | Release build compiles with R8 | PASS (CI design) / NOT VERIFIED (this audit) | CI step; local `app-release.apk` 2026-11-17 | — |
| 40 | Android | Release signing configured, debug signing forbidden | PASS | gradle guard; local `key.properties` | B-08 |
| 41 | Android | Store identity approved | FAIL | REL-03 | P0-03 |
| 42 | Android | targetSdk current | PASS | `flutter.targetSdkVersion` (Flutter 3.47.9) | — |
| 43 | iOS | Builds and archives | NOT VERIFIED | PLAT-I-01 | P7-01 |
| 44 | iOS | Privacy manifest / export compliance | FAIL | PLAT-I-02, PLAT-I-03 | P5-03 |
| 45 | iOS | Location usage string present | PASS | `Info.plist` | — |
| 46 | Testing | Coverage tracked | FAIL | TEST-03 (68.4 % local run) | P6-03 |
| 47 | Testing | Integration tests in CI | FAIL | TEST-02 | P6-02 |
| 48 | Crash monitoring | Production identity matches app | FAIL | REL-03 | P0-03 |
| 49 | Crash monitoring | Background failures observable | FAIL | OBS-01 | P1-04 |
| 50 | Store | Play FGS declaration, Data safety, rating | NOT VERIFIED | PLAT-A-04, B-13 | P7-03 |
| 51 | Store | Listing text and screenshots | PARTIAL | `docs/STORE_LISTING_AR.md`, `store/` | P7-03 |
| 52 | Store | Adhan audio rights | FAIL | REL-02 | P0-02 |
| 53 | Signing | Play App Signing / upload key backup | NOT VERIFIED | B-08 | P7-05 |
| 54 | Release builds | AAB built and tested in CI | FAIL | CI-01 | P7-02 |
| 55 | Release builds | Release identity gate | FAIL | `verify_release.py` exit 1 | P0-03 |
| 56 | Documentation | README accurate | FAIL | DOC-01 | P7-04 |
| 57 | Documentation | Release/QA procedures documented | PASS | `docs/RELEASE_VALIDATION_MATRIX.md`, `docs/MANUAL_QA_CHECKLIST_AR.md`, `docs/PLAY_CONSOLE_GUIDE_AR.md` | — |
| 58 | Authentication | Accounts/session security | NOT APPLICABLE | local-only scope (`docs/APP_SCOPE_AND_AUTH.md`) | — |
| 59 | Backend | Own API security | NOT APPLICABLE | no backend | — |

Tally (59 items): PASS 17 · FAIL 22 · PARTIAL 6 · NOT VERIFIED 12 · NOT APPLICABLE 2 — rows with a dual status (24, 39) are counted under PASS. Full release readiness requires every FAIL fixed or explicitly accepted by the owner.
