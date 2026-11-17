# Sakina – Implementation Status

Progress against [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md) (same task IDs). Updated 2026-11-18. P0-05 and the adhan-voice work were committed in `8e2f0f1`; P1-10 is in the working tree, not committed.

Status: **Done** (code + tests in the tree), **Partial** (part done; rest noted), **Blocked** (needs an owner decision, credentials or devices — see [EXTERNAL_BLOCKERS.md](EXTERNAL_BLOCKERS.md)), **Not started**, **Skipped** (reason given).

| Task | Status | Notes |
|---|---|---|
| P0-01 Content approval | Blocked | B-05 |
| P0-02 Adhan rights | Blocked | B-06 |
| P0-03 Release identity / Firebase | Blocked | B-01, B-02, B-04, B-14 |
| P0-04 Commit pending work | Done | Committed by the owner in `8e2f0f1` (adhan voices, scheduling generation) |
| P0-05 Single-owner scheduling | Done | `SchedulingGeneration`; UI isolate fills the whole window; no parallel background enqueue. Device check §9.6 pending |
| P1-01 Shared Quran store | Done | `QuranMasterAsset`: one decode per process, off the UI isolate (inline under `flutter test`) |
| P1-02 Remove metadata fallback | Done | ~1,000 hard-coded lines removed from `local_surah_data_source.dart` |
| P1-03 Stable prayer identifiers | Done | Scheduling and the in-app prayer banner key on `DailyPrayer`. Also fixed: after Isha the banner ignored a silent Fajr (name "الفجر غداً" never matched). Azkar category routes still match content names (changing them means editing gated content) |
| P1-04 Local diagnostics | Done | `DiagnosticsLog` (error type only, 50 entries), handlers installed first in `main()`, background failures recorded, Settings → سجل التشخيص |
| P1-05 Timezone / clock changes | Done | `BootReceiver` handles `TIMEZONE_CHANGED`/`TIME_SET` (unthrottled `time_change` source); resume check reconfigures `tz.local` and reschedules. Device check pending |
| P1-06 Router error page | Done | `RouteNotFoundScreen` |
| P1-07 Split notification service | Not started | Large refactor; do after commits land |
| P1-08 Atomic bookmark | Done | Single `bookmark_v2` value, legacy migration, range checks. An older app version installed over this one would not see the migrated bookmark |
| P1-09 Versioned blobs, backup rules | Partial | Backup/data-extraction rules added (exclude plugin caches and downloaded recitations). Versioned blobs and the 1.0.0+3 fixture not done |
| P1-10 Permission onboarding, location accuracy | Done (device check pending) | First-run notification and location steps; system-backed permission states with settings recovery; validated, staleness-aware device fixes; offline city naming; device/manual location source with throttled refresh through the P0-05 boundary. Release APK checked on the Android 16 emulator (first-run path; see task notes). Integration tests on the emulator: `prayer_times_flow` fails identically on unmodified `HEAD` (two "05:00" texts since the redesign), `quran_flow` (Basmala finder) and `production_flow` unconfirmed because the emulator ran out of storage; physical Android/iOS checks pending (B-03). City list expansion needs an owner decision |
| P2-01 iOS durability | Done (unverified) | iOS window up to 7 days within the 64-notification limit; "open Sakina" notice at noon on the last day. Needs an iOS device (B-03) |
| P2-02 iOS one-off tasks | Done | Skipped on iOS |
| P2-03 Adhan audio stream | Blocked | B-09 decision |
| P2-04 Calculation methods | Blocked | B-10 decision |
| P2-05 Content into gated assets | Not started | Needs B-05 process for new collections |
| P2-06 tzdata freshness | Not started | After P5-07 |
| P2-07 Exact-alarm awareness | Done | Re-checked on every resume; alerts re-planned when the permission changes |
| P3-01 Screen-reader pass | Blocked | Devices (B-03) |
| P3-02 Splash colours | Skipped | Colours are deliberate (match the logo). Open question for the owner: native launch background `#2B1710` differs from the Flutter splash `#5E3B29` |
| P3-03 UI strings into ARB | Done | No UI text was hard-coded; added a guard test with an allow-list of identifiers/asset names |
| P3-04 Visual review | Blocked | Emulator/device session |
| P4-01 Startup budget | Not started | Needs profiling on a device |
| P4-02 Size budget, adhan size | Partial | CI AAB size budget added; re-encoding blocked on B-06 |
| P4-03 Reader profiling | Not started | Device |
| P5-01 YouTube key restriction | Blocked | B-07 |
| P5-02 Drop precise location | Done | `ACCESS_FINE_LOCATION` removed. Device check of "my location" and qibla pending |
| P5-03 iOS privacy manifest | Done (unverified) | `PrivacyInfo.xcprivacy` added to the Runner target; `ITSAppUsesNonExemptEncryption=false`. Needs an Xcode build to verify |
| P5-04 History secret scan | Not started | |
| P5-05 Firebase key restrictions | Blocked | B-04 |
| P5-06 – P5-10 Dependency upgrades | Not started | One per task, each with a release build and device check |
| P6-01 Background path tests | Done | Handler made injectable; 11 tests |
| P6-02 Integration tests in CI | Done (unverified) | Emulator job added, not yet required; runs on the next CI push |
| P6-03 Coverage reporting | Done | `scripts/coverage_gate.py` + floors, lcov artifact |
| P6-04 Ownership / timezone suite | Done | `scheduling_ownership_test.dart`, `timezone_change_test.dart` |
| P6-05 Router/AppRoot/dialog tests | Partial | Router error page covered; AppRoot banner and location dialog not yet |
| P6-06 Device QA | Blocked | B-03 |
| P7-01 iOS pipeline | Blocked | macOS host, B-02 |
| P7-02 CI AAB, size, deps | Done (unverified) | Runs on the next CI push |
| P7-03 Store compliance | Blocked | B-11 – B-13 |
| P7-04 Documentation | Partial | README corrected; superseded plans not yet archived |
| P7-05 RC sign-off | Blocked | Phase 0 |
