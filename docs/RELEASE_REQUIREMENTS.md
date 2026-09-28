# Release requirements

Android release builds no longer fall back to debug signing. Create ignored `android/key.properties` with `storeFile` (absolute or relative to android), `storePassword`, `keyAlias`, and `keyPassword`. Keep the keystore and passwords outside version control and in protected CI secrets. Build/install verification of a signed artifact is still required.

The existing sample Android identifier and inconsistent Firebase/iOS identities have deliberately not been replaced with invented production values. Before release the owner must supply:

1. Approved Android application ID and iOS bundle ID (and migration plan if already published).
2. Matching Firebase project and genuine per-platform configuration, including iOS GoogleService-Info.plist. Regenerate Firebase options for the approved platform matrix.
3. Android signing keystore and iOS signing/provisioning via the secret store.
4. Backend token registration/update/delete endpoint contract and privacy/retention policy, if backend push targeting is required.
5. Approved prayer method/madhab/high-latitude policy and content/source approvals.

Set repository variables `RELEASE_ANDROID_ID`, `RELEASE_IOS_ID`, and `RELEASE_FIREBASE_PROJECT` to the approved matrix. Run `python scripts/verify_release.py`; the tag/manual `release-readiness.yml` workflow runs the same native identity gate. This does not replace signed artifact inspection or Firebase Dart-options verification.

Required device evidence: notification permission denial/recovery, exact alarm eligibility, foreground/background/terminated tap, reboot and package update, travel/timezone/DST/date rollover, offline first launch, location denied/permanently denied, large text and TalkBack/VoiceOver, Qibla on physical sensors, startup/frame/memory traces and signed install/upgrade.

The added Android plugin receivers restore already persisted notifications. They do not calculate future days when the app remains closed. Automatic multi-day prayer replenishment still needs implementation and device verification. No production-readiness claim follows from unit/widget tests.
