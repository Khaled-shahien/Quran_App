# UPDATED DEVELOPMENT & IMPROVEMENT PLAN

**Current re-audit:** 2026-09-28
**Previous audit:** 2026-09-22 (`AUDIT_REPORT.md`)
**Implementation evidence:** `docs/AUDIT_IMPLEMENTATION.md`
**Readiness:** **NOT READY**

This document is the current source of truth. The historical progress log remains below so the original implementation trail is not lost. Repository implementation is not treated as runtime, owner-approval, signed-artifact, or production evidence.

## 1. Audit Update Summary

- Original tracked tasks: **40** (`T01`-`T40`), all retained.
- Completed at repository/test scope: **17**.
- Partially completed: **19**.
- Not implemented: **0 confirmed**.
- Rework: **1** (`T11`, with current prayer error-handling risk `NF-001`).
- Blocked: **3** (`T34`, `T35`, `T39`).
- New findings: **3** (`NF-001`-`NF-003`).
- Current production blockers: release identity/signing, religious-content approval, notification/device evidence, privacy/store readiness, and physical accessibility/reliability evidence.

Focused current verification: `flutter test test/features/prayers` passed **33 tests**; `dart analyze lib/features/prayers test/features/prayers` reported no issues. The full suite ran **220 tests with 3 failures**, all in offline surah name/number lookup in `quran_search_screen_test.dart`. Physical-device testing, signed artifact inspection, and release gates remain pending.

## 2. Current Project Baseline

Flutter feature-oriented app using Provider/ChangeNotifier, GetIt, GoRouter, SharedPreferences, bundled JSON content, HTTP repositories, Firebase packages, local notifications, WorkManager, Geolocator, and native compass channels. Quran, duas, adhkar, and hadith are bundled; prayer and media use network services with selected caches. Arabic RTL, Cairo/Amiri assets, themes, settings, navigation, Quran search, prayer location configuration, Qibla, Khatma, media, reminders, diagnostics, bookmarks, and favorites are present in code.

The application is broad but not release-ready. No physical-device permission/notification/reboot/timezone/accessibility/performance evidence, approved Firebase identity, signed production artifact, public privacy URL, scholarly content approval, or store submission is verified. Emulator tests do not establish Qibla sensor or OEM notification behavior.

## 3. Previous Findings vs Current State

| Area | Previous state | Current state | Resolution |
|---|---|---|---|
| Prayer location | Silent/fixed Cairo fallback | GPS/manual coordinates, city data, method persistence, stale-request protection | Code implemented; physical and policy verification remain |
| Prayer cache | Write-through/stale behavior incomplete | Keyed cache, expiry, stale metadata, refresh paths | Partial; multi-day/DST/offline matrix remains |
| Signing/identity | Debug signing and sample identities | Debug fallback rejected; identity gate documented | Blocked on owner values, credentials, signed artifact |
| Notifications | Delivery, reboot, routing unverified | Local scheduling, receivers, canonical Khatma route | Partial; device matrix and future-day replenishment remain |
| Search | Unfinished entry | Offline verse plus surah name/number search and tests | Complete for defined scope |
| Localization/UI | English prayer states; dark gaps | Core Arabic localization, dark component themes, contrast tests | Partial; remaining strings/device review |
| Content/privacy | No approval workflow | Manifest/disclosure, integrity checks, draft policy, release gates | Blocked on owners/reviewers/public URL |

## 4. Master Task Status Table

Status: **A Completed**, **B Partially Completed**, **D Needs Rework**, **F Blocked**. Completion reflects verified repository scope, not release readiness.

| ID | Original task | Priority | Status | % | Evidence / remaining work |
|---|---|---:|---|---:|---|
| T01 | GPS flow | P1 | B | 75 | Injected lookup/errors/stale protection; physical denial/travel tests pending |
| T02 | Location UI | P1 | B | 75 | City catalog/manual/GPS/method UI; policy and device UX pending |
| T03 | Release signing | P0 | B | 50 | Debug fallback rejected; keystore/IDs/signed artifact pending |
| T04 | Dark components | P1 | A | 100 | Component themes and tests present |
| T05 | Caption contrast | P1 | A | 100 | Dark token and automated contrast check |
| T06 | Crashlytics | P1 | B | 75 | Opt-in integration; project/iOS/symbol verification pending |
| T07 | Analytics | P2 | B | 75 | Allowlisted events; dashboard/retention verification pending |
| T08 | Privacy | P0 | B | 75 | Draft/inventory; owner/contact/public URL pending |
| T09 | Settings | P1 | A | 100 | Theme, reading, location, notifications, monitoring, sources |
| T10 | Quran search | P1 | B | 75 | Verse search works, but all three offline surah name/number acceptance tests fail |
| T11 | FCM decision | P1 | D | 75 | Local reminders selected; dormant push code/dependency cleanup pending |
| T12 | Content provenance | P0 | B | 75 | Metadata/hash/disclosure gates; sources/reviewer approval pending |
| T13 | Diagnostic route | P1 | A | 100 | Debug-only notification test route |
| T14 | Device notifications | P0 | B | 50 | Scheduling/routing code; physical matrix and future-day replenishment pending |
| T15 | Primary navigation | P2 | A | 100 | Five destinations and reader path |
| T16 | Continue reading | P2 | A | 100 | Position restore shortcut |
| T17 | Refresh | P2 | A | 100 | Prayer refresh and media retry paths/tests |
| T18 | Media offline UX | P2 | B | 75 | Retry/error paths; complete cached/stale validation pending |
| T19 | Splash | P2 | A | 100 | Two-second delay and independent onboarding state |
| T20 | Khatma completion | P3 | A | 100 | Completion dialog |
| T21 | Home refactor | P2 | A | 100 | Major widgets extracted |
| T22 | Reader refactor | P2 | A | 100 | Data/content/control parts extracted |
| T23 | Color aliases | P2 | A | 100 | Canonical tokens migrated |
| T24 | Directionality | P2 | B | 75 | Redundant wrapper removed; bidi/icon review pending |
| T25 | Use-case directories | P3 | A | 100 | `domain/usecases` verified |
| T26 | Bundled fonts | P1 | A | 100 | Cairo/Amiri assets and licenses bundled |
| T27 | Semantics | P1 | B | 75 | Labels/settings semantics; screen-reader audit pending |
| T28 | Dark visual tests | P2 | A | 100 | Settings goldens reviewed |
| T29 | RTL tests | P1 | A | 100 | 360px/2x text navigation/settings checks |
| T30 | Network failure tests | P1 | A | 100 | Media retry and GPS stale/denial regressions |
| T31 | Accessibility suite | P0 | B | 75 | Automated target/contrast/large-text checks; device audit pending |
| T32 | Integration flows | P1 | B | 75 | Settings/theme/search/reader flows; physical/signed run pending |
| T33 | Store listing | P1 | B | 50 | Arabic copy/screenshots requirements; final assets/URL pending |
| T34 | iOS Firebase | P0 | F | 25 | Platform/configuration/identity decision pending |
| T35 | Device matrix | P0 | F | 25 | Matrix documented; physical devices/evidence unavailable |
| T36 | Security review | P0 | B | 50 | Local checks; independent review and sign-off pending |
| T37 | Profiling | P2 | B | 50 | Font/splash improvements; profile measurements pending |
| T38 | Final regression | P0 | B | 50 | Prayer slice passes; full suite is 220 tests with 3 Quran search failures |
| T39 | Store release | P0 | F | 0 | Not performed; all release gates must close |
| T40 | Operations | P1 | B | 50 | Runbook/monitoring integration; alerts/owners/evidence pending |

## 5. Completed Implementations

Verified repository/test completion: `T04`, `T05`, `T09`, `T13`, `T15`, `T16`, `T17`, `T19`, `T20`, `T21`, `T22`, `T23`, `T25`, `T26`, `T28`, `T29`, and `T30`. `T10` is partial because its three surah lookup acceptance tests fail. These are complete within their stated code/test scope and still require ordinary regression maintenance.

## 6. Partially Completed Items

`T01`, `T02`, `T03`, `T06`, `T07`, `T08`, `T10`, `T12`, `T14`, `T18`, `T24`, `T27`, `T31`, `T32`, `T33`, `T36`, `T37`, `T38`, and `T40` have repository slices but unresolved runtime, approval, operational, test, or measurement boundaries. `T11` is rework rather than completion because the product decision is made but dormant FCM remains.

## 7. Remaining Development Work

**P0:** approved identities/Firebase/signing; content provenance and qualified review; future-day prayer replenishment; physical notification and permission tests; accessibility/Qibla/reliability evidence; privacy/store gates; final regression.
**P1:** location/travel UX, monitoring project verification, privacy publication, notification matrix, integration validation, store assets, FCM cleanup, security review, operations alerts.
**P2/P3:** measured profiling, media stale/cache refinement, bidi cleanup, and optional feature polish.

## 8. Items Requiring Rework

`T11` must leave one clear notification strategy: local reminders are selected, while dormant FCM code/dependency must be removed or isolated and cannot be advertised as push support.

The current worktree change in `lib/features/prayers/presentation/providers/prayer_times_provider.dart` removed the prior catch around notification cancellation and preference writes. Happy-path tests pass, but storage/scheduler exceptions can now escape manual location selection without a localized recovery state. See `NF-001`.

## 9. Blocked Items

`T34` is blocked by launch-platform choice, approved bundle/project identity, genuine native Firebase configuration, and signing. `T35` is blocked by physical devices and evidence capture. `T39` is blocked by all P0 gates, owner approvals, credentials, device evidence, and signed-artifact inspection.

## 10. New Findings

### NF-001 — Manual prayer configuration lacks controlled failure handling

**Evidence:** Current manual-selection code awaits notification cancellation and preference writes without the previous catch/recovery branch.
**Impact:** A storage/platform failure may become an uncaught exception and leave the user unsure whether the new location was saved.
**Root cause:** Error handling was removed while asynchronous persistence remained.
**Priority:** P1.
**Action:** Restore narrow error handling while retaining request-id/disposal guards; add scheduler-failure and preference-write-failure tests.
**Acceptance:** No uncaught UI exception; latest request remains authoritative; localized retry is shown; failed saves are not reported as saved.

### NF-002 — Tooltip affordance removed from three dua back buttons

**Evidence:** Current worktree diff removes `IconButton.tooltip` from `duas_screen.dart`, `azkar_screen.dart`, and `azkar_details_screen.dart`; semantic labels remain.
**Impact:** Pointer/desktop users lose hover guidance.
**Priority:** P2.
**Action:** Restore tooltips or replace them with a tested shared policy.
**Acceptance:** Back actions expose semantic labels and hover tooltips without duplicate mobile announcements.

### NF-003 — Quran surah name/number lookup acceptance tests fail

**Evidence:** `flutter test --no-pub test/features/quran/presentation/screens/quran_search_screen_test.dart` deterministically fails all three lookup cases (`الفاتحة`, `١`, and `1`) because no `ListTile` is rendered.
**Impact:** The advertised offline surah lookup is not verified and the full suite is red.
**Root cause:** The screen's asynchronous surah metadata path does not produce matching results in the test flow, although the bundled JSON is present and verse search remains separate.
**Priority:** P1.
**Action:** Trace metadata loading/normalization in the widget path, fix the lookup, and retain deterministic tests for Arabic name, Eastern Arabic numeral, and Western numeral.
**Acceptance:** The isolated file and full suite pass; each query renders exactly one result labeled `سورة 1` and opens the expected reader destination.

## 11. Regressions Discovered

No confirmed navigation, theme, RTL, Firebase, notification-delivery, or data-integrity regression is established from available evidence. `NF-001` is a confirmed error-handling risk, `NF-002` a confirmed pointer affordance regression, and `NF-003` a confirmed Quran search regression. Device-only regressions remain Unable to Verify.

## 12. Current Production Blockers

| Blocker | Required fix | Acceptance criterion |
|---|---|---|
| Identity/signing | Approved IDs, Firebase config, protected signing | Signed artifact installs, matches IDs, and passes identity gate |
| Religious content approval | Sources, editions, licenses, reviewer sign-off | `verify_content.py --require-approved` passes and approvals are archived |
| Notifications | Future-day replenishment plus physical test matrix | Permission, delivery, tap, reboot, upgrade, timezone cases pass |
| Privacy/store readiness | Public policy/support URL, listing and screenshots | Store checklist and release links are approved and resolvable |
| Physical reliability/accessibility | Hardware QA for Qibla, TalkBack/VoiceOver, large text, performance | Each required case has expected result, actual result, and evidence |

## 13. Updated Priority Matrix

| Priority | Scope |
|---|---|
| P0 | Signing/identity, content/privacy gates, reminders, physical reliability/accessibility, final regression |
| P1 | Location recovery, monitoring, notification routing, store assets, FCM cleanup, security, integration |
| P2 | Profiling, media stale/cache refinement, bidi cleanup, maintainability |
| P3 | Global search, quiet hours/history, richer offline media, post-release polish |

## 14. Current Production Readiness

**NOT READY.** Broad functionality and automated coverage exist, but prayer correctness, reminder delivery, release identity, content approval, privacy publication, physical accessibility, Qibla sensors, performance, and signed-artifact behavior lack required evidence. No overall numeric score is assigned.

## 15. Updated Development Roadmap

1. **Phase 1 — Critical Fixes:** Fix `NF-001`; finalize prayer policy/replenishment; obtain platform, identity, signing, privacy, and content approvals.
2. **Phase 2 — Core Functional Completion:** Verify permissions, notification taps/reboot/timezone, prayer cache/offline behavior, media recovery, and FCM isolation.
3. **Phase 3 — UI/UX Refinement:** Restore tooltip affordances; finish Arabic strings, bidi/icon direction, themes, large text, and store screenshots.
4. **Phase 4 — Technical & Performance Improvements:** Profile startup, frames, memory, battery, and network; optimize measured problems.
5. **Phase 5 — QA & Stability:** Execute physical device, TalkBack/VoiceOver, Qibla, offline, update, reboot, and signed-install regression.
6. **Phase 6 — Production Preparation:** Run all gates, approve content/policy, configure monitoring, inspect signed artifact.
7. **Phase 7 — Release & Post-Release:** Internal test, staged rollout, thresholds, named ownership, corrective-build process.

## 16. Updated Implementation Order

1. `NF-001`, platform decision, approved IDs/Firebase/signing/privacy/content governance.
2. Prayer policy, location/cache behavior, and future-day replenishment.
3. FCM isolation and local-notification verification.
4. Physical notification, permission, Qibla, RTL, accessibility, and signed-install tests.
5. Media/offline, monitoring opt-in/out, and store assets.
6. Performance measurements and final automated/device regression.
7. Internal/staged release and operations activation.

## 17. Final Development Backlog

| ID | Title | Priority | Dependencies | Definition of done |
|---|---|---:|---|---|
| B-01 | Harden manual prayer failure handling | P1 | NF-001 | Failure tests pass; localized retry; no uncaught exception |
| B-02 | Finalize prayer policy/replenishment | P0 | Owner/content approval | Method/madhab/timezone documented; closed-app next-day test passes |
| B-03 | Provision identity and signing | P0 | Owner credentials | Identity gate and signed install pass |
| B-04 | Approve content provenance | P0 | Reviewer/licenses | Required content gate passes; approvals archived |
| B-05 | Verify physical notifications | P0 | B-02, approved build | Permission/delivery/tap/reboot/upgrade/timezone cases pass |
| B-06 | Complete privacy/store package | P0 | Owner contact/policy | URL, listing, screenshots and disclosures approved |
| B-07 | Complete accessibility/Qibla audit | P0 | Physical devices | TalkBack/VoiceOver, large text, motion, sensor cases pass |
| B-08 | Isolate FCM | P1 | Product decision | No unsupported push claim; startup/privacy tests pass |
| B-09 | Verify monitoring/operations | P1 | Approved Firebase | Opt-in/out, crash/event, symbols, alerts, ownership pass |
| B-10 | Run performance/final regression | P1 | Release-like build | Profile evidence and all automated/device gates archived |

## 18. Acceptance Criteria

No silent fixed prayer fallback; explicit location/method/timezone; no debug signing; approved content sources/licenses; localized recoverable errors; exact notification destinations; physical permission/reboot evidence; accessible primary flows; no unsupported FCM claim; public privacy/support links; and reproducible signed-artifact verification.

## 19. Definition of Done

Code/configuration exists, focused checks pass, affected flows and failure states are exercised, Arabic/RTL/accessibility impact is reviewed, documentation is updated, and external dependencies have recorded evidence. Release work additionally requires build SHA, version, device/OS, locale/timezone, permissions, expected/actual result, and archived artifact or logs.

## 20. Final Release Requirements

Use [docs/RELEASE_REQUIREMENTS.md](RELEASE_REQUIREMENTS.md) and [docs/DEVICE_QA_AND_OPERATIONS.md](DEVICE_QA_AND_OPERATIONS.md). Require formatting, analyzer, full tests, integration, content integrity/approval, identity, signed build/install, device matrix, privacy/store approval, monitoring, and evidence archive. Do not publish with any P0 blocker open.

## 21. Post-Release Recommendations

Use internal testing before staged rollout. Monitor crashes, ANRs, notification failures, opt-in, and user reports against approved thresholds. Process religious-content changes through the source/reviewer workflow. Consider global search, quiet hours, notification history, richer offline media, and further decomposition only after reliability is established.

## 22. Final Master Action Plan

Fix `NF-001`; obtain platform, identity, signing, Firebase, privacy, and content approvals; finish prayer policy and multi-day replenishment; run physical notification/Qibla/accessibility/device tests; verify monitoring and store materials; execute the complete signed-build regression; then proceed through internal and staged release with named operational ownership. Completed work is not repeated as pending work.

## 2026-09-28 — Blueprint implementation and verification

The remaining application work now includes offline city selection, settings,
persistent reading preferences, bottom navigation, continue reading, surah
name/number search, dark component themes, bundled Cairo/Amiri, optional
monitoring, deferred notification permission, and smaller home/reader files.
Religious text bytes were not changed. Existing user changes in editor settings
were left untouched.

### Task status

“Implemented” describes repository work, not permission to publish. Device and
owner checks are listed separately and must not be inferred from passing tests.

| Task | Status and evidence / remaining work |
|---|---|
| T01 GPS flow | Implemented permission/service errors, injected device lookup, stale-response protection and manual recovery. Physical permission recovery remains to verify. |
| T02 Location UI | Implemented offline search of 18 city centers, manual coordinates, device location and calculation method. Catalog is deliberately a limited subset; attribution is bundled. |
| T03 Release signing | Existing release guard refuses debug fallback. Owner keystore, approved application ID and signed install still pending. |
| T04 Dark components | Implemented navigation, sheet, dialog, input and scrollbar component themes. |
| T05 Caption contrast | Implemented dedicated dark caption token; automated contrast check against card/background. |
| T06 Crashlytics | Integrated opt-in mobile service and Android plugin; off by default. Real project events, iOS upload setup and symbol verification pending. |
| T07 Analytics | Integrated allowlisted app/settings-open events, no reading/search/location payloads. Dashboard validation pending. |
| T08 Privacy | Arabic policy draft and data inventory prepared. Owner contact, retention approval and public URL pending. |
| T09 Settings | Implemented theme, reading, location, notifications, reminder times, optional monitoring, about and sources. |
| T10 Quran search | Existing normalized verse highlighting retained; added offline surah name and Arabic/Western number lookup. |
| T11 FCM decision | Local reminders selected for production. Startup messaging/token registration and native auto-init disabled. Dormant diagnostic code/dependency retained, no backend push claim. |
| T12 Content provenance | Added metadata fields and in-app pending-source disclosure. Release gate requires approval. Actual sources, editions, licenses and qualified reviewer approval remain pending. |
| T13 Diagnostic route | Notification-test route is debug-only. |
| T14 Notifications on devices | Pending physical foreground/background/terminated, permission, reboot, upgrade and timezone evidence. Future-day prayer replenishment is still incomplete. |
| T15 Navigation | Implemented five primary destinations; reader remains outside the shell. |
| T16 Continue reading | Implemented bookmark shortcut that restores the reader position. |
| T17 Refresh | Added prayer pull-to-refresh; existing media refresh paths retained. |
| T18 Media offline UX | Existing recoverable error/retry states retained; retry regression added. Full cached browsing of every media type is not promised. |
| T19 Splash | Reduced delay to two seconds; onboarding completion tracked independently of permission prompts. |
| T20 Khatma | Added completion congratulations dialog. |
| T21 Home refactor | Extracted drawer, khatma actions, prayer header and continue-reading widget. |
| T22 Reader refactor | Extracted data, content, controls and button parts, retaining reader state ownership. |
| T23 Color aliases | Removed legacy aliases and migrated references to canonical tokens. |
| T24 Directionality | Removed redundant application-level wrapper; Arabic content/screen wrappers retained for now. Broader cleanup remains optional follow-up. |
| T25 Use-case directories | Verified current tree already uses `domain/usecases`; no `use_cases` references remain. |
| T26 Bundled fonts | Cairo and Amiri assets and OFL licenses bundled; production widgets no longer fetch GoogleFonts dynamically. |
| T27 Semantics | Added missing icon tooltips and settings section semantics. Complete manual screen-reader audit remains pending. |
| T28 Dark visual tests | Added Windows light/dark settings goldens with actual Cairo and Material icon fonts; visually inspected. Coverage is settings, not every screen. |
| T29 RTL tests | Added RTL navigation and settings checks, including 360px width at 2x text in both themes. |
| T30 Network failure tests | Existing repository failure coverage retained; added media failure-to-retry recovery and GPS denial/stale-result tests. |
| T31 Accessibility suite | Added navigation labeled-target/minimum-target guidelines and contrast/large-text checks. Full app-wide audit pending. |
| T32 Integration | Added real-app settings/theme/offline-search/reader flow. Android execution status recorded below. |
| T33 Store listing | Arabic listing copy and screenshot capture requirements drafted; real store assets, privacy URL and owner approval pending. |
| T34 iOS Firebase | Pending platform decision, approved bundle/project identity and genuine native config. |
| T35 Device matrix | Matrix documented; physical multi-device execution pending. |
| T36 Security review | Local checks cover release signing, ignored credentials, no tracked `.env`/keystore, HTTPS call sites and content gate. Independent/full security review pending. |
| T37 Profiling | Offline fonts and shorter splash implemented. Profile-mode startup/frame/memory measurements pending. |
| T38 Final regression | Automated checks recorded below; physical-device and signed-build regression still pending. |
| T39 Store release | Not performed. Blocked on release credentials/identity, content/policy approval, device evidence and signed artifact validation. |
| T40 Operations | Monitoring integration and rollout/runbook drafted. Production dashboard/alerts, release owners and post-launch evidence pending. |

### Validation

- Flutter 3.48.0-0.5.pre / Dart 3.14 beta is the local and pinned CI test toolchain.
  A production SDK choice still requires verification before publication.
- Static analysis: no issues after the implementation batch.
- Initial full regression: 217 passed, two settings golden mismatches following
  a deliberate outline-contrast adjustment. Baselines were regenerated with
  bundled fonts and reviewed; final regression result is recorded below.
- All four religious-content SHA-256 values were verified using Node locally.
  Python is unavailable on this machine, so the Python release approval command
  has not been executed locally; CI owns that additional check.
- Native Android integration was attempted on API 36 x64. Build outcome is
  recorded below; an emulator is not evidence for physical Qibla sensors or
  OEM notification delivery.

### Release inputs still needed

Approved Android application ID; launch platforms and iOS bundle ID if applicable;
Firebase project/configuration; signing material in protected secrets; public
privacy/support contact; content provenance and reviewer sign-off. The earlier
configuration question received an echo of its prompt, so no production values
have been invented.

See `RELEASE_REQUIREMENTS.md`, `DEVICE_QA_AND_OPERATIONS.md`,
`PRIVACY_POLICY_DRAFT_AR.md`, `STORE_LISTING_AR.md` and `THIRD_PARTY_ASSETS.md`.

## 2026-09-28 — Prayer location request ordering

Compared the blueprint's first blockers with the current implementation:

- Prayer location already supports device GPS and manual coordinates. An
  unconfigured installation does not silently use Cairo. Manual city search
  and physical-device location verification remain separate work.
- Android release builds already require release signing properties and forbid
  falling back to debug signing. A production-signed artifact was not verified.

Fixed asynchronous request ordering in `PrayerTimesProvider`: late location
lookups, failures, and manual selections cannot overwrite a newer request.
Pending lookups cannot start repository requests after disposal. Date correction
also stops when another request has taken ownership of the state.

Added four regression tests covering stale lookup success, stale lookup failure,
overlapping manual selections, and completion after disposal.

Validation:

- `flutter test test/features/prayers`: 31 tests passed.
- `dart analyze lib/features/prayers test/features/prayers`: no issues.

This batch does not establish production readiness. Device notification delivery,
release credentials, remaining blueprint findings, and full release verification
still require work.
