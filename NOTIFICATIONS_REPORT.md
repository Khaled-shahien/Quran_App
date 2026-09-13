# Firebase & Notifications Setup Report

Generated: 2026-07-06 13:32:40 +03:00

---

## 1. Firebase Connection Status

| Check | Result |
|-------|--------|
| google-services.json exists | PASS - `android/app/google-services.json` exists |
| Package name matches | PASS - both use `com.example.quran_app` |
| Firebase project ID | `quran-app-10d05` |
| google-services plugin in Gradle | PASS - declared in `android/settings.gradle.kts` and conditionally applied in `android/app/build.gradle.kts` |
| minSdk is at least 21 | PASS - `minSdk = maxOf(21, flutter.minSdkVersion)` |
| firebase_core in pubspec | PASS - `firebase_core: ^3.15.2` |
| firebase_messaging in pubspec | PASS - `firebase_messaging: ^15.1.4` |
| Firebase initialized before app startup work | PASS - handled by `AppInitializer.initialize()` |
| Background FCM handler registered | PASS - `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` |

Notes:
- This Android project uses Kotlin Gradle DSL (`*.gradle.kts`), not Groovy `build.gradle`.
- `android/app/build.gradle.kts` already applies `com.google.gms.google-services` only when `google-services.json` exists, which avoids breaking builds if the Firebase file is temporarily removed.

---

## 2. FCM Push Notifications Status

| Check | Result |
|-------|--------|
| FCM service exists | PASS - existing `FirebaseMessagingService` is used instead of adding a duplicate `FCMService` |
| Background handler registered | PASS |
| Foreground handler registered | PASS |
| Foreground FCM shows local notification | PASS - foreground messages call `NotificationService.showNotification()` |
| Notification tap handling | PASS - routes through `NotificationRouter` |
| POST_NOTIFICATIONS permission added | PASS |
| FCM token | Not retrieved during static audit/build; requires running on a device |

Changes made:
- Added `FirebaseMessagingService.instance` for singleton access.
- Changed FCM fallback notification titles from English to Arabic: `إشعار جديد`.
- Kept the Firebase Messaging Android service out of `AndroidManifest.xml` because the FlutterFire `firebase_messaging` plugin contributes the required service through manifest merging.

---

## 3. Local Notifications and Prayer Times Status

| Check | Result |
|-------|--------|
| flutter_local_notifications added | PASS - `^18.0.1` |
| timezone package added | PASS - `^0.9.4` |
| flutter_timezone package added | PASS - `^4.1.1` |
| Local notification service exists | PASS - existing `NotificationService` extended |
| Prayer notification channel created | PASS - `prayer_times_channel` |
| Prayer scheduling methods added | PASS |
| Adhan sound file exists | FAIL - `adhan.mp3` is still missing |
| `res/raw` folder exists | PASS - `android/app/src/main/res/raw/` was created locally |
| SCHEDULE_EXACT_ALARM permission added | PASS |
| USE_EXACT_ALARM permission added | PASS |
| RECEIVE_BOOT_COMPLETED permission added | PASS |
| VIBRATE permission added | PASS |
| Connected to Prayer Times feature | PASS - both prayer providers now schedule after successful loads |

Changes made:
- Added prayer-time exact scheduling to `NotificationService`.
- Added `schedulePrayerNotification`, `scheduleAllPrayersToday`, and `cancelAllPrayerNotifications`.
- Added Arabic prayer notification title/body text.
- Added a prayer notification scheduler abstraction and local implementation.
- Connected the scheduler to both `PrayerTimesProvider` and `PrayerTimesPerformanceProvider`.
- Added the user preference key `prayer_notifications_enabled`; default is enabled, and `false` cancels prayer notifications.

---

## 4. Files Created / Modified

Created:
- `NOTIFICATIONS_REPORT.md`
- `lib/features/prayers/domain/services/prayer_notification_scheduler.dart`
- `lib/features/prayers/data/services/local_prayer_notification_scheduler.dart`
- `test/features/prayers/data/services/local_prayer_notification_scheduler_test.dart`
- `android/app/src/main/res/raw/` local directory

Modified:
- `android/app/build.gradle.kts`
- `lib/core/app/app_root.dart`
- `lib/core/di/service_locator.dart`
- `lib/core/services/firebase_messaging_service.dart`
- `lib/core/services/notification_service.dart`
- `lib/features/prayers/presentation/providers/prayer_times_provider.dart`
- `lib/features/prayers/presentation/providers/prayer_times_performance_provider.dart`

Audited, no changes needed:
- `android/settings.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`
- `lib/main.dart`
- `lib/core/initialization/app_initializer.dart`
- `android/app/google-services.json`

---

## 5. Actions Required from Developer

1. Add an adhan MP3 file at:
   `android/app/src/main/res/raw/adhan.mp3`
2. Run the app on a real Android device, allow notifications, and verify that an FCM token is produced at runtime.
3. Send an FCM test message from Firebase Console to that runtime token.
4. Before production release, consider replacing the sample package name `com.example.quran_app` with the final app ID and re-download `google-services.json` for that package if changed.

---

## 6. How to Test

### Test FCM Push Notification

1. Run the app on a real Android device.
2. Open the notification test/debug screen or watch debug logs for the FCM token.
3. In Firebase Console, go to Engage > Messaging.
4. Send a test message to the device token.
5. Expected: the device receives the notification; if the app is foregrounded, the app shows a local notification.

### Test Prayer Time Notification

1. Add `android/app/src/main/res/raw/adhan.mp3`.
2. Run the app on Android and allow notification permission.
3. Open the prayer times screen or home prayer widget so prayer times load.
4. Confirm pending notifications from the notification test screen.
5. For quick testing, temporarily use a prayer time a few minutes in the future.
6. Expected: a prayer notification appears with the prayer channel and adhan sound.

---

## 7. Verification Output

### flutter pub get

```text
Got dependencies!
60 packages have newer versions incompatible with dependency constraints.
```

### flutter analyze

```text
Analyzing quran_app...
No issues found! (ran in 14.2s)
```

### focused tests

```text
flutter test test/features/prayers/data/services/local_prayer_notification_scheduler_test.dart test/features/prayers/presentation/providers/prayer_times_provider_test.dart
00:00 +5: All tests passed!
```

### flutter build apk --debug

```text
Running Gradle task 'assembleDebug'...                             82.5s
Built build\app\outputs\flutter-apk\app-debug.apk
```

---

## 8. Issues Found & Fixed

1. Prayer times were loaded but not connected to prayer notification scheduling.
   Fix: added an injectable prayer notification scheduler and wired both prayer providers to it.
2. Local notification service had general alarm support but no dedicated prayer channel or prayer notification IDs.
   Fix: added the `prayer_times_channel`, stable prayer notification IDs, and exact one-time prayer scheduling.
3. FCM foreground/background fallback notification titles were English.
   Fix: changed fallback title to Arabic.
4. Android minSdk was delegated entirely to Flutter defaults.
   Fix: made API 21 minimum explicit with `maxOf(21, flutter.minSdkVersion)`.
5. `android/app/src/main/res/raw/` was missing.
   Fix: created the directory and documented the required `adhan.mp3`.

---

## 9. Remaining Issues Not Fixed

1. `adhan.mp3` is missing.
   Developer action: place the MP3 at `android/app/src/main/res/raw/adhan.mp3`.
2. FCM delivery and token retrieval were not runtime-tested on a physical device.
   Developer action: run the app on Android and send a Firebase Console test message.
3. Prayer notifications are scheduled after prayer times load in the app. If the device reboots before the app loads prayer times again, the existing boot recovery covers the app's saved reminder alarms but does not yet rebuild prayer-time notifications from persisted prayer data.
   Developer action: decide whether boot-time prayer notification recovery is required for this release.
