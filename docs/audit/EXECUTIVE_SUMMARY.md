# Sakina – Executive Summary

Audit date: 2026-11-17 · Version `1.0.0+3` · Branch `main` at `ffb7bdb` plus uncommitted adhan-voice work · Audit-only: nothing in the application was changed.

Documents: [Comprehensive report](COMPREHENSIVE_AUDIT_REPORT.md) · [Feature inventory](FEATURE_INVENTORY.md) · [UI/UX](UI_UX_AUDIT.md) · [Security](SECURITY_AUDIT.md) · [Notifications & background](NOTIFICATIONS_AND_BACKGROUND_AUDIT.md) · [Testing](TESTING_AND_QUALITY_REPORT.md) · [Readiness checklist](PRODUCTION_READINESS_CHECKLIST.md) · [Roadmap](IMPROVEMENT_ROADMAP.md) · [Implementation tasks](IMPLEMENTATION_TASKS.md) · [External blockers](EXTERNAL_BLOCKERS.md)

## Overall condition

Sakina is an Arabic-first, local-first Flutter app (Quran reader, prayer times with offline calculation, prayer alerts with selectable adhan recordings, adhkar, duas, hadith, tasbeeh, qibla, khatma, recitation, articles/videos). The code quality is **well above average for a solo project**: clean analyzer, 774 passing tests, defensive startup, carefully reasoned notification edge cases, release-only bug safeguards (R8 rules, resource keep rules, signing guard), privacy-preserving opt-in crash reporting and a CI that builds a real R8 release APK.

What stands between it and a public release is mostly **not code**: religious-content approval, adhan audio rights, and the final store identity are all still pending, and are each enforced by the project's own release gates (which currently fail). In code, the most important defect is a probable race between the UI isolate and the WorkManager background isolate rescheduling the same notifications. The iOS target has never been built.

## Architecture assessment

Feature-first folders with data/domain/presentation layers, GetIt for services and Provider for UI state. Appropriate for the app's size and growth; **no rewrite is recommended**. Local weaknesses: the 2.7 MB Quran JSON is decoded on the UI isolate in five separate places; scheduling logic keys on localized Arabic display strings; the notification service is 1,381 lines with several redundant facade layers.

## Engineering maturity

| Dimension | Level |
|---|---|
| Code quality & static analysis | High |
| Automated testing (unit/widget) | Good (68.4 % line coverage of instrumented files); weak on background and native paths |
| Integration/device testing | Low (exists, not automated, not run) |
| CI/CD | Good for Android debug-safety; no AAB, iOS or integration jobs |
| Observability | Low (no error capture unless the user opts into crash reports) |
| Release management | Gates exist and correctly fail; inputs are missing |

## Readiness score: **58 / 100**

This is a **judgement**, not a measurement. Each area was scored 0–100 from the evidence in the reports, then weighted:

| Area | Weight | Score | Basis |
|---|---|---|---|
| Functional completeness | 15 % | 80 | 16 of 34 inventory rows fully implemented, 10 with issues |
| Code quality & architecture | 15 % | 75 | clean analyzer; PERF-01, ARCH-01..03 |
| Automated testing | 10 % | 65 | 774 tests; TEST-01..03 |
| Notification & adhan reliability | 15 % | 55 | strong design; NOTIF-01..06 unverified on devices |
| Security & privacy | 10 % | 75 | no secrets; SEC-01, PLAT-A-02/03 |
| Android release readiness | 15 % | 40 | signing guard OK; identity gate fails |
| iOS release readiness | 5 % | 15 | never built |
| Content & legal compliance | 10 % | 25 | content and adhan rights pending |
| UX & accessibility | 5 % | 60 | automated checks only; no visual/screen-reader review |

Weighted total = 57.75 → **58**.

## Findings at a glance

43 findings: **3 Critical, 3 High, 17 Medium, 16 Low, 4 Informational**; 35 Confirmed, 5 Probable, 3 Potential. Release blockers: **4** (REL-01, REL-02, REL-03 for any release; PLAT-I-01 additionally for iOS).

### Five most important risks

1. **REL-01** – Quran, hadith and adhkar collections have no recorded source/licence approval (`verify_content.py --require-approved` fails).
2. **REL-02** – Redistribution rights for the four bundled adhan recordings are unverified.
3. **REL-03** – Release identity gate fails: final Android/iOS IDs and Firebase registrations are not aligned; iOS Firebase config is missing.
4. **NOTIF-01** – Foreground and background isolates cancel and reschedule the same notifications concurrently; can lose prayer alerts (probable; needs device confirmation).
5. **NOTIF-03 / PLAT-I-01** – iOS has never been built; on iOS, prayer alerts stop after ~3 days without opening the app and the adhan plays only as the default sound.

## Main strengths

- Offline, zone-aware prayer calculation with high-latitude handling and reference-time tests.
- Thoughtful notification design: stable weekday ID slots, DST-safe recurrence, sound fallback, tap dedupe and hold-until-ready routing.
- Startup recovery screen; defensive parsing of preferences and route extras.
- Privacy by design: local data, opt-in crash reports with no message text, link scheme allow-list.
- Content hash gate and release identity gate already in CI.

## Major weaknesses

- Pending owner/legal inputs (content, audio, identity, store).
- Cross-isolate scheduling race; no timezone-change handling.
- No visibility into field failures, especially background scheduling.
- iOS unverified; integration tests not automated; background path untested.
- Core plugins several major versions behind (notifications 18 → 23).

## Estimated work categories

| Phase | Tasks | Nature |
|---|---|---|
| 0 – Blockers | 5 | 3 owner-driven, 2 code (Small–Medium) |
| 1 – Architecture & reliability | 9 | mostly Medium; one Large refactor |
| 2 – Islamic features | 7 | Small–Medium; 2 need owner/scholar decisions |
| 3 – UI/UX & a11y | 4 | device-based review + small fixes |
| 4 – Performance | 3 | measure-first, Small |
| 5 – Security/privacy/compliance | 10 | config + one-at-a-time upgrades |
| 6 – Testing | 6 | Small–Medium + device QA |
| 7 – Release | 5 | iOS pipeline (Large), store package |

**49 tasks** in total ([IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md)); 15 external blockers ([EXTERNAL_BLOCKERS.md](EXTERNAL_BLOCKERS.md)).

## Final recommendation

Do **not** publish yet. Begin Phase 0: commit the pending adhan work (P0-04), fix the scheduling race (P0-05) and add background-path tests (P6-01), while the owner completes content approval (P0-01), adhan rights (P0-02) and the release identity (P0-03). An Android release is realistic once Phase 0, P1-04, P1-05, P5-01, P6-06 and P7-03 are done; iOS requires P7-01, P2-01, P2-02 and P5-03 in addition.
