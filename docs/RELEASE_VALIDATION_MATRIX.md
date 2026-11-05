# Release Validation Matrix

## Purpose

This document defines the operational release gate for public builds of the Sakina App. It complements the repo-level build and test checks and focuses on the evidence expected before store submission or public release.

## Mandatory Preconditions

- Android package identity and signing are finalized for the target app id.
- iOS bundle id, provisioning, and entitlements are verified in the Apple developer environment.
- Release privacy disclosures and permission messaging are consistent with real app behavior.
- Firebase monitoring is explicitly reviewed and consented if enabled.
- Local environment overrides are documented and not accidentally left in production.

## Required Validation Commands

### Code quality and regression checks

```bash
flutter test
flutter analyze
```

### Android release validation

```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols/android \
  --dart-define=APP_ENV=production \
  --dart-define-from-file=.env
```

### iOS release validation

```bash
flutter build ipa --release \
  --obfuscate --split-debug-info=build/symbols/ios \
  --dart-define=APP_ENV=production \
  --dart-define-from-file=.env
```

`--obfuscate` hides Dart symbol names in the shipped binary. Keep the matching
`build/symbols/<platform>` folder for every published build (outside the
repository; `app.*.symbols` is git-ignored): it is the only way to read crash
stack traces, e.g. `flutter symbolize -i <trace> -d build/symbols/android/app.android-arm64.symbols`.
If Crashlytics is enabled, upload the same symbols with
`firebase crashlytics:symbols:upload --app=<app id> build/symbols/<platform>`.
`.env` supplies `YOUTUBE_API_KEY` and is never committed.

> The iOS path requires a valid Apple signing context, provisioning profile, and Xcode environment.

## Release Gate Checklist

### Code

- [ ] All relevant tests pass.
- [ ] Static analysis is clean.
- [ ] Critical notification and startup behavior is covered by regression tests.

### Platform

- [ ] Android package id and signing are configured for production.
- [ ] iOS app id and provisioning are valid for archive submission.
- [ ] Store metadata matches the actual app behavior.

### Privacy and compliance

- [ ] Needed permissions are disclosed and justified.
- [ ] Firebase or analytics behavior is explicitly reviewed for privacy risk.
- [ ] Local-only auth scope is validated and documented.

### Release readiness

- [ ] Final feature checklist matches shipped behavior.
- [ ] Critical user journeys are manually reviewed.
- [ ] Release notes and support links are ready.

## Signoff Recommendation

A build may be treated as release-ready only when all mandatory prerequisites are complete and the validation commands above have been run with successful outcomes in the relevant target environment.
