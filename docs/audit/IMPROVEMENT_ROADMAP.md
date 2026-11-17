# Sakina – Improvement Roadmap

Audit date: 2026-11-17. Ordered by the brief's priority rules (security/privacy → data integrity → stability → core Islamic features → notifications → platforms → UX → performance → maintainability → cosmetics) and by dependencies. Task IDs match [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md), which holds the full implementation steps, constraints and verification commands for each task. Findings: [COMPREHENSIVE_AUDIT_REPORT.md](COMPREHENSIVE_AUDIT_REPORT.md). External items (`B-xx`): [EXTERNAL_BLOCKERS.md](EXTERNAL_BLOCKERS.md).

Priority scale: **P-Must** (required for a public release), **P-High** (next after blockers), **P-Medium**, **P-Low**. Complexity: Small (≤ 1 day), Medium (2–4 days), Large (≥ 1 week), for one experienced developer — estimates, not commitments.

## Dependency overview

```
P0-04 ─► (all code tasks run on a clean, committed base)
P0-05 ─► P6-04, P1-07, P5-06, P5-08
P6-01 ─► P1-07, P5-06, P5-08
P1-01 ─► P1-02 ─► P2-05 ; P1-01 ─► P4-03 ; P1-01 ─► P1-08 (range validation)
P0-02 ─► P2-03, P4-02            B-09 ─► P2-03          B-10 ─► P2-04
P0-03 ─► P5-05, P5-09            P5-07 ─► P2-06
P7-01 ─► P5-03 verification, P2-01 device verification
Everything in Phase 0 + P6-06 + P7-03 ─► P7-05
```

---

## Phase 0 – Critical risks and release blockers

| ID | Title | Priority | Severity addressed | Affected features | Relevant files | Dependencies | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P0-01 | Record content-owner approval | P-Must | CRITICAL (REL-01) | Quran, duas, azkar, hadith, guide, after-adhan | `content_manifest.json` | — | Small (agent) | B-05 |
| P0-02 | Adhan recording rights | P-Must | CRITICAL (REL-02) | Adhan alerts, preview | `ADHAN_AUDIO_LIBRARY.md`, `res/raw/adhan_*` | — | Small–Medium | B-06 |
| P0-03 | Align release identity & Firebase | P-Must | CRITICAL (REL-03) | Build, crash reporting | `build.gradle.kts`, `project.pbxproj`, `firebase_options.dart`, `google-services.json` | — | Small | B-01, B-02, B-04 |
| P0-04 | Commit pending adhan-voice work | P-Must | MEDIUM (REPO-01) | Adhan voices | working tree | — | Small | owner review |
| P0-05 | Single-owner scheduling across isolates | P-Must | HIGH (NOTIF-01) | All notifications | `service_locator.dart`, `local_prayer_notification_scheduler.dart`, `settings_provider.dart`, `workmanager_service.dart` | P0-04 | Medium | device for final check |

| ID | Description & key steps | Acceptance criteria | Required tests | Expected outcome |
|---|---|---|---|---|
| P0-01 | Fill source/edition/licence/reviewer/date/evidence for 6 collections from the owner's review; never invent values | `verify_content.py --require-approved` exits 0 | `scripts/tests` | Release workflow content gate passes |
| P0-02 | Record permission per recording or replace files (new `_v2` channel ids if replaced) | Licence + evidence per file | `adhan_voices_test.dart` | Legally distributable adhan |
| P0-03 | Decide IDs, `flutterfire configure`, remove stale clients, set CI variables | `verify_release.py` exits 0 | config/platform tests + release build | Consistent identity; Crashlytics attributable |
| P0-04 | Review diff, run checks, commit on branch, PR | Clean `git status`; CI green | full suite + release build | CI covers adhan voices |
| P0-05 | Foreground schedules the full window itself; remove parallel background enqueue on toggles; persisted scheduling generation aborts stale background runs | No background enqueue within 60 s of a foreground schedule; stale run aborts | new ownership tests; existing scheduler/coordinator tests | No lost/duplicated alerts from races |

## Phase 1 – Core architecture and reliability

| ID | Title | Priority | Severity | Features | Files | Deps | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P1-01 | Shared off-isolate Quran store | P-High | MEDIUM (PERF-01) | Reader, search, khatma, guide | new `quran_text_store.dart` + 5 callers | P0-04 | Medium | — |
| P1-02 | Remove silent metadata fallback | P-High | MEDIUM (ARCH-01) | Quran index | `local_surah_data_source.dart` | P1-01 | Small | — |
| P1-03 | Stable prayer/category identifiers | P-High | MEDIUM (ARCH-02) | Prayer alerts, banner, azkar routes | `notification_service.dart`, `local_prayer_notification_scheduler.dart`, `app_root.dart`, `app_router.dart` | P0-05 | Medium | — |
| P1-04 | Always-on local diagnostics | P-High | MEDIUM (OBS-01) | Startup, background, settings | `monitoring_service.dart`, new `diagnostics_log.dart`, `workmanager_service.dart` | — | Medium | — |
| P1-05 | React to timezone/clock changes | P-High | MEDIUM (NOTIF-02) | Daily reminders, prayer times | `AndroidManifest.xml`, receiver, `notification_service.dart`, `app_root.dart` | P0-05 | Medium | device |
| P1-06 | Localized router error page | P-Medium | LOW (ARCH-05) | Navigation | `app_router.dart` | — | Small | — |
| P1-07 | Split notification service; remove dead code | P-Medium | LOW (ARCH-03, ARCH-04) | Notifications | `notification_service.dart`, facades, `main_navigation_shell.dart` | P0-05, P6-01 | Large | — |
| P1-08 | Atomic validated bookmark | P-Medium | LOW (DATA-02) | Bookmark | `bookmark_provider.dart` | P1-01 | Small | — |
| P1-09 | Versioned blobs, migration fixtures, backup rules | P-Medium | LOW (DATA-01, PLAT-A-03) | Khatma, tasbih, adhkar progress, backup | models, `preference_schema.dart`, manifest + xml | — | Medium | — |

| ID | Description & key steps | Acceptance | Tests | Outcome |
|---|---|---|---|---|
| P1-01 | Decode once with `Isolate.run`, index by surah/page/juz, inject everywhere | Only the store references the asset | store test + all Quran/khatma tests | No repeated main-thread decode |
| P1-02 | Return typed failure, show error state | Corrupt asset → error UI | corrupt-asset test | Data problems are visible |
| P1-03 | `Map<DailyPrayer, DateTime>`; `NextPrayer.prayer`; azkar category ids | No localized-string comparisons for logic | fake-l10n test | Translation edits cannot break alerts |
| P1-04 | Global handlers before `startApp`; bounded local log; background outcome in settings | Errors and background status visible | diagnostics tests | Field failures diagnosable without PII |
| P1-05 | Receivers for TIMEZONE_CHANGED/TIME_SET; resume zone check → reconfigure + reschedule | Reminders follow new zone | resume-check test; device | Correct times after travel |
| P1-06 | `errorPageBuilder` with home action | `/unknown` shows Arabic page | widget test | No English dead end |
| P1-07 | Extract platform/prayer/daily/tap-router units; GetIt only | Files < 400 lines; behaviour unchanged | full notification suite | Lower change risk |
| P1-08 | Single JSON value; legacy migration; range checks | Legacy migrates; invalid dropped | migration tests | Consistent bookmark |
| P1-09 | `v` field per blob; 1.0.0+3 fixture; backup rules | Fixture loads; rules referenced | fixture test + release build | Safe upgrades and restores |

## Phase 2 – Core Islamic features

| ID | Title | Priority | Severity | Features | Files | Deps | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P2-01 | iOS prayer-alert durability | P-High (iOS) | HIGH (NOTIF-03) | Prayer alerts iOS | `prayer_replenishment_service.dart`, `notification_service.dart`, `adhan_preferences.dart` | P0-05 | Medium | B-03 |
| P2-02 | iOS one-off background tasks | P-High (iOS) | MEDIUM (NOTIF-04) | Background iOS | `workmanager_service.dart`, `app_initializer.dart` | — | Small | — |
| P2-03 | Adhan audio stream decision | P-High | MEDIUM (NOTIF-05) | Adhan | `notification_channels.dart`, `adhan_voices.dart` | P0-02, B-09 | Small–Medium | B-09 |
| P2-04 | More methods + per-prayer offsets | P-Medium | MEDIUM (PRAY-01) | Prayer times | `prayer_calculation_policy.dart`, `prayer_times_repository_impl.dart` | — | Medium | B-10 |
| P2-05 | Hard-coded content into gated assets | P-Medium | MEDIUM (CONT-01) | Asma al-Husna, daily verse | screens, assets, manifest, `verify_content.py` | P1-01, P1-02 | Medium | B-05 |
| P2-06 | Timezone database freshness test | P-Medium | MEDIUM (PRAY-02) | Prayer times, alerts | new test | P5-07 | Small | — |
| P2-07 | Exact-alarm status awareness | P-Low | LOW (NOTIF-06) | Prayer alerts | `adhan_settings_controller.dart`, `adhan_preferences.dart` | — | Small | — |

| ID | Description & key steps | Acceptance | Tests | Outcome |
|---|---|---|---|---|
| P2-01 | Budget-based window ≤ 64 pending; end-of-window "open the app" notice; iOS note | Pending ≤ 64 for all settings | budget unit test; iOS device | iOS users warned before alerts lapse |
| P2-02 | Skip one-off registration on iOS | No iOS registration errors | platform-branch test | Clean iOS boot |
| P2-03 | Alarm-usage `_v2` channels or documented notification behaviour | Decision documented and implemented | channel tests; device modes | Adhan behaviour matches intent |
| P2-04 | Add adhan_dart methods with new ids; offsets −30…+30 per prayer | Reference times match published tables | per-method tests | Accurate times for more regions |
| P2-05 | Byte-identical move to JSON assets; extend manifest script | 8 collections gated; identical rendering | equality test | All religious text under review gate |
| P2-06 | Assert minimum tzdata version/rule | Fails on 0.9.4, passes after upgrade | tz test | DST rules current |
| P2-07 | Re-check on resume; persistent hint; reschedule after grant | Hint toggles with permission | widget test | Users know when alerts may be late |

## Phase 3 – UI/UX and accessibility

| ID | Title | Priority | Severity | Features | Files | Deps | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P3-01 | Screen-reader and a11y pass | P-High | MEDIUM (UX-01) | All core flows | presentation widgets | — | Medium | B-03 |
| P3-02 | Splash colours from design | P-Low | LOW (UX-02) | Splash | `splash_screen.dart` | — | Small | — |
| P3-03 | UI strings into ARB | P-Low | LOW (UX-03) | Several screens | presentation files, `app_ar.arb` | P1-03 | Small | — |
| P3-04 | Visual review light/dark/designs | P-High | MEDIUM (UX-01) | All screens | — (evidence), theme tokens | — | Medium | emulator |

| ID | Description & key steps | Acceptance | Tests | Outcome |
|---|---|---|---|---|
| P3-01 | TalkBack/VoiceOver walkthrough of 10 flows; fix labels, order, targets, reduced motion | All issues fixed or ticketed | semantics tests per fix | Usable with assistive tech |
| P3-02 | Use design tokens; align native launch theme | Two designs render correctly | widget/golden test | Consistent first impression |
| P3-03 | Classify literals; move UI text | Guard test blocks new literals | l10n guard test | Consistent localization |
| P3-04 | Screenshot every route × sizes × themes; fix contrast | Screenshot set stored; AA contrast | goldens where stable | Verified visual quality |

## Phase 4 – Performance and resource optimisation

| ID | Title | Priority | Severity | Features | Files | Deps | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P4-01 | Startup budget | P-Medium | INFO (ARCH-06) | Startup | `app_root.dart`, providers | — | Small | mid-range device |
| P4-02 | Artifact size budget, adhan size | P-Low | LOW (PLAT-A-01) | Download size | `res/raw`, CI | P0-02 | Small | owner listening approval |
| P4-03 | Reader frame profiling | P-Medium | MEDIUM (PERF-01) | Reader | — | P1-01 | Small | low-end device |

| ID | Description & key steps | Acceptance | Tests | Outcome |
|---|---|---|---|---|
| P4-01 | Profile cold start; lazy-load only measured hot spots | Baseline + target recorded (e.g. first frame < 1.5 s) | existing suite | Fast, measured startup |
| P4-02 | `bundletool get-size`; optional re-encode with `_v2` channels; CI budget | Sizes recorded; CI guard | CI size step | Smaller downloads |
| P4-03 | DevTools timeline on Al-Baqarah open | No decode frame > 32 ms; first verse < 300 ms warm | — | Smooth reader |

## Phase 5 – Security, privacy and compliance

| ID | Title | Priority | Severity | Features | Files | Deps | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P5-01 | Restrict YouTube key | P-Must | MEDIUM (SEC-01) | Videos | README | — | Small | B-07 |
| P5-02 | Drop precise location | P-High | LOW (PLAT-A-02) | Location, qibla | `AndroidManifest.xml` | — | Small | device |
| P5-03 | iOS privacy manifest, export key | P-Must (iOS) | MEDIUM/LOW (PLAT-I-02/03) | iOS release | `PrivacyInfo.xcprivacy`, `Info.plist` | P7-01 | Small | — |
| P5-04 | Git history secret scan | P-High | (verification gap) | Repository | — | — | Small | — |
| P5-05 | Firebase key restrictions | P-High | INFO (SEC-02) | Crash reporting | — | P0-03 | Small | B-04 |
| P5-06 | Upgrade flutter_local_notifications | P-High | MEDIUM (DEP-01) | Notifications | `pubspec.yaml`, notification code | P0-05, P6-01 | Large | device |
| P5-07 | Upgrade timezone, flutter_timezone | P-High | MEDIUM (DEP-01, PRAY-02) | Prayer times | `pubspec.yaml` | — | Small | — |
| P5-08 | Upgrade workmanager | P-Medium | MEDIUM (DEP-01) | Background | `pubspec.yaml`, `BootReceiver.kt`, `AppDelegate.swift` | P6-01 | Medium | device |
| P5-09 | Upgrade Firebase | P-Medium | MEDIUM (DEP-01) | Crash reporting | `pubspec.yaml` | P0-03 | Medium | — |
| P5-10 | Remaining upgrades; pin hygiene | P-Low | MEDIUM/LOW (DEP-01, DEP-02) | — | `pubspec.yaml`, `docs/DEPENDENCIES_AND_LICENSES.md` | — | Medium | — |

| ID | Description & key steps | Acceptance | Tests | Outcome |
|---|---|---|---|---|
| P5-01 | API + app restrictions + quota | Evidence recorded (no key) | — | Key abuse limited |
| P5-02 | Remove FINE; verify coarse fix | "My location" and qibla work | device + release build | Data minimisation |
| P5-03 | Required-reason declarations; `ITSAppUsesNonExemptEncryption=false` | Xcode privacy report clean | — | App Store compliant |
| P5-04 | Run history scanner; rotate if found | Report stored | — | Verified clean history |
| P5-05 | Restrict keys; delete stale apps | Console evidence | — | Reduced misuse surface |
| P5-06 | Follow majors' migration notes; keep R8 rules | Device checks pass | notification suite + release build | Current, supported plugin |
| P5-07 | Upgrade; run prayer reference tests | P2-06 passes | prayer tests | Fresh tz data |
| P5-08 | Upgrade; re-check native APIs | Reboot test passes | background tests (P6-01) | Supported background API |
| P5-09 | Upgrade; verify consent flow | Opt-in crash visible | monitoring tests | Supported Firebase SDK |
| P5-10 | get_it, go_router, lints; document pins | No avoidable major lag | full suite | Lower maintenance debt |

## Phase 6 – Testing and quality assurance

| ID | Title | Priority | Severity | Features | Files | Deps | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P6-01 | Background reschedule tests | P-Must | MEDIUM (TEST-01) | Background | `workmanager_service.dart`, new tests | — | Medium | — |
| P6-02 | Integration tests in CI | P-High | MEDIUM (TEST-02) | Core flows | `.github/workflows/` | — | Medium | CI emulator minutes |
| P6-03 | Coverage reporting | P-Medium | LOW (TEST-03) | — | workflows | — | Small | — |
| P6-04 | Ownership and timezone regression suite | P-High | (guards NOTIF-01/02) | Notifications | tests | P0-05, P1-05 | Small | — |
| P6-05 | Router/AppRoot/location-dialog tests | P-Medium | (coverage gaps) | Navigation, prayers | tests | P1-06 | Medium | — |
| P6-06 | Device QA matrix | P-Must | (verification) | All | `docs/RELEASE_VALIDATION_MATRIX.md` | P0-03 | Large | B-03 |

| ID | Description & key steps | Acceptance | Tests | Outcome |
|---|---|---|---|---|
| P6-01 | Inject handler dependencies; test throttle, bypass, failure, abort | ≥ 70 % coverage of the file | new unit tests | Background path protected |
| P6-02 | Emulator job (API 34) running `integration_test` | Green 5 runs in a row | 5 flows | End-to-end regressions caught |
| P6-03 | lcov artifact + baseline gate for core paths | Gate active | — | Coverage cannot silently drop |
| P6-04 | Tests encoding P0-05 / P1-05 rules | Fail on regression | new tests | Races don't return |
| P6-05 | Each route builds; banner; dialog validation | Coverage of the three files > 60 % | widget tests | Navigation regressions caught |
| P6-06 | Execute matrix on signed release build | Results recorded | manual | Evidence for release |

## Phase 7 – Production and store release

| ID | Title | Priority | Severity | Features | Files | Deps | Complexity | External |
|---|---|---|---|---|---|---|---|---|
| P7-01 | iOS build pipeline | P-Must (iOS) | HIGH (PLAT-I-01) | iOS | `ios/`, workflows | P0-03 | Large | B-02, B-03, B-08 |
| P7-02 | CI AAB, size budget, advisories | P-Medium | LOW (CI-01) | Build | workflows | — | Small | — |
| P7-03 | Store compliance package | P-Must | INFO (PLAT-A-04) + store items | Store | `docs/STORE_LISTING_AR.md`, `site/` | P0-01..03 | Medium | B-11, B-12, B-13 |
| P7-04 | Documentation consolidation | P-Low | LOW (DOC-01) | Docs | README, `docs/` | — | Small | — |
| P7-05 | Release candidate sign-off | P-Must | all | All | `docs/RELEASE_VALIDATION_MATRIX.md` | Phase 0, P6-06, P7-03 | Medium | owner |

| ID | Description & key steps | Acceptance | Tests | Outcome |
|---|---|---|---|---|
| P7-01 | macOS build, commit Podfile/SwiftPM, CI job, signing | CI iOS green; TestFlight upload | iOS build | Shippable iOS |
| P7-02 | `flutter build appbundle`; size record; advisory check | Workflow green | — | The uploaded artifact is the tested one |
| P7-03 | FGS declaration, Data safety, rating, privacy URL, support, App Store labels | Store checklist PASS | — | Submission-ready listings |
| P7-04 | Refresh README; archive superseded plans; link `docs/audit/` | README matches code | — | One current source of truth |
| P7-05 | Tag RC; run gates; owner sign-off | No open CRITICAL/HIGH unaccepted | all gates | Public release |

## Recommended first phase

Start with **Phase 0**: P0-04 (commit the pending work so CI covers it) → P0-05 (scheduling race, the only HIGH defect fixable entirely in code), while the owner works on P0-01, P0-02 and P0-03 in parallel since they need decisions and evidence only the owner can provide. P6-01 can run alongside P0-05 because it only adds tests.
