# App Scope and Authentication Policy

## Product Scope

This application is intentionally designed as a local-first Islamic utility app. It provides Quran reading, prayer times, adhkar, hadith, khatma tracking, qibla guidance, and local settings without relying on a hosted user identity or account system.

The app stores user preferences and local progress in `SharedPreferences` and local JSON assets. There is no current customer identity model, no login flow, and no remote session management.

## Authentication Decision

As of the current product scope, the app is intentionally non-authenticated. This is not an accidental gap; it is a product contract.

- No username/password flow
- No OAuth or SSO integration
- No remote profile data persistence
- No account resets or session invalidation logic required by the app today

This keeps the build simpler, reduces security risk, and aligns with the app’s local-first architecture.

## Future Considerations

If a future release introduces account features, the project should add a fresh auth design before shipping. That design must include:

- secure backend API boundaries
- user consent and privacy review
- token/session storage guidance
- password reset, account deletion, and export controls
- admin and support flows where relevant

## Monitoring and Analytics

Firebase monitoring remains optional and compile-time gated. When enabled, it should only collect aggregate operational data and crash information needed to maintain the app. No user account identity should be attached to analytics.

## Release Signoff

This document should be reviewed alongside the release matrix before any public store submission.
