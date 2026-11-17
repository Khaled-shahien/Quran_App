# Sakina – External Blockers

Everything below needs information, access, credentials or decisions that are not in the repository. No value here is invented; where the repository holds a candidate value it is quoted as found. Tasks: [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md).

| ID | What is missing | Why it is needed | Depends on it | Provided by | Blocks |
|---|---|---|---|---|---|
| B-01 | Final Android application ID decision. Current `applicationId` is `io.github.khaledshahien.sakina` (commit `4bc16bc`); Kotlin namespace `app.sakina.quran`; `verify_release.py` reports it "differs from approved identity" because `RELEASE_ANDROID_ID` is unset | Store identity is permanent after the first Play upload | P0-03, P5-01, P5-05, P7-03 | App owner | Production release |
| B-02 | Final iOS bundle ID (currently `app.sakina.quran`), Apple Developer account, team ID, certificates, provisioning profiles | Signing, TestFlight, App Store | P0-03, P7-01, P5-03 | App owner / Apple Developer Program | iOS testing and release |
| B-03 | Physical test devices (Android: Pixel, Samsung, Xiaomi, low-end; iOS: small and recent iPhone, iPad) and a macOS machine with Xcode | Notification delivery, adhan audio, reboot, Doze, OEM kill, screen readers, iOS build | P2-01, P3-01, P5-02, P6-06, P7-01 | Owner / QA | Release verification |
| B-04 | Approved Firebase project and app registrations matching B-01/B-02; `GoogleService-Info.plist` for iOS; decision whether crash reporting ships at all | `firebase_options.dart` and `google-services.json` currently include non-final clients; iOS plist absent | P0-03, P5-05, P5-09 | Owner (Firebase console access) | Release with monitoring |
| B-05 | Content-owner review of the 6 (later 8) religious collections: source, edition, licence, reviewer, approval date, evidence URL; comparison of the Quran text with the stated Tanzil edition / a printed mushaf | Religious accuracy; Tanzil licence attribution | P0-01, P2-05 | Owner and a qualified reviewer | Production release |
| B-06 | Redistribution permission for the four adhan recordings (rights holder, written permission, date) or replacement recordings with a known licence | Copyright | P0-02, P2-03, P4-02 | Owner | Production release |
| B-07 | Google Cloud access for the YouTube Data API key (restrictions, quota); release signing SHA-1 for the Android restriction | Prevent key abuse | P5-01, P5-04 (rotation if needed) | Owner | Videos feature in production |
| B-08 | Android release keystore custody: `android/key.properties` exists locally and is git-ignored; CI uses a throwaway key. Play App Signing enrolment and upload-key backup must be confirmed | Updates must be signed with the same upload key | P7-01 (analogous for iOS), P7-03, P7-05 | Owner | Production release |
| B-09 | Product decision: should the adhan sound like an alarm (plays in silent mode, alarm volume) or like a notification (respects silent/DND)? | Channel audio attributes are immutable; decide once | P2-03 | Owner | Development of P2-03 |
| B-10 | Scholarly/product decision on default calculation method per region, which additional methods to offer, Umm al-Qura Ramadan Isha convention, Hijri offset default | Religious correctness of prayer times | P2-04 | Owner with a qualified reviewer | Development of P2-04 |
| B-11 | Published privacy-policy URL (draft at `site/privacy.html`, workflow `pages.yml`) and confirmation that its content matches the final build (e.g. after P5-02) | Required by both stores | P7-03 | Owner | Store submission |
| B-12 | Support contact and store listing: final text (`docs/STORE_LISTING_AR.md`), screenshots per required size (some exist in `store/`), feature graphic, content rating questionnaire, Data safety / App Privacy answers | Store submission | P7-03 | Owner | Store submission |
| B-13 | Play Console declarations: foreground service (media playback) with demo video; exact-alarm use if requested | Policy compliance | P7-03 | Owner | Play submission |
| B-14 | GitHub repository variables `RELEASE_ANDROID_ID`, `RELEASE_IOS_ID`, `RELEASE_FIREBASE_PROJECT` and an emulator-capable CI budget | Release-readiness workflow, integration tests in CI | P0-03, P6-02 | Repository admin | CI gates |
| B-15 | Licence choice for the source code (README: "No license file is currently included") | Clarity for contributors; not a store requirement | P7-04 | Owner | Nothing technical |

## Blocking classification

- **Blocks development**: B-09 (P2-03), B-10 (P2-04).
- **Blocks testing**: B-03, B-14 (CI integration tests), B-02 (iOS).
- **Blocks production release**: B-01, B-02 (iOS), B-04 (if monitoring ships), B-05, B-06, B-07 (if videos ship), B-08, B-11, B-12, B-13.
