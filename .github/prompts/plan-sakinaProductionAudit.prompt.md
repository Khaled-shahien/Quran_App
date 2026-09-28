## Plan: Sakina Production Audit

This plan converts the attached audit brief into an evidence-led audit and implementation blueprint for the Flutter app. Static repository evidence establishes the feature and architecture baseline; runtime/device tests must validate behavior before any claim of production readiness.

**Steps**

### Phase 1 — Evidence Baseline
1. Inventory routes and feature modules from `lib/core/navigation/app_router.dart`, `lib/features/**`, `app_root.dart`, and startup initialization. Record each feature's entry point, purpose, dependencies, state persistence, and current loading/empty/error behavior.
2. Reconcile source, existing reports, manifests, and CI/release checks. Mark each statement as verified, suspected, recommended, or not verifiable; specifically reconcile the resolved `/khatma` route finding against historical reports.
3. Establish the baseline with `flutter analyze`, unit/widget tests, integration tests, content verification, and release verification scripts. Preserve failures and environment prerequisites as audit evidence.

### Phase 2 — Core Flow and Runtime Validation
4. Test launch, onboarding, home, Quran/search/reader/bookmark, prayer/location, Qibla, duas/adhkar/hadith, tasbeeh, khatma, media, settings, and notification deep-link journeys. Cover back navigation, restart/background/terminated re-entry, missing data, retry, offline, slow network, permission denial/revocation, and timezone/DST changes.
5. Validate notification behavior on supported Android/iOS devices or simulators: permission timing, exact alarms, channels, scheduling, duplicate prevention, reboot/update recovery, closed-app future prayer schedules, FCM tap routing, token lifecycle, and user preferences/quiet hours. Treat delivery reliability as unverified until observed.
6. Validate responsive and accessibility behavior at small/large phone sizes and increased text scale: overflow, safe areas, semantics, focus order, touch targets, contrast, reduced motion, Arabic bidi/RTL, landscape, keyboard/input, and system UI.

### Phase 3 — Content, Privacy, and Release Configuration
7. Obtain and document authoritative content provenance, editions, translations, hadith grading, attribution, licensing, repetition counts, Arabic review, and owner approval. Update the content governance process and manifest semantics without treating hashes as authenticity proof.
8. Confirm production Android/iOS identifiers, Firebase project files, API keys/secrets, signing credentials, app backup/privacy behavior, third-party data flows, logging redaction, and external media quotas/licenses. Keep release verification fail-closed.
9. Resolve the onboarding/notification-permission state coupling by defining independent persisted states and a clear first-run permission strategy, subject to product approval.

### Phase 4 — Remediation Backlog
10. P0/P1 fixes: production identities/signing/configuration; approved religious content and licensing; notification schedule recovery while closed; FCM token backend contract and deletion lifecycle; privacy-sensitive logging review; startup failure policy; onboarding state separation; critical flow/error recovery defects found by runtime tests.
11. P1/P2 quality work: complete loading/empty/error/offline/partial/success/permission states; centralize hard-coded strings and localization policy; standardize theme/design tokens, RTL directionality, accessibility semantics, and typography; verify tasbeeh persistence/reset; improve SharedPreferences schema/versioning and corruption recovery where needed.
12. P2/P3 product and polish work only where evidence supports it: search enhancements, settings organization, notification history/quiet hours, caching/performance, media fallback behavior, and feature discoverability. Do not redesign working flows without a measured problem.

### Phase 5 — QA, Observability, and Release Gates
13. Add focused unit/widget tests for newly fixed state machines and persistence, integration tests that boot `main()`/`AppRoot`, and platform/device suites for notifications, permissions, sensors, network failures, localization/RTL, accessibility, and release configuration.
14. Define privacy-minimal analytics and crash/performance observability: app launch, onboarding, feature completion, search, notification open, errors, latency/startup, and retention events only with documented consent and data minimization.
15. Produce the final audit report using the requested sections: executive summary, feature inventory, user flows, IA, UI/UX/design system, light/dark, Arabic/RTL, accessibility, religious content, notifications, functional/edge/error/state audits, search/settings/onboarding/home, performance, security/privacy, architecture/code quality/testing, QA matrix, gaps, production readiness, prioritized issues, root causes, roadmap, backlog, acceptance criteria, release gates, and final checklist.

**Relevant files**
- `lib/core/navigation/app_router.dart` — verified route inventory and notification deep-link destinations.
- `lib/core/app/app_root.dart` and `lib/core/initialization/app_initializer.dart` — locale/RTL policy, global providers, startup sequencing, and failure handling.
- `lib/core/services/notification_service.dart`, `firebase_messaging_service.dart`, and `workmanager_service.dart` — local/remote notification scheduling, token lifecycle, background/reboot behavior, and logging.
- `lib/features/**` — feature-specific user journeys, state handling, persistence, and UI states.
- `pubspec.yaml`, `l10n.yaml`, `lib/l10n/app_ar.arb` — dependencies and localization scope.
- `assets/**`, `content_manifest.json`, `scripts/verify_content.py`, `docs/PRIVACY_AND_CONTENT.md` — content inventory, integrity checks, governance, and privacy claims.
- `android/app/src/main/AndroidManifest.xml`, iOS Runner configuration, `lib/core/constants/api_keys.dart`, `scripts/verify_release.py`, CI workflows, and signing configuration — platform permissions, secrets, identifiers, and release gates.
- `test/**` and `integration_test/**` — current automated coverage and required gaps, especially real app startup coverage.
- `README.md`, `AUDIT_REPORT.md`, `NOTIFICATIONS_REPORT.md`, and `docs/**` — historical claims to reconcile with current implementation.

**Verification**
1. Run `flutter analyze`, targeted unit/widget suites, all integration tests, `python scripts/verify_content.py`, and `python scripts/verify_release.py` with production configuration intentionally absent/present as appropriate; record exact results.
2. Use Android and iOS runtime matrices for launch, permissions, notification delivery/deep links, reboot/update, timezone/DST, offline/slow network, location/sensor behavior, and background/terminated states.
3. Use accessibility scanners plus TalkBack/VoiceOver manual traversal, large-font and reduced-motion checks, contrast measurement, and RTL/localization screenshots at representative phone sizes.
4. Profile startup, frame rendering, scrolling, memory, network, and battery for Quran, prayer, media, and notification workloads; set measurable thresholds before release.
5. Security/privacy review must inspect release bundles and logs for identifiers, API keys, tokens, precise coordinates, notification payloads, and unintended data exposure; review third-party retention and backup behavior.
6. Release gates: zero unresolved Critical/P0 issues; approved content/provenance/licensing; correct production identities/Firebase/signing; passing core-flow regression; validated notifications; no critical accessibility/security findings; acceptable performance; crash/analytics monitoring and rollback procedure ready.

**Decisions**
- Treat the attached prompt as the requested audit/report scope, but execute it in evidence phases rather than asserting unverified runtime outcomes.
- Preserve the feature-oriented Provider/ChangeNotifier + GetIt + GoRouter architecture unless measurements or defects justify targeted refactoring.
- Keep release verification fail-closed; configure real production identities and credentials rather than weakening checks.
- Product scope is Arabic plus English; missing translation coverage and hard-coded user-facing strings are release-relevant findings. Generated Arabic localization alone does not establish bilingual support.
- The immediate deliverable is the complete audit report before implementation.
- Android physical-device validation is available; iOS device validation, Firebase production configuration, and signing credentials remain unconfirmed unless supplied later.
- Religious authenticity, scholarly review, licensing, and notification delivery are not inferred from code or hashes.
- Exclude unrelated rewrites, speculative features, competitor copying, and visual redesign without a concrete usability or business problem.

**Further Considerations**
1. Confirm whether the immediate deliverable is the complete audit report now or an audit execution plan followed by implementation. Recommended: approve this plan, then execute baseline and runtime evidence collection before producing the final report.
2. Confirm supported platforms/devices and whether physical Android/iOS devices, Firebase production configuration, content-owner review, and signing credentials are available; otherwise those areas remain explicitly Not Verifiable.
3. Confirm product localization scope: Arabic-only, or Arabic plus additional locales. This determines whether hard-coded strings are a release blocker or a post-launch backlog item.
