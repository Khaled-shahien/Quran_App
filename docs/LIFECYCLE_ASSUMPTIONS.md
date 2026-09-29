# Lifecycle Assumptions

This document records the expected behavior of app-scoped state across backgrounding, resume, restart, and system scheduling.

## App Resume

- `AppRoot` remains the owner of app-scoped providers and the prayer clock timer.
- The timer is cancelled when the root is disposed.
- The root removes its `WidgetsBindingObserver` before disposal completes.
- When the app resumes and a valid prayer location exists, prayer data may refresh from the repository.
- Resume refresh must not clear persisted location, calculation method, or user settings.

## Background Scheduling

- WorkManager owns durable background reschedule execution.
- Notification scheduling remains behind `NotificationSchedulingCoordinator` for foreground settings changes.
- Background jobs read persisted alarm settings and only record a successful run after scheduling/replenishment completes.
- Failed background work remains retryable and must not advance the last-success timestamp.
- Near-duplicate background executions are throttled.

## Restart and Migration

- SharedPreferences is loaded before providers are created.
- `PreferenceSchema.migrate` runs after dependency injection and before optional monitoring/background services.
- Providers treat malformed persisted values as recoverable input and use safe defaults.
- A restart must preserve valid bookmark, alarm, prayer-location, theme, and khatma state.

## Verification

Automated coverage protects storage migration, malformed settings, scheduler delegation, and provider behavior. Physical device validation is still required for OEM background limits, reboot delivery, exact alarms, and notification permission behavior.
