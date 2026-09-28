# Production fix progress

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
