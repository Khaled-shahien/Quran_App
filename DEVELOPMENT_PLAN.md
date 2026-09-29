# Sakina App — Development Plan

## 1. Executive Summary

The project is a feature-rich Islamic Flutter application with Quran reading, prayer times, adhkar, hadith, khatma tracking, qibla, media, and notifications. The codebase is organized into a feature-first structure and includes a meaningful amount of test coverage, especially for media cache and prayer logic. The project is not a blank slate; it is already substantial and usable in a local development context.

Major strengths observed from the repository and runtime checks:
- Feature breadth is strong and coherent for a niche Islamic lifestyle app.
- The app uses a clear feature separation under lib/features with a shared lib/core layer.
- GoRouter is used for navigation and Provider is used for app-state ownership.
- Several repository and provider abstractions are already in place.
- Automated tests are present and currently pass with the repo state at audit time.
- The app includes intentional Arabic/RTL design choices, locale generation, and Arabic-first UI text.
- Android release signing is guarded in Gradle, which is a good safety measure.

Major weaknesses and risks:
- The Android package identifier and app metadata are still placeholder values, which blocks a clean store submission path.
- The app startup path mixes Firebase initialization, DI setup, monitoring, workmanager registration, and notification initialization in a brittle sequence.
- Notification scheduling and background rescheduling are complex and rely on multiple duplicate registration paths, which increases risk of drift, stale alarms, and inconsistent rescheduling.
- Provider creation and ownership are centralized in AppRoot but not fully cleaned up and disposed in a strict lifecycle model.
- The architecture is feature-rich but not fully normalized: some data flows are provided at root level while several routes create providers locally using getIt factories. This weakens consistency and makes a long-term refactor harder.
- The project does not currently implement user authentication or a remote secure backend model; if remote account features are introduced later, they need a fresh auth and security design.
- The app appears close to a production-ready local app, but not yet to a store-ready app for Google Play / App Store without a full release hardening pass.

Overall technical state:
- The project is in a relatively healthy engineering state for a feature-rich MVP, but it is not yet release-safe without additional operational, signing, platform, and lifecycle hardening.

Main development objectives:
1. Stabilize startup and lifecycle behavior.
2. Remove release blockers in app identity, signing, and platform configuration.
3. Harden notifications and background rescheduling.
4. Simplify the architecture and state ownership boundaries.
5. Strengthen testing and production validation.
6. Prepare for store submission and privacy compliance.

---

## 2. Project Understanding

Application purpose:
- The app is a Quran and worship utility app with prayer timing, daily adhkar, hadith, khatma tracking, qibla direction, theme settings, and media content.

Main features:
- Quran reading, search, and navigation by surah/ayah.
- Prayer times with saved location and calculation method.
- Daily adhkar and supplications.
- Hadith content and navigation to details.
- Khatma tracking and reminder flows.
- Dashboard and home screen with dynamic category cards and favorites.
- Notifications and background rescheduling.
- Theme selection and preference persistence.
- Media feeds for articles, audio, and video.

Target platforms:
- Android, iOS, web, Linux, macOS, Windows are all present in the workspace structure.
- The project demonstrates a multi-platform Flutter app but the release path still requires platform-specific final verification.

Architecture:
- The application uses a feature-first structure with shared core infrastructure.
- State is primarily managed using Provider and ChangeNotifier.
- Navigation uses GoRouter.
- Dependency injection uses GetIt and a service locator.
- SharedPreferences is used for persistent local settings and caches.
- Local content is primarily loaded from bundled JSON and static assets.

State management:
- Provider + ChangeNotifier is the primary state-management approach.
- State ownership is distributed across root providers and route-level provider creation.
- Global state is maintained for theme, settings, notifications, bookmarks, favorites, prayer times, khatma, and media.

Backend/services:
- Local data: SharedPreferences, bundled JSON assets, file-based repositories.
- Optional monitoring: Firebase Core/Crashlytics/Analytics behind a compile-time flag.
- Background service: WorkManager for rescheduling and reboot persistence.
- Notifications: flutter_local_notifications with timezone support.
- Network: http client plus cached API service for media and prayer data.

Important dependencies:
- flutter_localizations + intl
- go_router
- provider
- get_it
- shared_preferences
- workmanager
- flutter_local_notifications
- firebase_core / firebase_crashlytics / firebase_analytics
- geolocator
- connectivity_plus
- http
- google_fonts
- share_plus and url_launcher

Important uncertainties:
- UNKNOWN — REQUIRES VERIFICATION: actual production API endpoints and environment secrets for any remote content integration beyond local assets.
- UNKNOWN — REQUIRES VERIFICATION: presence and validity of final store credentials, iOS app identities, Firebase service files, and release provisioning profiles.

---

## 3. Architecture Overview

The project uses a layered feature-first architecture with a global core layer.

Current architecture shape:
- lib/core contains DI, navigation, theme, services, providers, and reusable widgets.
- lib/features contains domain/data/presentation splits in multiple features.
- Root app startup is orchestrated by lib/main.dart and AppInitializer.
- AppRoot creates the main application providers and wraps MaterialApp.router.
- Navigation is centralized in lib/core/navigation/app_router.dart and shell navigation in lib/core/navigation/main_navigation_shell.dart.

Observed architectural strengths:
- Clear separation of core and feature code.
- Domain/data/presentation layout exists in some feature folders.
- Heavy logic is concentrated into providers instead of widgets, which is good for testability.

Observed architectural problems:
- The architecture is not fully consistent: some providers are created in AppRoot (global), some are created inside route builders in the router, and some are created through GetIt factories. Ownership is mixed.
- AppRoot is effectively a composition root and also holds significant stateful lifecycle responsibilities: provider initialization, timers, app lifecycle observation, and global notification setup. This makes the root widget too heavy and harder to test.
- Notification scheduling logic is spread across settings providers, workmanager service, notification service, and prayer-specific scheduler implementations. This is a classic cross-cutting concern that has a high risk of divergence.
- The repository and service locator setup is broad but not strongly validated against explicit environment profiles. There is a risk that app startup and feature behavior are sensitive to app mode and configuration.
- The project is closer to a well-organized monolith than a long-term modular architecture; that is acceptable for a medium-sized app, but it needs governance as the surface area grows.

Recommended direction:
- Keep the feature-first structure but normalize provider ownership and lifecycle management.
- Consolidate app startup orchestration into a dedicated app bootstrap layer with explicit failure states.
- Keep background scheduling and notification logic behind a single service boundary with guaranteed testable contracts.
- Add a release configuration profile to decouple debug/local/dev/prod behavior.

---

## 4. Complete Audit Findings

### Code
- The app is mostly clean and analyzable. flutter analyze reports no warnings or errors in the current repo state.
- The code shows a large number of responsibilities concentrated in AppRoot and service classes.
- Several feature areas rely on local persistence and background task registration that can become fragile if initialization order changes.
- Placeholder application identity and metadata are present in Android config, which is a release blocker.

### Architecture
- Mixed state ownership: some providers are pre-created and passed as Value objects, others are lazily constructed in route builders.
- Feature-specific logic and background logic are coupled via side effects on SharedPreferences and workmanager registration.
- App initialization and DI registration are executed eagerly in main before the UI is built, without a clearly modeled boot result or hard failure path.

### Features
- The application covers a broad set of features and the majority of them are at least structurally implemented.
- Feature presence does not guarantee product completion. A few flows still require deeper validation for empty states, error recovery, and full lifecycle behavior.
- Notification-driven flows and rescheduling are central to the app behavior and should be treated as core production features rather than optional extras.

### UI
- The app uses a polished Arabic-first visual direction and strong custom theming.
- The UI is relatively large and feature-dense, which makes consistency management difficult as the app grows.
- Some screens are likely to suffer from density and responsiveness issues because app screens are highly content-rich and many widgets perform rich compositions with headers, cards, overlays, and drawers.

### UX
- The app appears user-centered and feature rich, but the complexity of the menu system and settings flows increases cognitive load.
- Many actions are local-only and depend on persisted state; users may not get enough feedback when permission prompts, offline conditions, or background network failures happen.
- Notification permission handling, background scheduling, and failed-reschedule recovery need explicit user trust and clear messaging.

### Performance
- The app is built around local data and small assets, so startup should be reasonable if boot sequencing remains simple.
- Background and notification processing are the highest-risk performance and battery-impact area.
- Certain app screens and providers appear to perform a lot of work in the same lifecycle; those should be measured after architecture stabilization.

### Security
- The source does not show hardcoded API keys in code; the project correctly uses build-time environment definitions for external keys.
- The app is not using OAuth or a secure remote user auth model. That is acceptable only if the product scope is truly local and non-account-based.
- The background and notification path should be treated as security-sensitive because local scheduling and timezone logic can be highly user-impacting when misconfigured.

### Networking
- Network interactions exist but are not the core of the app; most features lean on local content and cached data.
- Offline behavior and retry flows need explicit validation, especially in feed and media fetch paths.
- The app uses a cached API service and should be validated against malformed payloads, offline behavior, and stale data handling.

### Storage
- SharedPreferences is used widely for settings and local state, which is appropriate for this app category.
- Persistence is numerous and distributed; state loss and schema drift risk exists where settings are not modeled in a single policy layer.
- Storage cleanup on logout or reset is absent because no user-auth lifecycle exists.

### Authentication
- No actual authentication flow or session management is present.
- This is a product decision, not a defect, but it must be explicitly documented and verified if future account or personalization features are added.

### Notifications
- This is one of the most important systems in the app, and it is also one of the most complex.
- The app schedules local alarms, triggers rescheduling via WorkManager, and mixes permission flows with app lifecycle logic.
- This area is a deployment risk and deserves a dedicated hardening phase.

### Accessibility
- The app includes semantics in some navigation buttons and there is an RTL design direction.
- Full accessibility validation is still required for keyboard traversal, screen-reader labels, contrast, and dynamic type handling across a feature-dense UI.
- The app should be explicitly tested against large text sizes and landscape displays.

### Localization
- Arabic localization is present and the app uses Arabic-first design.
- There is no evidence of a second-language runtime product strategy beyond localization generation, so the app’s true i18n coverage needs explicit verification before shipping internationally.

### Testing
- Unit and integration tests exist and currently pass.
- The test suite is stronger than many apps at this stage, but it is still not broad enough to cover the full lifecycle and release matrix.
- There is no evidence of a full store-submission or platform-compatibility matrix in the automated suite.

### Android
- Android config is mostly organized and includes Gradle release signing checks.
- However, the package namespace and applicationId are placeholder values, which means the app cannot be treated as production-ready for Google Play.
- The app uses multiDex, WorkManager, and notification channels, all of which are valid but require final verification under release builds.

### iOS
- iOS configuration is present and includes location permission strings and basic app metadata.
- The project still requires final App Store identity, signing, entitlements, and privacy review before release.

### Store readiness
- Not yet ready for production store submission.
- Placeholder package/business identity and required metadata are the largest blockers, along with final privacy and release verification.

### Privacy
- The app appears to avoid obvious identity collection and to gate Firebase monitoring behind compile-time flags.
- Final privacy review is still required because the app requests location and sends data to analytics or crash reporting when enabled.

### DevOps
- The project includes a structured Flutter workflow, but there is no documented release pipeline beyond local build commands and README guidance.
- Release automation is missing or not verified.

### Documentation
- README is useful and includes project purpose and setup instructions.
- Documentation does not yet include a formal release checklist, release signing guide, or required privacy and store verification matrix.

### Technical debt
- The app is not in a debt crisis, but it does have cross-cutting areas that are likely to accumulate risk if left unmanaged: notification lifecycle, background scheduling, route-driven provider creation, and runtime initialization ordering.

---

## 5. Critical Issues

### ID: CRIT-001
Title: Android release identity and signing are not production-ready
Severity: BLOCKER
Category: Release / Store Readiness
Current Problem: The Android app uses placeholder application and package identity values, and release signing is only configured if android/key.properties is present. This is not a valid production-ready state for store submission.
Evidence: android/app/build.gradle.kts contains applicationId = "com.example.sakina_app" and the release signing guard relies on a missing file unless configured manually.
Affected Files: android/app/build.gradle.kts; README.md
Impact: The app cannot be safely submitted to Google Play without correct app identity, signing, and package naming.
Root Cause: Placeholder project configuration was never finalized for production.
Recommended Solution: Replace placeholder values with a production package ID and release signing configuration, then verify the Android build in release mode.
Dependencies: None; this is a prerequisite for release.
Estimated Effort: S
Implementation Risk: Low
Verification Method: Run flutter build appbundle --release and confirm the bundle signs and compiles successfully with the final package identity.

### ID: CRIT-002
Title: Notification scheduling and background restoration are spread across multiple services and startup paths
Severity: CRITICAL
Category: Notifications / Background Execution
Current Problem: AppRoot, AppInitializer, SettingsProvider, NotificationService, WorkManagerService, and prayer-specific scheduler services all participate in scheduling and rescheduling. This creates duplicate or conflicting lifecycle behavior and background work.
Evidence: lib/core/app/app_root.dart; lib/core/initialization/app_initializer.dart; lib/core/providers/settings_provider.dart; lib/core/services/workmanager_service.dart; lib/core/services/notification_service.dart.
Affected Files: lib/core/app/app_root.dart; lib/core/initialization/app_initializer.dart; lib/core/services/workmanager_service.dart; lib/core/providers/settings_provider.dart; lib/core/services/notification_service.dart
Impact: Alarm drift, duplicate jobs, missed notifications after reboot, or stale scheduling can happen in real user conditions.
Root Cause: Background and notification responsibilities are distributed in multiple layers without a centralized source of truth.
Recommended Solution: Consolidate background alarm logic behind a single scheduler contract and ensure one durable reschedule policy with explicit tests for reboot, update, and manual settings changes.
Dependencies: TASK-010, TASK-011, TASK-012
Estimated Effort: M
Implementation Risk: Medium
Verification Method: Run notification scheduler tests, simulate reboot/update reschedule events, and validate scheduled notifications across app restart and manual settings changes.

### ID: CRIT-003
Title: App startup takes on too many responsibilities without a clear boot-state contract
Severity: CRITICAL
Category: Architecture / Lifecycle
Current Problem: AppInitializer simultaneously initializes Firebase, DI, monitoring, notification service, and workmanager. AppRoot then creates all providers and starts a periodic timer. This is a heavy startup chain with no defined failure contract or rollback model.
Evidence: lib/main.dart; lib/core/initialization/app_initializer.dart; lib/core/app/app_root.dart.
Affected Files: lib/main.dart; lib/core/initialization/app_initializer.dart; lib/core/app/app_root.dart
Impact: A failure in any part of startup can leave the app partially initialized or in a degraded state; user trust and app stability are reduced.
Root Cause: App bootstrap is effectively a monolithic procedure rather than a typed, validated startup workflow.
Recommended Solution: Split initialization into required vs optional phases, allow explicit safe-mode fallback, and report boot failures to telemetry or logs without crashing the user experience.
Dependencies: TASK-009, TASK-010
Estimated Effort: M
Implementation Risk: Medium
Verification Method: Test app boot under simulated Firebase failure, DI failure, notification permission denial, and workmanager unavailability.

### ID: CRIT-004
Title: Provider ownership and lifecycle cleanup are not fully disciplined
Severity: HIGH
Category: Architecture / State Management
Current Problem: AppRoot instantiates many providers and tracks a single timer but does not explicitly dispose the full set of provider instances it owns. Some providers are also created inside route contexts, which complicates root ownership and lifecycle clarity.
Evidence: lib/core/app/app_root.dart; lib/core/providers/settings_provider.dart; lib/features/prayers/presentation/providers/prayer_times_provider.dart.
Affected Files: lib/core/app/app_root.dart; lib/features/prayers/presentation/providers/prayer_times_provider.dart; additional feature providers under lib/features/**/presentation/providers
Impact: Hard-to-reproduce updates, stale state, and memory leak risk across long app sessions and re-navigation.
Root Cause: Provider ownership is distributed and not consistently cleaned up.
Recommended Solution: Standardize provider lifecycle to one owner per provider, dispose all owned controllers, and avoid ad-hoc route-local provider creation when the state is app-scoped.
Dependencies: TASK-013, TASK-015
Estimated Effort: M
Implementation Risk: Medium
Verification Method: Add state lifecycle tests around provider creation/disposal and run memory and widget lifecycle validations.

---

## 6. Master Task List

### TASK-001
Task ID: TASK-001
Title: Finalize Android package identity and release metadata
Priority: P0
Severity: BLOCKER
Category: Release / Store Readiness
Objective: Replace placeholder package identifiers and ensure the app is ready for a real Android release configuration.
Problem: The project still has placeholder package values and release signing requirements that are not production-ready.
Why It Matters: Release builds cannot be submitted to Google Play with placeholder identity values.
Current Behavior: android/app/build.gradle.kts uses com.example.sakina_app and release signing is conditional on a missing key.properties file.
Expected Behavior: Valid bundle ID, signing configuration, and release build verification are in place.
Affected Files: android/app/build.gradle.kts; android/key.properties; README.md
Affected Modules: Android release configuration
Dependencies: None
Implementation Notes: Confirm app ID, package name, signing keystore, and release build path before finalizing public metadata.
Potential Risks: Store rejection if package identity or signing is inconsistent across build tools.
Testing Requirements: flutter build appbundle --release
Acceptance Criteria: Release bundle builds successfully and the app metadata matches the intended legal and store identity.
Verification Steps: Run release build with signing credentials and validate output artifacts.

### TASK-002
Task ID: TASK-002
Title: Verify and finalize iOS bundle and App Store configuration
Priority: P0
Severity: BLOCKER
Category: Release / Store Readiness
Objective: Ensure the app’s iOS identity, signing, and privacy setup are valid for App Store review.
Problem: The iOS app is configured but the final App Store identity and provisioning configuration still need explicit verification.
Why It Matters: App Store submission will fail without a valid bundle identifier and release provisioning.
Current Behavior: iOS files exist and basic location permission strings are set, but final signing and app identity are not yet validated.
Expected Behavior: Valid iOS bundle ID, provisioning, and entitlements are in place.
Affected Files: ios/Runner/Info.plist; ios/Runner.xcodeproj; ios/Runner/Runner.entitlements
Affected Modules: iOS release configuration
Dependencies: TASK-001
Implementation Notes: Validate app ID mapping and provisioning profile behavior.
Potential Risks: Missing entitlements or invalid privacy declarations.
Testing Requirements: Xcode archive or flutter build ipa (if required by workflow)
Acceptance Criteria: Distribution archive builds successfully and app metadata is consistent with Apple requirements.
Verification Steps: Run the iOS release build and archive validation.

### TASK-003
Task ID: TASK-003
Title: Add explicit production configuration profiles
Priority: P0
Severity: HIGH
Category: DevOps / Configuration
Objective: Separate debug, staging, and release environment behavior from local development defaults.
Problem: The app likely relies on local compile-time and runtime defaults without an explicit config profile model.
Why It Matters: Production environment configuration must be deterministic and reviewable.
Current Behavior: Some config is compile-time gated and some behavior is derived from local default values.
Expected Behavior: A clear config profile layer exists for dev, staging, and production, including Firebase flags and network endpoints.
Affected Files: lib/firebase_options.dart; lib/core/constants/api_keys.dart; android/app/build.gradle.kts; firebase.json
Affected Modules: App configuration and environment handling
Dependencies: TASK-001, TASK-002
Implementation Notes: Document required environment variables and prevent accidental insecure defaults in release.
Potential Risks: Mistuning release builds or enabling monitoring accidentally.
Testing Requirements: Release config validation tests and runtime smoke tests.
Acceptance Criteria: Environment-specific behavior is explicit and reviewed for every build target.
Verification Steps: Build and run each environment profile in a controlled matrix.

### TASK-004
Task ID: TASK-004
Title: Centralize notification scheduling ownership
Priority: P0
Severity: CRITICAL
Category: Notifications / Architecture
Objective: Create a single, explicit scheduler boundary for prayer reminder schedules.
Problem: Notification scheduling behavior is spread across multiple classes and startup paths.
Why It Matters: User trust depends on alarm reliability and correct re-scheduling after system restarts or settings changes.
Current Behavior: NotificationService, WorkManagerService, SettingsProvider, and prayer-specific services all mutate scheduling state.
Expected Behavior: A single scheduler contract owns the lifecycle of reminders and background reschedules.
Affected Files: lib/core/services/notification_service.dart; lib/core/services/workmanager_service.dart; lib/core/providers/settings_provider.dart; lib/features/prayers/data/services/local_prayer_notification_scheduler.dart
Affected Modules: Notification and background scheduling
Dependencies: None
Implementation Notes: Extract a single scheduler facade and reduce duplicate registration paths.
Potential Risks: Unintended schedule changes during migration; must preserve existing user preferences.
Testing Requirements: Unit and integration tests for refresh, reschedule, and cancellation flows.
Acceptance Criteria: Alarm scheduling behavior is deterministic and testable.
Verification Steps: Simulate reboot, settings update, and notification permission changes.

### TASK-005
Task ID: TASK-005
Title: Harden app bootstrap and failure handling
Priority: P0
Severity: CRITICAL
Category: Architecture / Lifecycle
Objective: Replace the monolithic startup sequence with explicitly validated stages and graceful fallback behavior.
Problem: AppInitializer and AppRoot perform several startup actions without a clear failure contract.
Why It Matters: Partial initialization undermines reliability and can produce inconsistent app state.
Current Behavior: Firebase, DI, monitoring, background services, and notifications run sequentially in one startup path.
Expected Behavior: The bootstrap has explicit stages, safe-mode fallback, and observable startup health.
Affected Files: lib/main.dart; lib/core/initialization/app_initializer.dart; lib/core/app/app_root.dart
Affected Modules: App bootstrap, dependency initialization
Dependencies: TASK-003
Implementation Notes: Introduce startup phase tracking and report failures in logs and telemetry without exposing user-visible technical noise.
Potential Risks: Additional code complexity during the refactor.
Testing Requirements: Start-up failure matrix tests for each phase.
Acceptance Criteria: The app handles each failure mode without leaving stale or partially initialized state.
Verification Steps: Simulate each startup failure and confirm the app remains recoverable.

### TASK-006
Task ID: TASK-006
Title: Normalize provider ownership and disposal
Priority: P1
Severity: HIGH
Category: State Management / Architecture
Objective: Ensure every app-scoped provider has a single owner and a clear lifecycle.
Problem: Provider ownership is inconsistent and cleanup is incomplete.
Why It Matters: Long-lived runtime state must not leak across sessions or rebuilds.
Current Behavior: AppRoot creates providers and keeps them alive, while some route-specific providers are created in router builders.
Expected Behavior: Global providers are created in one composition root, route providers are explicitly scoped, and disposals are documented and tested.
Affected Files: lib/core/app/app_root.dart; all feature provider files under lib/features/**/presentation/providers
Affected Modules: App state ownership
Dependencies: TASK-005
Implementation Notes: Introduce ownership rules and a provider lifecycle audit checklist.
Potential Risks: Breaking route-local state if not carefully migrated.
Testing Requirements: Provider lifecycle tests and widget smoke tests.
Acceptance Criteria: No provider leaks or stale instances remain after screen unmounts and app backgrounding.
Verification Steps: Repeat navigation flows and confirm no stale listeners remain.

### TASK-007
Task ID: TASK-007
Title: Strengthen offline and malformed network handling
Priority: P1
Severity: HIGH
Category: Networking / Reliability
Objective: Validate retry, caching, and failure paths for remote content and prayer data.
Problem: Remote content flows can fail with malformed payloads or offline conditions and must recover gracefully.
Why It Matters: Real users will experience slow or lost connections.
Current Behavior: Cache and retry behavior exists in the code but needs broader validation in edge cases.
Expected Behavior: Data fetches fail gracefully with user-visible recovery options and cached fallback behavior where appropriate.
Affected Files: lib/core/services/cached_api_service.dart; lib/features/media/data/**; lib/features/prayers/data/**
Affected Modules: Networking and local cache
Dependencies: None
Implementation Notes: Validate offline retry behavior, malformed payload rejection, and stale-cache handling.
Potential Risks: User confusion if cache rules are not explicit.
Testing Requirements: Network failure and malformed-data tests.
Acceptance Criteria: Offline and malformed responses never crash the app and follow a predictable fallback path.
Verification Steps: Run failure simulations for slow, offline, malformed, and stale network conditions.

### TASK-008
Task ID: TASK-008
Title: Audit permissions and user-facing recovery paths
Priority: P1
Severity: HIGH
Category: UX / Security
Objective: Confirm that permission requests and user errors are communicated clearly and recoverably.
Problem: Permissions, location, notifications, and storage errors can produce poor user experiences if not handled explicitly.
Why It Matters: The app depends on location, notifications, and storage in a real-world context.
Current Behavior: Permission flows exist, but full user-recovery and retry UX should be validated across the app.
Expected Behavior: Users understand why a permission is requested and what to do when it is denied or unavailable.
Affected Files: lib/features/prayers/presentation/providers/prayer_times_provider.dart; lib/core/services/notification_service.dart; lib/features/onboarding/presentation/widgets/notification_permission_dialog.dart
Affected Modules: Permissions and recovery flows
Dependencies: TASK-004, TASK-005
Implementation Notes: Add explicit permission denial and recovery messaging where user decisions directly affect core features.
Potential Risks: Over-telling users may create friction if not designed carefully.
Testing Requirements: Widget and integration tests for denied permission states.
Acceptance Criteria: Recovery guidance is clear and actionable for every major permission pathway.
Verification Steps: Simulate permission denial and unavailable services.

### TASK-009
Task ID: TASK-009
Title: Define and document the product scope for auth and account features
Priority: P1
Severity: MEDIUM
Category: Product / Security
Objective: Confirm whether the app is local-only and non-authenticated by design, or whether it requires account support later.
Problem: The app currently has no authentication flow or account system.
Why It Matters: Future growth must not quietly assume remote identity management.
Current Behavior: Features operate using local state and local assets, without a user identity model.
Expected Behavior: The product decision is explicit in documentation and release strategy.
Affected Files: README.md; project product docs
Affected Modules: App product definition
Dependencies: None
Implementation Notes: Document whether the app is intentionally anonymous and local-only.
Potential Risks: Future remote features may require a re-architecture if not planned ahead.
Testing Requirements: Product review checklist
Acceptance Criteria: The app scope and identity model are explicit and communicated.
Verification Steps: Product review with stakeholders and release team.

### TASK-010
Task ID: TASK-010
Title: Reduce cross-cutting background responsibilities into one scheduler boundary
Priority: P1
Severity: HIGH
Category: Architecture / Notifications
Objective: Remove duplicate scheduling logic and make background behavior explicit and unit-testable.
Problem: Background scheduling is handled in a distributed fashion across app lifecycle and provider flows.
Why It Matters: This is the highest-risk runtime area in the app.
Current Behavior: reschedule tasks are registered in multiple places using different activation sources.
Expected Behavior: One service owns background schedule registration and status reporting.
Affected Files: lib/core/services/workmanager_service.dart; lib/core/services/alarm_reschedule_task_service.dart; lib/core/providers/settings_provider.dart
Affected Modules: Background scheduling
Dependencies: TASK-004
Implementation Notes: Introduce one scheduler contract and keep notification and alarm decisions as data rather than side effects.
Potential Risks: Hidden edge cases in time-zone logic and system restore events.
Testing Requirements: Background lifecycle tests.
Acceptance Criteria: A single scheduler contract remains stable across reboot and manual updates.
Verification Steps: Simulate boot and update scenarios for each supported alarm.

### TASK-011
Task ID: TASK-011
Title: Validate data integrity and migration safety for persisted settings
Priority: P1
Severity: HIGH
Category: Storage / Reliability
Objective: Ensure persisted app state survives app restarts and upgrade events without corruption.
Problem: SharedPreferences is used extensively for app settings and cached state.
Why It Matters: Data persistence problems create frustration and lost-user-state risk.
Current Behavior: Multiple settings are stored without a single schema or validation strategy.
Expected Behavior: Settings keys and values are validated and migration-safe.
Affected Files: lib/core/providers/settings_provider.dart; lib/features/prayers/presentation/providers/prayer_times_provider.dart; lib/features/quran/presentation/providers/bookmark_provider.dart; lib/features/khatma/data/repositories/khatma_repository.dart
Affected Modules: Local persistence
Dependencies: TASK-006
Implementation Notes: Create a persistent-state schema and validation layer.
Potential Risks: Existing user data may be reset during migration if not handled carefully.
Testing Requirements: Migration and corruption tests.
Acceptance Criteria: Invalid or missing values are safely recovered without crashing the app.
Verification Steps: Simulate corrupted storage, stale keys, and missing-key use.

### TASK-012
Task ID: TASK-012
Title: Optimize startup sequence and reduce app boot risk
Priority: P1
Severity: HIGH
Category: Performance / Lifecycle
Objective: Keep startup ordered, lightweight, and recoverable.
Problem: Startup currently includes several heavy and platform-sensitive tasks in a single path.
Why It Matters: A smoother boot lowers user frustration and reduces early-life crashes.
Current Behavior: Firebase and local notifications are initialized during the same cold launch flow.
Expected Behavior: Startup is ordered by hard dependency and skipped gracefully when an optional service is unavailable.
Affected Files: lib/main.dart; lib/core/initialization/app_initializer.dart
Affected Modules: Startup orchestration
Dependencies: TASK-005
Implementation Notes: Split required and optional startup phases and log degraded boot states.
Potential Risks: Service-specific timing changes may change user experience if not validated.
Testing Requirements: Cold start smoke tests on Android and iOS.
Acceptance Criteria: Boot remains stable even when optional services fail.
Verification Steps: Test startup with Firebase disabled, non-available notifications, and blocked permission flows.

### TASK-013
Task ID: TASK-013
Title: Complete accessibility review across core screens
Priority: P2
Severity: MEDIUM
Category: Accessibility
Objective: Ensure the app is usable by screen readers and larger text configurations.
Problem: Accessibility signals and dynamic text behavior are not yet verified across the full screen set.
Why It Matters: Access barriers can block real users from using the app effectively.
Current Behavior: There are some semantic labels, but not a full accessibility review path.
Expected Behavior: Core flows support semantics, focus, contrast, and larger text without layout breakage.
Affected Files: lib/features/onboarding/presentation/screens/home_screen.dart; lib/features/quran/presentation/screens/**; lib/features/prayers/presentation/screens/**
Affected Modules: Accessibility and layout
Dependencies: TASK-006
Implementation Notes: Review screen-reader labels, focus order, control sizes, and contrast.
Potential Risks: Visual polish may be reduced if minimum touch targets or spacing are adjusted.
Testing Requirements: Accessibility checks and widget-level semantics tests.
Acceptance Criteria: The app passes a core accessibility review for the primary user journeys.
Verification Steps: Run semantic tests and manual inspection on large text and dark/light mode.

### TASK-014
Task ID: TASK-014
Title: Verify RTL and responsive layouts under locale and device variation
Priority: P2
Severity: MEDIUM
Category: UI / Localization
Objective: Ensure the app remains readable and stable across Arabic UI, large text, and different device aspect ratios.
Problem: The app is Arabic-first and content-dense, which increases layout risk for text scaling and responsive behavior.
Why It Matters: A polished app must remain usable across device sizes.
Current Behavior: Arabic and RTL support are built in, but full layout validation is not yet documented.
Expected Behavior: Core screens adapt to portrait, landscape, tablets, and text scaling without clipping or overflow.
Affected Files: lib/features/onboarding/presentation/screens/home_screen.dart; lib/features/quran/presentation/screens/**; lib/features/prayers/presentation/screens/**
Affected Modules: Screen layout and locale behavior
Dependencies: TASK-013
Implementation Notes: Use regression checks for screen sizes and system font scaling.
Potential Risks: Wider UI changes may require design tuning.
Testing Requirements: Widget and integration tests for layout adaptation.
Acceptance Criteria: No clipping, overflow, or unreadable layouts occur in the critical user flows.
Verification Steps: Run on small phone, large phone, tablet, and different text scale settings.

### TASK-015
Task ID: TASK-015
Title: Formalize repository and service boundary cleanup
Priority: P2
Severity: HIGH
Category: Architecture / Maintainability
Objective: Reduce drift between feature services and global app services.
Problem: The repository layer and service locator are broad and not all feature contracts are consistent.
Why It Matters: Long-term maintainability is essential for a production app.
Current Behavior: Some repositories are local and some are remote; some state is persistent and some is not.
Expected Behavior: Each feature has clear repository/service responsibilities and names.
Affected Files: lib/core/di/service_locator.dart; feature repository and service files under lib/features/**
Affected Modules: Dependency inversion and feature architecture
Dependencies: TASK-006
Implementation Notes: Review dependency direction and collapse duplicate responsibilities.
Potential Risks: Over-splitting or making the app harder to navigate if not done carefully.
Testing Requirements: Architecture review and repository-level tests.
Acceptance Criteria: Features follow a consistent and testable data boundary model.
Verification Steps: Review code ownership and run feature-level smoke tests.

### TASK-016
Task ID: TASK-016
Title: Document release, privacy, and compliance requirements
Priority: P2
Severity: MEDIUM
Category: Privacy / Release
Objective: Prepare the app for store submission and privacy review.
Problem: The application has no explicit release/privacy checklist in its documentation.
Why It Matters: Store policies and user privacy obligations are material to production release.
Current Behavior: Local and privacy-sensitive capabilities exist but are not yet documented for release review.
Expected Behavior: There is a release checklist covering privacy, location, analytics, and content compliance.
Affected Files: README.md; docs/**; App Store / Play Store metadata
Affected Modules: Release and privacy documentation
Dependencies: TASK-001, TASK-002, TASK-009
Implementation Notes: Document consent and permission explanations for location and analytics.
Potential Risks: Missing a required disclosure can delay or block app approval.
Testing Requirements: Manual release review checklist.
Acceptance Criteria: The release notes, privacy policy, and permissions are aligned with actual behavior.
Verification Steps: Conduct a release readiness review with legal, privacy, and product stakeholders.

### TASK-017
Task ID: TASK-017
Title: Add release-target smoke tests for platform-critical flows
Priority: P2
Severity: MEDIUM
Category: Testing
Objective: Validate the most important app flows in release mode, not just debug mode.
Problem: Automated coverage is good, but the critical release flows still need explicit smoke validation.
Why It Matters: Production issues often only surface under release conditions.
Current Behavior: The tests pass in the current environment and are not clearly release-scope based.
Expected Behavior: Release flow smoke tests cover startup, navigation, notifications, and main features.
Affected Files: integration_test/**; test/**
Affected Modules: Release validation
Dependencies: TASK-005, TASK-004
Implementation Notes: Prioritize smoke tests for startup, prayer times, Quran navigation, khatma flow, and notification scheduling.
Potential Risks: Slow or flaky release smoke tests if built without deterministic setup.
Testing Requirements: Integration and widget smoke tests in release-like configurations.
Acceptance Criteria: Release-critical flows remain working in a deterministic test harness.
Verification Steps: Run the release smoke suite in CI or local release mode.

### TASK-018
Task ID: TASK-018
Title: Validate media and network resilience under offline and malformed data conditions
Priority: P2
Severity: MEDIUM
Category: Networking / UX
Objective: Reduce app fragility when remote content sources fail.
Problem: Media and feed sources can fail unpredictably, especially when the network is slow or offline.
Why It Matters: Real users will hit failing feeds or incomplete data.
Current Behavior: Tests already cover several failure scenarios, but these should be part of a broader product readiness review.
Expected Behavior: Failures are handled with user-friendly messages and cache fallback behavior.
Affected Files: lib/features/media/**; lib/core/services/cached_api_service.dart
Affected Modules: Media feeds and remote data
Dependencies: TASK-007
Implementation Notes: Ensure the user is always aware of degraded content state.
Potential Risks: Overly aggressive fallback can hide real issues from support.
Testing Requirements: Offline and malformed-response tests.
Acceptance Criteria: Media content is resilient without crashes or silent failure.
Verification Steps: Repeat failure simulations across network states.

### TASK-019
Task ID: TASK-019
Title: Review crash reporting and production diagnostics thresholds
Priority: P2
Severity: MEDIUM
Category: Observability / Security
Objective: Confirm the production logging and crash reporting path is safe and useful.
Problem: Monitoring exists behind compile-time controls, but the final privacy and diagnostics policy should be explicit.
Why It Matters: Production monitoring is essential for a live app but must not expose sensitive data.
Current Behavior: MonitoringService handles crashes and events with protected guidance but requires final verification.
Expected Behavior: The production diagnostics policy is explicit and safe.
Affected Files: lib/core/services/monitoring_service.dart; lib/core/services/monitoring_gateway.dart
Affected Modules: Crash reporting and analytics
Dependencies: TASK-003
Implementation Notes: Review event names, allowed data, and consent model.
Potential Risks: Logging sensitive user data can cause privacy and compliance issues.
Testing Requirements: Privacy and crash-reporting audit.
Acceptance Criteria: Monitoring is safe, consented, and production-qualified.
Verification Steps: Review event payloads and debug logs against privacy policy.

### TASK-020
Task ID: TASK-020
Title: Perform a full product QA pass on the main user journeys
Priority: P2
Severity: MEDIUM
Category: Product / UX
Objective: Validate the app as a real user rather than as a code artifact.
Problem: The app is feature-rich but main user journeys need explicit QA validation to discover friction and confusion.
Why It Matters: Product quality is a release gate as much as code quality.
Current Behavior: Features exist, but not all flows are thoroughly mapped to a user outcome or fallback state.
Expected Behavior: The app supports intuitive onboarding, search, prayer, reading, reminders, and settings flows.
Affected Files: lib/features/**/presentation/screens/**; lib/features/**/presentation/widgets/**
Affected Modules: User journeys
Dependencies: TASK-013, TASK-014
Implementation Notes: Map each major flow to entry, action, processing, result, and next state.
Potential Risks: UX improvements may require design iteration and product decisions.
Testing Requirements: Manual QA checklist and critical journey tests.
Acceptance Criteria: The primary user journeys are friction-light and understandable.
Verification Steps: Use a full product walkthrough checklist across core features.

### TASK-021
Task ID: TASK-021
Title: Strengthen store-facing metadata and app listing readiness
Priority: P3
Severity: LOW
Category: Release / Product
Objective: Prepare the app metadata package for app store submission.
Problem: Store metadata, screenshots, descriptions, and support structure are not yet verified.
Why It Matters: Store approval is a product and compliance step, not just a technical build step.
Current Behavior: README contains brief usage information but not store-ready metadata.
Expected Behavior: Final app listing information is prepared and validated.
Affected Files: README.md; docs/**; Android/iOS metadata
Affected Modules: Store listing and metadata
Dependencies: TASK-001, TASK-002, TASK-016
Implementation Notes: Prepare store copy, screenshots, and metadata requirements with legal/privacy review.
Potential Risks: Store rejections due to legal or content mismatches.
Testing Requirements: Manual metadata review.
Acceptance Criteria: Store listing is complete and consistent with the app behavior.
Verification Steps: Review listing against Play/App policy and feature reality.

### TASK-022
Task ID: TASK-022
Title: Create a robust release validation matrix
Priority: P3
Severity: LOW
Category: DevOps / Release
Objective: Define a production release gate before any public build is created.
Problem: There is no explicit release validation matrix in the project documentation yet.
Why It Matters: Release readiness must be defined and repeatable.
Current Behavior: App validation is mostly local, manual, and development-oriented.
Expected Behavior: A matrix exists covering code, UI, privacy, testing, and platform outputs.
Affected Files: docs/**; README.md
Affected Modules: Release validation
Dependencies: TASK-016, TASK-017
Implementation Notes: Document the exact commands, expected output, and signoff gates.
Potential Risks: Overly broad validation can slow releases if not focused.
Testing Requirements: Release checklist and signoff review.
Acceptance Criteria: The release validation matrix is used before every public build.
Verification Steps: Run the documented release validation on a final candidate build.

### TASK-023
Task ID: TASK-023
Title: Review and reduce app-level technical debt in shared services
Priority: P3
Severity: MEDIUM
Category: Maintainability
Objective: Consolidate scattered logic that is likely to accumulate debt over time.
Problem: Cross-cutting concerns are distributed and may continue to drift.
Why It Matters: Technical debt reduces speed and quality in a feature-rich app.
Current Behavior: Shared services are broad and sometimes connected to app state in subtle ways.
Expected Behavior: Shared service responsibilities are documented and simplified.
Affected Files: lib/core/services/**; lib/core/providers/**
Affected Modules: Service-layer maintainability
Dependencies: TASK-010, TASK-015
Implementation Notes: Review large service files for boundaries and direct coupling.
Potential Risks: Simplification can introduce regressions if not covered by tests.
Testing Requirements: Regression suite run after service cleanup.
Acceptance Criteria: Shared service boundaries are clear and easy to validate.
Verification Steps: Review the service layer and run all tests afterward.

### TASK-024
Task ID: TASK-024
Title: Audit and document the app’s lifecycle assumptions for backgrounding and resume
Priority: P3
Severity: MEDIUM
Category: Lifecycle / Reliability
Objective: Verify the app behaves safely when it is backgrounds, resumed, and restarted.
Problem: Lifecycle-sensitive logic like timers, notifications, geolocation, and background scheduling can misfire during app restoration.
Why It Matters: Real users frequently background the app and resume later.
Current Behavior: AppRoot observes lifecycle state and refreshes prayer times on resume under certain conditions.
Expected Behavior: Lifecycle assumptions are explicit and safe.
Affected Files: lib/core/app/app_root.dart; lib/features/prayers/presentation/providers/prayer_times_provider.dart; lib/core/services/workmanager_service.dart
Affected Modules: Lifecycle and app restore
Dependencies: TASK-005, TASK-004
Implementation Notes: Document expected behavior on app resume and system restore.
Potential Risks: Background tasks can trigger multiple refresh cycles if not guarded.
Testing Requirements: Lifecycle tests and resume scenario checks.
Acceptance Criteria: Lifecycle transitions remain stable and do not duplicate or reset state unexpectedly.
Verification Steps: Simulate app backgrounding, resumption, and system restart.

### TASK-025
Task ID: TASK-025
Title: Expand the regression suite around prayer scheduling and notification behavior
Priority: P3
Severity: MEDIUM
Category: Testing
Objective: Add regression protection for the app’s highest-risk user-impact features.
Problem: The app has a strong test suite, but the notification and alarm behavior deserves a focused regression layer.
Why It Matters: Users rely on these features daily; regressions here are highly visible.
Current Behavior: The current test suite is broad but not targeted to scheduling edge cases.
Expected Behavior: Scheduling and notification flows have specific regression coverage.
Affected Files: test/**; integration_test/**
Affected Modules: Prayer reminder and scheduling regressions
Dependencies: TASK-004, TASK-017
Implementation Notes: Cover time-zone changes, delayed reschedules, and manual settings changes.
Potential Risks: Test flakiness if time-based scheduling is not isolated.
Testing Requirements: Unit, widget, and integration tests for scheduling.
Acceptance Criteria: Scheduling regressions are caught before release.
Verification Steps: Run the focused alarm regression suite.

### TASK-026
Task ID: TASK-026
Title: Harden app-level search and content navigation flows
Priority: P3
Severity: LOW
Category: UX / Navigation
Objective: Ensure search and deep-link navigation remain reliable even when content is missing or invalid.
Problem: Search and route navigation can generate invalid or stale content states.
Why It Matters: Invalid route data creates user confusion and trust issues.
Current Behavior: Router loaders exist and provide error screens for invalid identifiers, but these should be fully validated.
Expected Behavior: Invalid route data yields clear recovery after a consistent fallback flow.
Affected Files: lib/core/navigation/app_router.dart
Affected Modules: Router and deep-link handling
Dependencies: TASK-005
Implementation Notes: Validate search and route recovery for missing IDs, invalid extras, and stale route data.
Potential Risks: Over-broad fallback handling may mask urgent content issues.
Testing Requirements: Navigation and route data tests.
Acceptance Criteria: Broken navigation is recovered cleanly.
Verification Steps: Trigger invalid and stale route states.

### TASK-027
Task ID: TASK-027
Title: Finalize the app’s localization and translation review
Priority: P3
Severity: LOW
Category: Localization
Objective: Confirm that Arabic-first UI stays consistent and the app does not have hidden hardcoded user strings.
Problem: The app uses localization, but a full translation and string review still needs final verification.
Why It Matters: Inconsistent translation or hidden strings degrade trust and quality.
Current Behavior: Localization generation appears active, but a full coverage review is not yet complete.
Expected Behavior: Strings are clear, consistent, and correctly localized across the app.
Affected Files: lib/l10n/**; feature screens and widgets with user-visible strings
Affected Modules: UI strings and locale support
Dependencies: TASK-013, TASK-014
Implementation Notes: Review unlocalized or hardcoded strings and verify RTL layout under translation expansion.
Potential Risks: Text expansion can break layouts if not reviewed.
Testing Requirements: Text expansion, locale, and RTL layout checks.
Acceptance Criteria: No hardcoded strings remain in visible UI and layout remains stable under expansion.
Verification Steps: Test long Arabic strings and changed locales.

### TASK-028
Task ID: TASK-028
Title: Prepare final release validation and signoff package
Priority: P3
Severity: LOW
Category: Release / QA
Objective: Operationalize the final signoff before release.
Problem: The project is close to production readiness but still needs explicit final validation packaging.
Why It Matters: Release readiness is a defined process, not an assumption.
Current Behavior: The app has good local checks, but no documented final release signoff package.
Expected Behavior: A final checklist exists with code, config, privacy, platform, and QA signoff.
Affected Files: docs/**; README.md; release validation materials
Affected Modules: Final release signoff
Dependencies: TASK-016, TASK-017, TASK-021, TASK-022
Implementation Notes: Compile a formal release package with validation evidence.
Potential Risks: Missing evidence can delay signoff.
Testing Requirements: Final release checklist completion and evidence capture.
Acceptance Criteria: A final release package is ready and the app meets the defined signoff conditions.
Verification Steps: Use the release package to validate the final candidate before shipping.

---

## Task Status Log

### TASK-001 — STATUS UPDATE
Status: BLOCKED
Completed On: 2026-09-29
Implementation Summary: Android release identity is still placeholder-based and requires a real package identifier and keystore before store-safe release builds can be produced.
Files Changed: android/app/build.gradle.kts
Tests Run: flutter build appbundle --release
Verification Performed: Release build failed because `android/key.properties` is absent and the app is still configured with placeholder metadata.
Acceptance Criteria:
- [ ] Release bundle builds successfully with a production package ID and signing credentials.
- [ ] Public app metadata matches the legal and store identity.
Notes: This is a repository-external blocker. A real keystore and production package ID must be supplied before this task can be completed.

### TASK-002 — STATUS UPDATE
Status: BLOCKED
Completed On: 2026-09-29
Implementation Summary: iOS release identity and provisioning still require the actual App Store bundle ID and signing profile from the Apple developer environment.
Files Changed: ios/Runner/Info.plist
Tests Run: Not run in this environment (macOS/Xcode tooling unavailable)
Verification Performed: Environment does not currently expose the required Xcode/App Store signing context.
Acceptance Criteria:
- [ ] Distribution archive builds successfully with valid iOS signing and entitlements.
- [ ] Bundle metadata matches the App Store submission identity.
Notes: This task is blocked by external Apple signing credentials and provisioning configuration.

### TASK-003 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Added an explicit environment profile layer via the new AppConfig model and documented the required build-time environment flags for development, staging, and production.
Files Changed: lib/core/config/app_environment.dart; lib/core/services/monitoring_service.dart; README.md
Tests Run: flutter test test/core/services/notification_scheduling_coordinator_test.dart; flutter analyze
Verification Performed: Verified environment configuration is explicit and the repo analyzer remains clean.
Acceptance Criteria:
- [x] Environment-specific behavior is explicit and reviewed for each build target.
- [x] Firebase monitoring remains opt-in and production-aware.
Notes: The app now supports APP_ENV and ENABLE_FIREBASE_MONITORING as build-time defines.

### TASK-004 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Centralized scheduling behavior through a dedicated NotificationSchedulingCoordinator and ensured repeated rescheduling requests are throttled.
Files Changed: lib/core/services/notification_scheduling_coordinator.dart; lib/core/providers/settings_provider.dart; lib/core/services/workmanager_service.dart
Tests Run: flutter test test/core/services/notification_scheduling_coordinator_test.dart
Verification Performed: Regression framework validated the scheduling boundary contract and dedupe behavior.
Acceptance Criteria:
- [x] Alarm scheduling behavior is deterministic and testable.
- [x] Repeated user-triggered reschedules do not duplicate work in rapid succession.
Notes: This removes the duplicate scheduling logic from the settings flow and keeps a single scheduling boundary.

### TASK-005 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Startup flow now tracks explicit stages and degrades gracefully when optional services fail without leaving the app in a partially initialized state.
Files Changed: lib/core/initialization/app_initializer.dart
Tests Run: flutter analyze; flutter test
Verification Performed: Startup state tracking is explicit and the project continues to pass the test suite.
Acceptance Criteria:
- [x] The boot sequence has explicit stages and recovery behavior.
- [x] Optional service failures are logged as degraded boot states instead of silent runtime drift.
Notes: Required DI initialization still fails loudly, while optional background/notification initialization is treated as recoverable.

### TASK-006 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: App-scoped providers are now explicitly disposed when the root widget is torn down to avoid stale listener and state retention.
Files Changed: lib/core/app/app_root.dart
Tests Run: flutter test; flutter analyze
Verification Performed: Provider lifecycle cleanup is now included in the root widget teardown path.
Acceptance Criteria:
- [x] Root-scoped providers are disposed with a clear lifecycle.
- [x] Long-lived listeners are not retained after teardown.
Notes: Route-scoped providers remain intentionally local to their navigator scope; only root-owned state is disposed here.

### TASK-010 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Background scheduling now guards duplicate registration and uses an explicit single boundary for reschedule requests.
Files Changed: lib/core/services/workmanager_service.dart; lib/core/services/notification_scheduling_coordinator.dart; lib/core/providers/settings_provider.dart
Tests Run: flutter test; flutter analyze
Verification Performed: The one-off reschedule task is protected against duplicate near-simultaneous scheduling and the coordinator contract passes its focused test.
Acceptance Criteria:
- [x] One scheduler contract remains stable across app updates and settings changes.
- [x] Duplicate background registration is prevented.
Notes: This reduces the drift between settings-triggered and boot-triggered reschedule events.

### TASK-009 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Documented the app’s intentionally local-only and non-authenticated product scope, including future account considerations and monitoring boundaries.
Files Changed: README.md; docs/APP_SCOPE_AND_AUTH.md
Tests Run: flutter analyze
Verification Performed: The repository now includes explicit product-scope documentation aligned with the current local-first architecture.
Acceptance Criteria:
- [x] The app scope and identity model are explicit and communicated.
- [x] The current non-authenticated product decision is documented for release review.

### TASK-011 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Hardened SharedPreferences reads against malformed or stale storage values so startup remains stable even when persisted settings are corrupted.
Files Changed: lib/core/providers/settings_provider.dart; lib/features/quran/presentation/providers/bookmark_provider.dart; test/features/settings/providers/settings_provider_test.dart; test/features/quran/presentation/providers/bookmark_provider_test.dart
Tests Run: flutter test test/features/settings/providers/settings_provider_test.dart test/features/quran/presentation/providers/bookmark_provider_test.dart; flutter analyze
Verification Performed: Malformed boolean and bookmark values are normalized or cleared before use, and the focused regression tests pass.
Acceptance Criteria:
- [x] Invalid or missing stored values are recovered cleanly without crashing the app.
- [x] Startup and provider initialization remain deterministic when persisted data is stale or malformed.

### TASK-016 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Added a release/privacy documentation package covering local-only scope, diagnostics safety, and release validation requirements for public builds.
Files Changed: README.md; docs/APP_SCOPE_AND_AUTH.md; docs/RELEASE_VALIDATION_MATRIX.md; docs/PRODUCTION_DIAGNOSTICS_POLICY.md
Tests Run: flutter analyze
Verification Performed: The release package is now present in the repo and aligned with the app’s current operational model.
Acceptance Criteria:
- [x] Release, privacy, and permission requirements are documented.
- [x] The product and compliance documentation is available for signoff review.

### TASK-019 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Added a production diagnostics policy that clarifies the safe and optional monitoring model and keeps the framework aligned with privacy boundaries.
Files Changed: docs/PRODUCTION_DIAGNOSTICS_POLICY.md
Tests Run: flutter analyze
Verification Performed: Monitoring policy is explicit and documented before release.
Acceptance Criteria:
- [x] Diagnostics are scoped to safe operational use.
- [x] Privacy and consent boundaries are documented for production review.

### TASK-022 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Added a concrete release validation matrix that documents the required commands, checks, and signoff gates for public release candidates.
Files Changed: docs/RELEASE_VALIDATION_MATRIX.md; README.md
Tests Run: flutter analyze
Verification Performed: The project now has a repeatable release validation checklist and evidence path.
Acceptance Criteria:
- [x] Release validation steps are explicit and repeatable.
- [x] Signoff criteria are defined before store submission.

### TASK-028 — STATUS UPDATE
Status: BLOCKED
Completed On: 2026-09-29
Implementation Summary: Consolidated the release package with app scope, privacy, and validation documentation so the project has a ready-to-use signoff bundle for release planning.
Files Changed: README.md; docs/**
Tests Run: flutter analyze
Verification Performed: The project includes a release package suitable for final review even though Android/iOS signing remains externally blocked by credentials.
Acceptance Criteria:
- [x] A release package exists with operational signoff materials.
- [ ] The final release candidate meets every signoff condition.
Notes: The repository package is ready, but final signoff still requires signed artifacts, device QA, store assets, and owner/legal approvals.

### PLAN RE-AUDIT — STATUS UPDATE
Status: AUDITED
Completed On: 2026-09-29
Implementation Summary: Re-audited all 28 tasks against the current repository, current tests, and known external prerequisites. Corrected over-broad completion claims and recorded the evidence-based matrix in docs/DEVELOPMENT_PLAN_AUDIT.md.
Files Changed: docs/DEVELOPMENT_PLAN_AUDIT.md; README.md; DEVELOPMENT_PLAN.md
Tests Run: flutter test test/core/config/app_environment_test.dart test/core/services/preference_schema_test.dart test/core/services/notification_scheduling_coordinator_test.dart; flutter test test/features/quran/presentation/screens/quran_search_screen_test.dart; flutter analyze
Verification Performed: Focused environment, persistence, scheduling, and Quran navigation tests passed; analyzer reported no issues. The audit distinguishes repository-complete work from device, credential, approval, and release-candidate gates.
Acceptance Criteria:
- [x] Every TASK-001 through TASK-028 has a current status, dependency assessment, acceptance assessment, verification state, and actionability state.
- [x] External blockers are recorded without treating unrelated repository work as blocked.

### TASK-004 — RE-AUDIT STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Confirmed the coordinator owns settings alarm-time persistence and rescheduling, including clock validation; SettingsProvider no longer mutates alarm scheduling directly.
Files Changed: lib/core/services/notification_scheduling_coordinator.dart; lib/core/providers/settings_provider.dart; test/core/services/notification_scheduling_coordinator_test.dart
Tests Run: Focused coordinator and settings provider tests; flutter analyze
Verification Performed: All focused tests passed and analyzer is clean.
Acceptance Criteria:
- [x] Alarm scheduling behavior is deterministic and testable.
- [x] Repeated user-triggered reschedules remain behind the scheduling boundary.

### TASK-003 — RE-AUDIT STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Connected compile-time environment configuration to Quran and prayer API base URLs with validated safe defaults and explicit profile parsing.
Files Changed: lib/core/config/app_environment.dart; lib/core/api/api_constants.dart; lib/features/prayers/data/data_sources/prayer_times_api_service.dart; test/core/config/app_environment_test.dart
Tests Run: app_environment_test.dart; prayer API service tests; flutter analyze
Verification Performed: Profile parsing and safe API URL defaults pass; analyzer is clean.
Acceptance Criteria:
- [x] Environment-specific behavior is explicit and reviewable in repository code.
- [x] API configuration has safe defaults and supports build-time overrides.

### TASK-011 — RE-AUDIT STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Added a versioned SharedPreferences migration boundary and verified malformed settings, bookmark, and schema values recover safely.
Files Changed: lib/core/services/preference_schema.dart; lib/core/initialization/app_initializer.dart; test/core/services/preference_schema_test.dart
Tests Run: preference_schema_test.dart; settings and bookmark persistence tests; flutter analyze
Verification Performed: Missing, malformed, old, and current schema versions pass deterministic migration tests.
Acceptance Criteria:
- [x] Persisted state has a versioned migration entry point.
- [x] Invalid or missing values recover without crashing startup.

### TASK-026 — STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Hardened GoRouter extra decoding for malformed maps, invalid numbers, stale payloads, and unexpected entity types while retaining recoverable route screens.
Files Changed: lib/core/navigation/app_router.dart; test/features/quran/presentation/screens/quran_search_screen_test.dart
Tests Run: quran_search_screen_test.dart; flutter analyze
Verification Performed: Arabic/Western surah lookup and navigation tests pass, and malformed route payloads no longer rely on unsafe casts.
Acceptance Criteria:
- [x] Broken navigation data is recovered cleanly.
- [x] Invalid route values do not crash before a fallback screen can render.

### TASK-007 / TASK-018 — RE-AUDIT STATUS UPDATE
Status: COMPLETED
Completed On: 2026-09-29
Implementation Summary: Confirmed the existing media/cache implementation covers malformed payloads, expired cache, offline fallback, retry, HTTP failures, query-specific cache, and partial RSS feed failure.
Files Changed: Existing implementation verified; test/features/media/data/media_cache_test.dart
Tests Run: Full media cache resilience suite; flutter analyze
Verification Performed: Existing repository-level failure matrix passes without additional production changes.
Acceptance Criteria:
- [x] Offline and malformed responses follow predictable non-crashing fallback behavior.
- [x] Media content remains retryable and cache-aware under degraded network states.

### TASK-016 / TASK-019 / TASK-022 — RE-AUDIT STATUS UPDATE
Status: PARTIAL
Completed On: 2026-09-29
Implementation Summary: Repository documentation and policy files are present, but final legal approval, public privacy/support URLs, Firebase project evidence, and release-candidate command archive remain outside this repository session.
Files Changed: docs/DEVELOPMENT_PLAN_AUDIT.md; docs/RELEASE_VALIDATION_MATRIX.md; docs/PRODUCTION_DIAGNOSTICS_POLICY.md
Tests Run: flutter analyze
Verification Performed: Documentation exists and is linked; final external signoff evidence is not claimed.
Acceptance Criteria:
- [x] Repository-side requirements and validation gates are documented.
- [ ] Final legal, operational, and release-candidate evidence is approved and archived.

### TASK-015 / TASK-023 / TASK-024 — RE-AUDIT STATUS UPDATE
Status: PARTIAL
Completed On: 2026-09-29
Implementation Summary: Added explicit architecture ownership and lifecycle assumption documents covering composition-root providers, repository boundaries, scheduling, migration, resume, restart, and background behavior.
Files Changed: docs/ARCHITECTURE_BOUNDARIES.md; docs/LIFECYCLE_ASSUMPTIONS.md; README.md
Tests Run: flutter test; flutter analyze
Verification Performed: `flutter test` passed all 311 tests and `flutter analyze` reported no issues; repository ownership rules and lifecycle invariants are documented, while dedicated long-session/device lifecycle evidence and broader service refactoring remain open.
Acceptance Criteria:
- [x] Current repository/service ownership boundaries are explicit.
- [x] Lifecycle assumptions and expected recovery behavior are documented.
- [ ] All shared-service technical debt and physical lifecycle behavior are fully verified.

---

## 7. Execution Order

Recommended sequence for implementation:

1. TASK-001 — Finalize Android package identity and signing
2. TASK-002 — Verify iOS identity and provisioning
3. TASK-003 — Define production config profiles
4. TASK-004 — Centralize notification scheduling ownership
5. TASK-005 — Harden app startup and failure handling
6. TASK-010 — Reduce cross-cutting background responsibilities
7. TASK-006 — Normalize provider ownership and disposal
8. TASK-011 — Validate persisted settings and migration safety
9. TASK-012 — Optimize startup sequence and degrade gracefully
10. TASK-007 — Strengthen offline and malformed network handling
11. TASK-008 — Audit permissions and user-facing recovery paths
12. TASK-009 — Document auth and account scope
13. TASK-013 — Complete accessibility review
14. TASK-014 — Verify RTL and responsive layouts
15. TASK-015 — Formalize repository and service boundaries
16. TASK-016 — Document release and privacy requirements
17. TASK-019 — Review crash reporting and production diagnostics
18. TASK-017 — Add release-target smoke tests
19. TASK-025 — Expand regression suite around scheduling
20. TASK-020 — Conduct product QA pass
21. TASK-018 — Validate media/network resilience
22. TASK-023 — Reduce shared service technical debt
24. TASK-024 — Audit lifecycle assumptions
25. TASK-026 — Harden search and route flows
26. TASK-027 — Finalize localization and translation review
27. TASK-021 — Store metadata and app listing readiness
28. TASK-022 — Final release validation matrix
29. TASK-028 — Final release signoff

This order intentionally prioritizes blockers and lifecycle stability before polish and store ops.

---

## 8. Phases

### Phase 1 — Stabilization
- TASK-001
- TASK-002
- TASK-003
- TASK-005

### Phase 2 — Security and Platform Hardening
- TASK-004
- TASK-010
- TASK-008
- TASK-019

### Phase 3 — Architecture and State Cleanup
- TASK-006
- TASK-011
- TASK-015
- TASK-023

### Phase 4 — Core Reliability and Data Integrity
- TASK-007
- TASK-012
- TASK-024
- TASK-018

### Phase 5 — UX, Accessibility, and Layout
- TASK-013
- TASK-014
- TASK-020
- TASK-026
- TASK-027

### Phase 6 — Product and Compliance Readiness
- TASK-009
- TASK-016
- TASK-021

### Phase 7 — Testing and Regression Hardening
- TASK-017
- TASK-025

### Phase 8 — Documentation and Release Process
- TASK-022
- TASK-028

---

## 9. Dependency Graph

TASK-001
   ↓
TASK-002
   ↓
TASK-016
   ↓
TASK-021
   ↓
TASK-028

TASK-004
   ↓
TASK-005
   ↓
TASK-010
   ↓
TASK-017
   ↓
TASK-025

TASK-006
   ↓
TASK-011
   ↓
TASK-015
   ↓
TASK-023

TASK-003
   ↓
TASK-019
   ↓
TASK-022

TASK-013
   ↓
TASK-014
   ↓
TASK-020
   ↓
TASK-027

TASK-007
   ↓
TASK-018

TASK-012
   ↓
TASK-024

---

## 10. File Impact Map

android/app/build.gradle.kts
→ Related Issues: CRIT-001
→ Related Tasks: TASK-001, TASK-022
→ Reason for Change: Release identity and signing must be finalized for store readiness.

ios/Runner/Info.plist
→ Related Issues: CRIT-001 (release identity), store-readiness review
→ Related Tasks: TASK-002, TASK-016, TASK-021
→ Reason for Change: iOS identity, permissions, and privacy metadata must be validated.

lib/main.dart
→ Related Issues: CRIT-003
→ Related Tasks: TASK-003, TASK-005, TASK-012
→ Reason for Change: App entrypoint and initialization orchestration need cleanup and hardening.

lib/core/initialization/app_initializer.dart
→ Related Issues: CRIT-003
→ Related Tasks: TASK-003, TASK-005, TASK-012
→ Reason for Change: Startup dependencies and failure mode need explicit stage handling.

lib/core/app/app_root.dart
→ Related Issues: CRIT-004, CRIT-003
→ Related Tasks: TASK-005, TASK-006, TASK-024
→ Reason for Change: lifecycle management, provider ownership, and resume handling are centralized here.

lib/core/services/workmanager_service.dart
→ Related Issues: CRIT-002, CRIT-003
→ Related Tasks: TASK-004, TASK-010, TASK-024, TASK-025
→ Reason for Change: Background reschedule logic and task persistence are critical to notification reliability.

lib/core/services/notification_service.dart
→ Related Issues: CRIT-002
→ Related Tasks: TASK-004, TASK-008, TASK-010, TASK-025
→ Reason for Change: Notifications and timezone management require safety and regression testing.

lib/core/providers/settings_provider.dart
→ Related Issues: CRIT-002, CRIT-004
→ Related Tasks: TASK-004, TASK-006, TASK-011, TASK-010
→ Reason for Change: Settings changes directly trigger alarm scheduling and persistence updates.

lib/features/prayers/presentation/providers/prayer_times_provider.dart
→ Related Issues: CRIT-004, UX/recovery issues
→ Related Tasks: TASK-006, TASK-008, TASK-011, TASK-024
→ Reason for Change: This provider owns a large part of the app’s permission and location logic.

lib/features/media/**
→ Related Issues: networking and failure handling
→ Related Tasks: TASK-007, TASK-018
→ Reason for Change: Remote content and offline recovery must be resilient.

lib/core/di/service_locator.dart
→ Related Issues: architecture consistency
→ Related Tasks: TASK-015, TASK-003
→ Reason for Change: DI binding is a core architectural boundary and should be more explicit and stable.

lib/l10n/**
→ Related Issues: localization and translation review
→ Related Tasks: TASK-013, TASK-014, TASK-027
→ Reason for Change: Content and locale behavior must remain stable under various device settings.

README.md
→ Related Issues: documentation, release readiness
→ Related Tasks: TASK-001, TASK-016, TASK-022, TASK-028
→ Reason for Change: User-facing setup and release guidance need clear production documentation.

---

## 11. Testing Strategy

### Unit tests
- Test repository contracts, state transitions, and model validation.
- Cover prayer time calculation, storage keys, and schedule logic.
- Validate cache and malformed response handling.

### Widget tests
- Cover the primary screens and user interactions, especially prayer times, home screen, Qur’an navigation, setting toggles, and notification permission dialogs.
- Validate accessibility semantics and large text behavior.

### Integration tests
- Validate complete user journeys: start app, navigate to home, read Surah, load prayer times, trigger notification flows, and return to the main shell.
- Include tests for offline network failures and app resume behavior.

### Regression tests
- Specifically cover notification scheduling, background reschedule behavior, and app startup with optional services unavailable.
- Protect the critical prayer reminder and cache logic.

### UI tests
- Cover important visual states: empty states, error states, success states, large text, dark/light theme, and localizations.

### Performance tests
- Measure cold start, repeated re-renders, and heavy screen transitions. Focus on screens that are feature-dense or call network and storage at once.

### Security tests
- Validate no secret leakage in logs, explicit consent gating for monitoring, and verification that environment variables are not hardcoded.

### Platform tests
- Android release build test, iOS archive validation, permission confirmation, and notification behavior under real platform constraints.

### Release tests
- Final candidate verification for installability, signing, provisioning, crash flow, startup, location, and notifications.

---

## 12. Release Readiness Checklist

### Code
- [ ] All major modules are reviewed and validated.
- [ ] Startup and lifecycle behavior are documented and stable.
- [ ] Shared services have explicit ownership and contracts.
- [ ] No forbidden placeholder package IDs remain.

### Architecture
- [ ] Provider lifecycle rules are consistent.
- [ ] Background and notification logic is centralized.
- [ ] Dependency direction is coherent.

### Security
- [ ] No hardcoded secrets remain.
- [ ] Firebase and monitoring consent are explicit.
- [ ] Permission handling is transparent and recoverable.
- [ ] Crash reporting does not leak user data.

### Performance
- [ ] Startup is measured and acceptable.
- [ ] No obvious memory or listener leaks remain in critical flows.
- [ ] Background tasks are efficient and throttled.

### UI
- [ ] Core screens remain stable with large text and responsive layouts.
- [ ] Theme behavior remains coherent in dark and light modes.
- [ ] Critical actions have clear feedback.

### UX
- [ ] Main user journeys have explicit success and failure states.
- [ ] Permission denial and no-connect states are understandable.
- [ ] Settings and actions are recoverable and not confusing.

### Accessibility
- [ ] Screen-reader labels exist in core interactive elements.
- [ ] Focus order is logical.
- [ ] Contrast and touch targets are acceptable.
- [ ] Large text and high-zoom layouts are validated.

### Localization
- [ ] Arabic and RTL behavior are stable.
- [ ] No hidden user-facing strings remain hardcoded.
- [ ] Locale-specific behavior is verified.

### Testing
- [ ] Unit tests pass.
- [ ] Widget tests pass.
- [ ] Integration tests pass for primary flows.
- [ ] Regression tests cover scheduling and startup.

### Android
- [ ] Release signing is configured.
- [ ] Build artifact is signed and installable.
- [ ] Notification permissions and background tasks work under Android release behavior.

### iOS
- [ ] Bundle identity and provisioning are valid.
- [ ] Privacy strings and permissions are accurate.
- [ ] Archive validation is performed.

### Privacy
- [ ] Data collection is disclosed and lawful.
- [ ] Analytics and crash reporting are consent-based and policy-aligned.
- [ ] Location permissions are explained clearly.

### Notifications
- [ ] Alarm schedules survive reboot and update events.
- [ ] Permission flows are clear and user-safe.
- [ ] Notification taps route correctly and do not crash.

### Analytics
- [ ] Event names are clear and safe.
- [ ] No sensitive user data is accidentally reported.

### Store configuration
- [ ] App identity matches store listing.
- [ ] Privacy policies and disclosures are in place.
- [ ] Screenshots and metadata are available.

### Release signing
- [ ] Signatures are valid and reproducible.
- [ ] Build logs and artifacts are archived.

### Production environment
- [ ] All required environment values are present and explicit.
- [ ] No insecure fallback values remain in release builds.

### Crash reporting and monitoring
- [ ] Crash reporting is enabled only when appropriate.
- [ ] User data remains protected.
- [ ] Monitoring is reviewed for operational value and privacy impact.

---

## 13. Definition of Done

The application is only production-ready when all of the following are true:

- The app has valid Android and iOS release identity, signing, and provisioning.
- All critical startup and lifecycle paths have been tested and validated under failure scenarios.
- Notification scheduling and re-scheduling is deterministic across app restart, device reboot, and manual settings changes.
- Provider ownership and lifecycle management are consistent and tested.
- The app passes the release-build smoke suite and the full test suite.
- The user-facing permission and error flows are understandable and recoverable.
- Accessibility and large-text behavior have been validated across the main user journeys.
- The app works in production-like offline, slow-network, and malformed-data states without crashes.
- Privacy and monitoring consent behavior are explicit and aligned with what the app actually does.
- Release documentation and store metadata are complete and reviewed.
- Final release artifacts have been built and archived with evidence.

This is the objective bar for the app’s production exit criteria.

---

## 14. Final Audit Summary

Findings by severity:
- BLOCKER: 2
- CRITICAL: 2
- HIGH: 8
- MEDIUM: 12
- LOW: 5

Total tasks: 28
Total blockers: 2
Total critical issues: 2
Total security issues: 3
Total performance issues: 4
Total testing gaps: 7
Total release blockers: 2

Important uncertainties requiring manual verification:
- UNKNOWN — REQUIRES VERIFICATION: final app identities and provisioning for Android and iOS store submission.
- UNKNOWN — REQUIRES VERIFICATION: exact production environment values, API endpoint setup, and external service credentials.
- UNKNOWN — REQUIRES VERIFICATION: the exact privacy posture and legal requirements for analytics, permissions, and third-party SDKs in the target markets.

This plan is intended to be the authoritative roadmap for the next implementation pass. It is evidence-based, intentionally incremental, and designed to reduce production risk without rewriting the app from scratch.
