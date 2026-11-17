# Sakina – Notifications & Background Execution Audit

Audit date: 2026-11-17. Findings are defined in [COMPREHENSIVE_AUDIT_REPORT.md](COMPREHENSIVE_AUDIT_REPORT.md) §4.2; tasks in [IMPLEMENTATION_TASKS.md](IMPLEMENTATION_TASKS.md). **No device was used**: everything about real delivery, sound, Doze, OEM behaviour and reboot is unverified here and listed in §9.

## 1. Components

| Layer | File | Role |
|---|---|---|
| Plugin owner | `lib/core/services/notification_service.dart` (1,381 lines, per-isolate singleton) | init, tz, channels, permissions, tap routing, prayer/daily/verse scheduling |
| Channels | `lib/core/services/notification_channels.dart` | 7 fixed channels + 1 per adhan voice (`prayer_adhan_<id>_v1`) |
| Presentation | `lib/core/services/notification_style.dart` | `NotificationDetails`, categories, actions, iOS interruption levels |
| Planning | `lib/features/prayers/domain/services/prayer_alert_planner.dart` | decides alerts/reminders per day |
| IDs | `lib/features/prayers/domain/prayer_notification_ids.dart` | weekday slots |
| Prayer scheduling | `lib/features/prayers/data/services/local_prayer_notification_scheduler.dart` | parses timings, calls service, then `onScheduled` |
| Replenishment | `lib/features/prayers/data/services/prayer_replenishment_service.dart` | recompute N=3 days from saved settings |
| Daily reminders | `SettingsProvider` → `NotificationSchedulingCoordinator` → `AlarmScheduler` → `NotificationService.updateAllAlarms` | |
| Khatma | `KhatmaProvider` (`_khatmaReminderNotificationId = 1205`) | |
| Background | `lib/core/services/workmanager_service.dart` (`callbackDispatcher`) | periodic 12 h, boot one-off, immediate one-off |
| Android native | `BootReceiver.kt`, plugin `ScheduledNotificationBootReceiver` | reboot / package-replaced |
| iOS native | `AppDelegate.swift` (BG periodic 12 h), `Info.plist` | |
| Tap routing | `NotificationRouter` (hold/release), `handleNotificationNavigation` | |

## 2. Notification ID map

| Range | Use |
|---|---|
| 1001–1004 | morning, evening adhkar; Mulk; Baqarah (daily repeating) |
| 1205 | Khatma reminder |
| 2001–2005 | legacy prayer IDs (cancelled on every reschedule) |
| 2011–2075 | prayer alerts: `2001+p + weekday*10` |
| 2999 | test prayer alert |
| 3011–3075 | "prayer is near" reminders (+1000) |
| 4001–4007 | daily verse, one per weekday, 7 days ahead |
| 90000–99999 | debug screen only |

No collisions found. A 3-day window never reuses a weekday slot, so days do not replace each other.

## 3. Channels (Android)

| Channel id | Importance | Sound |
|---|---|---|
| `sakina_app_channel` | high | default |
| `sakina_alarms_channel` | max | default |
| `prayer_times_default_sound_v2` | max | default + vibration |
| `prayer_times_silent_v1` | high | none, vibration |
| `prayer_reminders_v1` | high | default |
| `test_channel` | max | default |
| `sakina_daily_verse_v1` | default | default |
| `prayer_adhan_{ali_mulla,nasser_alqatami,naqshbandi,islam_sobhi}_v1` | max | raw MP3 (2:15–3:25) |

Retired adhan channels are deleted at start-up (`AdhanVoices.retiredChannelIds`). No channel sets `audioAttributesUsage` → notification stream (NOTIF-05).

## 4. Lifecycle

```
App start ─► AppInitializer
   ├─ NotificationService.initialize()      tz db, tz.local (once), plugin init, channels
   ├─ deliverLaunchNotification()          route tap that launched a terminated app
   └─ WorkManager.initialize()             + periodic(12h, initialDelay 10m, policy update)
                                           + one-off "boot" (20 s, replace)
AppRoot ─► NotificationRouter.hold(); splash ─► release(dropPending: !onboarded)
PrayerTimesProvider.fetch ─► schedulePrayerNotifications(today)
        └─► onScheduled ─► WorkManager one-off "manual" (3 s, bypasses throttle)
                               └─► background isolate: updateAllAlarms + replenish(3 days)
Settings toggle ─► foreground updateAllAlarms  AND  requestReschedule (background)   ◄─ NOTIF-01
Reboot / update ─► BootReceiver.kt (15 s) + plugin boot receiver ─► background replenish
Every 12 h     ─► periodic task ─► background replenish (throttled 45 s)
Tap            ─► onDidReceiveNotificationResponse / launch details
                   ─► routeNotificationResponse (2 s dedupe) ─► NotificationRouter ─► go('/home') + push(target)
```

### Prayer alert path
1. `PrayerTimesProvider` computes today's times offline.
2. `LocalPrayerNotificationScheduler.buildPrayerSchedule` converts "HH:mm" to instants in the prayer location's zone (`prayerInstant`).
3. `NotificationService.scheduleAllPrayersForDate` cancels the day's legacy + slot IDs, then `planPrayerAlerts` decides per prayer: silent → none; otherwise an alert at the prayer time (if in the future) and an optional reminder `reminderMinutes` earlier.
4. `schedulePrayerNotification` skips anything ≤5 s ahead, builds content, picks `exactAllowWhileIdle` or `inexactAllowWhileIdle`, and calls `zonedSchedule`; on `invalid_sound` it retries with the default sound.
5. The OS delivers; Android plays the channel sound (adhan MP3) on the notification stream.

### Duplicate prevention
- Stable IDs per prayer × weekday; reschedule replaces.
- `_lastAppliedAlarmStateSignature` skips identical daily-reminder updates (per isolate only).
- `_alarmUpdates` future chain serialises updates (per isolate only).
- WorkManager unique names + 45 s throttle (bypassed for `manual_settings_update`).
- **Gap**: nothing coordinates the UI and background isolates (NOTIF-01).

### Failure recovery
- Missing adhan sound → default sound (logged).
- Exact alarm unavailable → inexact (NOTIF-06).
- Background task failure returns `false` → WorkManager retries with exponential backoff (10 min periodic / 5 min boot).
- Replenishment aborts if settings changed mid-run (`prayer_replenishment_service.dart:83-95`).
- Failures are only `developer.log`-ged → invisible in release (OBS-01).

## 5. Permissions

| Permission | Requested | Denied behaviour |
|---|---|---|
| `POST_NOTIFICATIONS` (13+), iOS alert/sound/badge | From an explanatory dialog after onboarding, not at launch | Scheduling still runs; nothing shows. Re-request from settings. |
| `SCHEDULE_EXACT_ALARM` | From adhan settings (`requestExact`) | Inexact delivery |
| `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `VIBRATE` | install-time | — |
| Battery optimisation | Guidance text in `adhan_preferences.dart` (no direct request) | OEM may kill background work |

## 6. Timezone, DST, clock changes

- DST: daily occurrences use calendar arithmetic (`nextDailyOccurrence`), prayer instants are absolute → correct across DST.
- Zone change / manual clock change: not handled (NOTIF-02).
- Bundled tz database age: PRAY-02.

## 7. Adhan audio

- Four owner-supplied MP3s, unchanged, 13 MB total, rights **pending** (REL-02).
- Android: sound = channel sound; volume = notification volume; silent/DND mute it; dismissing the notification stops it.
- iOS: notification sounds >30 s fall back to the default sound; voice selection hidden; no full adhan (NOTIF-03).
- Preview: just_audio from the raw resource; pauses recitation. Recitation is also paused if the app is open at prayer time (`app_root.dart:117-134`).
- **Not guaranteed by the OS**: full-length playback (OEM may truncate), playback in Doze if delivered late, playback in silent/DND.

## 8. Android vs iOS

| Aspect | Android | iOS |
|---|---|---|
| Scheduling | AlarmManager via plugin, exact if permitted | `UNCalendarNotificationTrigger`, max 64 pending |
| After reboot | plugin + `BootReceiver` re-register | system keeps pending requests |
| Replenishment | WorkManager periodic 12 h (reasonably reliable, OEM-dependent) | BGAppRefresh, opportunistic; one-off tasks not permitted (NOTIF-04) |
| Adhan audio | full MP3 as channel sound | default sound only |
| Pending budget used | ≈ 30 prayer + 4 daily + 7 verse + 1 khatma = 42 | same, under 64 |

## 9. Required tests

Automated (see [TESTING_AND_QUALITY_REPORT.md](TESTING_AND_QUALITY_REPORT.md)):
1. `callbackDispatcher` / `_handleRescheduleAlarms` with fakes: throttle, manual bypass, failure returns false, settings change abort (P6-01).
2. Foreground schedule does not enqueue a redundant background run after P0-05 (P6-04).
3. Display-name change does not drop a prayer (after P1-03).
4. Timezone-change detection on resume (P1-05).
5. iOS schedule budget ≤ 64 (P2-01).

Device (manual, release build):
1. Each prayer mode on Android 10, 12, 13, 14, 15/16 (Pixel, Samsung, Xiaomi): delivery time, sound, vibration.
2. Adhan in normal / vibrate / silent / DND.
3. Reboot with app never reopened → alerts on following 3 days.
4. Exact-alarm permission revoked → delay measured.
5. Timezone change and manual time change.
6. Rapid settings toggles then reboot → `adb shell dumpsys alarm | grep io.github.khaledshahien.sakina` shows the expected set (NOTIF-01).
7. Tap from foreground / background / terminated → correct screen and back stack.
8. iOS: alerts without opening the app for 4+ days (NOTIF-03).
