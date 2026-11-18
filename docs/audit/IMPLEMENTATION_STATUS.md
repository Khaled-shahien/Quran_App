# Sakina – Implementation Status

Progress against [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md) (same task IDs). Updated 2026-11-18. P0-05 and the adhan-voice work were committed in `8e2f0f1`, P1-10 in `33117d6`. Phase 2 of `SAKINA_PRODUCT_AUDIT_AND_FEATURE_ROADMAP.md` is tracked at the end of this file.

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
| P1-07 Split notification service | Done | Core plus reminders, prayer alerts, wording, tap routing and clock rules in separate files (`070632f`) |
| P1-08 Atomic bookmark | Done | Single `bookmark_v2` value, legacy migration, range checks. An older app version installed over this one would not see the migrated bookmark |
| P1-09 Versioned blobs, backup rules | Done | Backup/data-extraction rules; ordered, resumable preference migrations; 1.0.0+3 upgrade fixture (`test/core/upgrade/`); versioned SQLite schema (`b96f2d7`) |
| P1-10 Permission onboarding, location accuracy | Done (device check pending) | First-run notification and location steps; system-backed permission states with settings recovery; validated, staleness-aware device fixes; offline city naming; device/manual location source with throttled refresh through the P0-05 boundary. Release APK checked on the Android 16 emulator (first-run path; see task notes). Integration tests on the emulator: `prayer_times_flow` fails identically on unmodified `HEAD` (two "05:00" texts since the redesign), `quran_flow` (Basmala finder) and `production_flow` unconfirmed because the emulator ran out of storage; physical Android/iOS checks pending (B-03). City list expansion needs an owner decision |
| P2-01 iOS durability | Done (unverified) | iOS window up to 7 days within the 64-notification limit; "open Sakina" notice at noon on the last day. Needs an iOS device (B-03) |
| P2-02 iOS one-off tasks | Done | Skipped on iOS |
| P2-03 Adhan audio stream | Blocked | B-09 decision |
| P2-04 Calculation methods | Done (defaults need B-10) | 20 Sunni methods, per-time minute offsets, Umm al-Qura Ramadan Isha, country suggestion confirmed by the user, explanation sheet (`2aba0b1`, `8a185da`). Dubai, Diyanet, Morocco and Moonsighting differ from AlAdhan by up to 5 min by design; check against official timetables |
| P2-05 Content into gated assets | Partial | New collections added gated and pending review: tafsir al-Muyassar, Hisn al-Muslim, Islamic occasions. Asma al-Husna still in Dart |
| P2-06 tzdata freshness | Done | timezone 0.11.2, tzdata 2026e (`6199bcf`). The old data predated Morocco's permanent UTC+0 (2026-09-20), so times there were an hour late. Prayer code now loads latest_all (the small set dropped link zones such as Europe/Oslo). The city list's same-offset aliases for 11 zones can now be rebuilt with the real zones |
| P2-07 Exact-alarm awareness | Done | Re-checked on every resume; alerts re-planned when the permission changes |
| P3-01 Screen-reader pass | Partial | New screens are in the 200% text audit (labels, 48 dp targets, no overflow); the listening mode uses a live region and adjust actions. TalkBack on a device still needed (B-03) |
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
| P5-06 – P5-10 Dependency upgrades | Partial | flutter_local_notifications 18 → 22.3.3 with timezone 0.11.2 (`6199bcf`; 23.x needs AGP 9 and compileSdk 37). Others not started. Device check pending |
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

## Phase 2 – Core experience (roadmap of 2026-11-18)

| Item | Status | Commit | Notes |
|---|---|---|---|
| 1 Local DB + versioned migrations (T-06, T-07) | Done | `b96f2d7` | sqflite, append-only migrations, opened lazily |
| 2 Quran index tabs + go-to (R-10) | Done | `601c347` | Juz/Hizb lists, page or surah:ayah jump |
| 3 Methods, offsets, why-this-time (R-30, R-43) | Done | `2aba0b1` | see P2-04 |
| 4 Offline city database (R-31) | Done | `8a185da` | 7,498 GeoNames cities; IL and EH left out pending an owner decision on labels |
| 5 Alert health check (R-42) | Done | `1fc2cad` | device check pending (B-03) |
| 6 Offline tafsir (R-11) | Done | `f008f36` | Tanzil terms are non-commercial with attribution; confirm with KFGQPC |
| 7 Saved verses, notes, export/import/erase (R-12, R-71) | Done | `84881ae` | uses file_picker 13 |
| 8 Complete Hisn al-Muslim (R-20) | Done | `41adec4` | no references in the API; written permission needed (B-05) |
| 9 Prayer-anchored reminders + Now card (R-40) | Done | `2e2cb8d` | |
| 10 Hijri calendar, occasions, Ramadan (R-34, R-36, R-37) | Done | `bc00cb2` | Imsak = Fajr - 10 min; occasions list needs scholar review |
| 11 Home-screen widget (R-38) | Done | `d4efcde` | Android only; refreshed by the app and every 30 min; not yet seen on a device |
| 12 Recitation API migration (R-16) | Blocked | — | needs Quran Foundation client registration and a backend for the secret (owner decision 2026-11-05) |

## Phase 3 – New product features (roadmap of 2026-11-18)

| Item | Status | Commit | Notes |
|---|---|---|---|
| Notification split (T-04) | Done | `070632f` | see P1-07 |
| Plugin upgrades (T-05) | Partial | `6199bcf`, `93530a9` | notifications and timezone only (owner approved these two) |
| Fajr adhan, stop, full screen, auto-DND (R-32, R-33) | Partial | `50ed104` | stop button on every adhan; optional Do Not Disturb 5 min after the adhan for 15–60 min. No Fajr recording (with the Fajr phrase) yet: the bundled adhans lack it; download not approved |
| Fajr wake mode (R-50) | Done (device check pending) | `50ed104` | local plugin `packages/sakina_alarms`: full-screen alarm, rising sound, snooze only while it ends ≥10 min before sunrise. Needs the USE_FULL_SCREEN_INTENT declaration in Play Console |
| Prayer/fasting log, excused mode (R-39) | Done | `3431d2e` | DB schema 2; local only, in the user's export file |
| Wird woven into prayers (R-41) | Done | `61364f5` | today only, 20 min after each prayer |
| Mosque iqama offsets (R-44) | Done | `b5e99a4` | set in Settings |
| Hifz revision queue (R-46) | Done | `456f599`, `73c3e5e` | DB schema 3; 1/3/7/14/30 days. Repeat-ayah audio uses the existing range repeat |
| Accessible listening mode (R-47) + TalkBack (P3-01) | Done / Partial | `2cec504` | see P3-01 |
| Share as image (R-13) | Done | `9abb6f9` | share_plus 13.3.1 |
| Search upgrade (R-14) | Done | `9abb6f9` | index built once, whole-word ranking, 2:255 |
| Recitation controls (R-15) | Done | `2cec504` | sleep timer, auto-next surah, repeat each ayah |
| Hadith upgrade phase 1 (R-21) | Done (pending review) | `015c3aa` | HadeethEnc text, grade, explanation, lessons, references for all 50; check the pairing and HadeethEnc's terms (B-05) |
| Guide expansion (R-23) | Not started | — | needs a sourced, reviewed text (owner decision 2026-11-18) |
| Daily calm minute (R-48) | Done | `8c44e3d` | verse of the day with its al-Muyassar meaning; no dua pairing (would need curation) |
| Travel awareness (R-49) | Partial | `8c44e3d` | "you are now in X" notice; travel rulings card waits for a reviewed text |
| Simple mode (R-51) | Done | `8c44e3d` | four large tiles; text one step larger |
| iOS release (R-72) | Blocked | — | needs a macOS host and Xcode (P7-01, B-02) |

## Phase 4 – Advanced (roadmap of 2026-11-18)

| Item | Status | Commit | Notes |
|---|---|---|---|
| Log out of cloud backup (PV-3) | Done | `612eb3c` | the log now lives in `sakina_private.db`, excluded from Android cloud backup; rows from Phase 3 builds are moved once |
| Encrypted backup (R-53) | Done | `612eb3c` | optional passphrase; Argon2id (19 MiB, 2 passes) + AES-256-GCM; cryptography 2.9.0 |
| One offline search box (R-54) | Done | `2c052f7` | Quran, Hisn al-Muslim, the forty hadith, guide; from Home's search button |
| Private weekly reflection (R-52) | Done | `4c708f8` | off by default; Friday and Saturday card |
| Monthly timetable export (R-35) | Done | `062670e`, `0191080` | image and A4 PDF (pdf 3.13.1, Amiri) |
| Offline group khatma (R-45) | Done (text codes) | `51ac0ba` | codes travel by any messenger; no QR (packages not approved) |
| Hadith phase 2 (graded collections) | Done (pending review) | `d2cd689` | all 3,574 Arabic HadeethEnc hadith under 493 topics, grades as published; 12.5 MB asset; confirm HadeethEnc terms (B-05) |
| Additional UI languages (G7) | Done: English | `8a4b493` | 1,112 strings; religious texts stay Arabic; needs a native English review and a look on device |
| Word-by-word / iʿrab / fixed pages (G5, G6) | Research only | — | `docs/research/PHASE4_RESEARCH_NOTES.md`; waits for KFGQPC permission and a decision on the GPL Quranic Arabic Corpus |
| Semantic search / voice (6.4) | Research only | — | voice not approved; semantic search needs a quality and size spike |
| Account-free sync | Research only | — | recommendation: scheduled encrypted export to a folder the user picks |
| Wear OS tile (G21) | Not started | — | not approved this phase |

Size after Phase 4: release APK 92.3 MB (was 83.4 MB), App Bundle 89.5 MB, over the CI budget of 85 MB (`AAB_BUDGET_MB` in `.github/workflows/flutter-quality.yml`). The hadith encyclopedia is 2.9 MB compressed; the rest is new code in each of the three ABIs. Raising the budget or trimming content is an owner decision; Play delivers per-ABI splits, so downloads are smaller than the bundle.

