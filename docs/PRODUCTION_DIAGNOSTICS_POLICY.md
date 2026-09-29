# Production Diagnostics Policy

## Objective

The app uses optional monitoring tools to improve stability and diagnose production issues without defaulting to a remote-identity model.

## Current Policy

- Firebase is optional and guarded by build-time configuration.
- Monitoring is not a required dependency for basic app function.
- No user account identity is required for crash or analytics events.
- Only operational and diagnostic signals should be collected.

## Requirements

- Event payloads must not include raw personal data.
- Analytics configuration must remain reviewable before a production build.
- Crash reporting should be used for app health, not for user surveillance.
- Disable monitoring for local, debug, and staging unless explicitly required.

## Signoff

The monitoring configuration should be reviewed before release alongside the release validation matrix and the app scope policy.
