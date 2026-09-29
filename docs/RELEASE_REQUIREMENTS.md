# Release requirements

Android release builds no longer fall back to debug signing. Create ignored `android/key.properties` with `storeFile` (absolute or relative to android), `storePassword`, `keyAlias`, and `keyPassword`. Keep the keystore and passwords outside version control and in protected CI secrets. Build/install verification of a signed artifact is still required.

The existing sample Android identifier and inconsistent Firebase/iOS identities have deliberately not been replaced with invented production values. Before release the owner must supply:

1. Approved Android application ID and iOS bundle ID (and migration plan if already published).
2. Matching Firebase project and genuine per-platform configuration, including iOS GoogleService-Info.plist. Regenerate Firebase options for the approved platform matrix.
3. Android signing keystore and iOS signing/provisioning via the secret store.
4. Public privacy URL and support contact, plus approved third-party data retention disclosures. Production uses local reminders; the FCM dependency, handlers and token controls have been removed. A backend token registration/update/delete contract is required only if remote push is added later.
5. Approved prayer method/madhab/high-latitude policy and content/source approvals.

Set repository variables `RELEASE_ANDROID_ID`, `RELEASE_IOS_ID`, and `RELEASE_FIREBASE_PROJECT` to the approved matrix. Run `python scripts/verify_release.py`; the tag/manual `release-readiness.yml` workflow runs the same native identity gate. This does not replace signed artifact inspection or Firebase Dart-options verification.

The release workflow also requires `python scripts/verify_content.py --require-approved`. Pending content provenance intentionally blocks that gate. Monitoring is integrated but disabled unless built with `--dart-define=ENABLE_FIREBASE_MONITORING=true`; even then it requires user opt-in. Verify real Firebase events/crashes and opt-out on the approved project before enabling it in a public build. iOS additionally needs its native Crashlytics upload setup and macOS build verification.

Store copy and screenshot requirements are drafted in `STORE_LISTING_AR.md`. Device evidence and rollout monitoring instructions are in `DEVICE_QA_AND_OPERATIONS.md`. Current verification uses Flutter 3.48.0-0.5.pre (beta); select and verify the production SDK before publishing.

Required device evidence: notification permission denial/recovery, exact alarm eligibility, foreground/background/terminated tap, reboot and package update, travel/timezone/DST/date rollover, offline first launch, location denied/permanently denied, large text and TalkBack/VoiceOver, Qibla on physical sensors, startup/frame/memory traces and signed install/upgrade.

The Android plugin receivers restore already persisted notifications. The background worker now fetches and queues today plus two future calendar days using saved location/method settings and API timezone; failed work remains retryable. WorkManager timing, closed-app delivery, offline exhaustion of the window and iOS background execution still require physical verification. No production-readiness claim follows from unit/widget tests.

Run `python -m unittest discover -s scripts/tests -v` to verify gate behavior
against isolated synthetic fixtures. Both CI workflows run these tests. The
content gate requires exactly the four tracked collections, unique paths and
matching hashes; its approval mode additionally checks owner metadata. The native
identity gate rejects missing/mismatched identities and debug signing references.
These static gates do not certify a signed binary, Dart Firebase options or the
authenticity of an approval record; those checks still require release evidence.
