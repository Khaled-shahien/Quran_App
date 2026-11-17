# Sakina – Notification Audit (Phase 1)

Status: audit of the code on branch `ui-ux-transformation`, before any
notification change. Nothing in this document is a claim that a notification
was seen on a device; device checks are listed separately in the plan.

## 1. Architecture as found

| Layer | File | Role |
| --- | --- | --- |
| Plugin | `flutter_local_notifications ^18.0.1`, `timezone`, `flutter_timezone` | Local notifications only. |
| Push | — | **No FCM / push.** `firebase_messaging` is not a dependency; Firebase is used for Crashlytics only. |
| Service | `lib/core/services/notification_service.dart` (singleton, ~1200 lines) | Init, channels, permissions, exact-alarm mode, every `show` / `zonedSchedule` call, tap routing entry. |
| Channels | `lib/core/services/notification_channels.dart` | Six Android channels (below). Ids must never be renamed without a migration. |
| Facades | `notification_facades.dart`, `alarm_scheduler.dart`, `notification_scheduling_coordinator.dart` | Interfaces the providers and tests use. |
| Settings | `lib/core/providers/settings_provider.dart`, settings screen "التنبيهات" group (`AlarmMenuItem`) | Four daily reminders: switch + time picker each. Default **off**. |
| Background | `workmanager_service.dart`, `alarm_reschedule_task_service.dart`, `ScheduledNotificationBootReceiver` | Re-schedules after boot/update and every 12 h; also replenishes prayer alerts. |
| Prayers | `features/prayers/.../local_prayer_notification_scheduler.dart`, `prayer_replenishment_service.dart`, `prayer_alert_planner.dart`, `prayer_notification_ids.dart` | One-off alerts for a rolling 3-day window, per-prayer mode (sound / notification only / silent) and optional "prayer is near" reminder. |
| Khatma | `features/khatma/data/services/local_khatma_reminder_service.dart` | Daily reading reminder through `scheduleDailyNotification`, payload `khatma`. |
| Routing | `core/navigation/notification_router.dart`, `notification_handler.dart` | Payload type → route; held until splash finishes; opens the target above `/home`. |
| Launch | `NotificationService.deliverLaunchNotification()` from `app_initializer.dart` | Terminated-app taps via `getNotificationAppLaunchDetails`, once per process. |
| Diagnostics | `settings/.../notification_test_screen.dart`, `notification_provider.dart` | Debug tools. |

### Channels

| Id | Name use | Importance | Used by |
| --- | --- | --- | --- |
| `sakina_app_channel` | default | high | `showNotification` |
| `sakina_alarms_channel` | reminders | max | morning / evening adhkar, Mulk, Baqarah, Khatma |
| `prayer_times_default_sound_v2` | prayer (sound) | max | prayer alert, sound / adhan mode |
| `prayer_times_silent_v1` | prayer (no sound) | high | prayer alert, notification-only mode |
| `prayer_reminders_v1` | prayer is near | high | reminder before a prayer |
| `test_channel` | diagnostics | max | test screen, one-time test alerts |

### Notification ids

`1001–1004` adhkar/Mulk/Baqarah · `1205` Khatma · `2001–2075` prayer alerts
(prayer + weekday × 10) · `3001–3075` prayer reminders · `2999` test prayer
alert · test screen uses `now % 100000` (debug only, can collide).

### Payload format

JSON `{"type": "<type>", "data": {...}}`. Types: `morning_adhkar`,
`evening_adhkar`, `mulk_surah`, `baqarah_surah`, `prayer_time`
(`prayerName`, `scheduledAt`), `khatma` (`feature`, `khatmaId`), `general`.
`routeNotificationPayload` accepts empty, malformed and plain-string payloads
(falls back to home), so a bad payload cannot crash the app.

### Routes opened

| Type | Destination |
| --- | --- |
| morning / evening adhkar | `/duas/morning`, `/duas/evening` |
| Mulk / Baqarah | `/quran/surah/67`, `/quran/surah/2` |
| prayer_time | `/after-adhan?prayer=…` (dua after the adhan) |
| khatma | `/khatma` (current wird card) |
| anything else | `/home` |

The handler calls `go('/home')` then `push(target)`, so repeated taps replace
the stack instead of stacking screens.

## 2. What already works well (keep)

- Timezone: device zone via `flutter_timezone`, offset fallback, DST-safe
  `nextDailyOccurrence` (calendar arithmetic, not +24 h). Prayer alerts are
  absolute instants.
- Exact alarms: falls back to inexact when access is denied/revoked instead
  of throwing; permission is asked from an explaining screen.
- Android 13 `POST_NOTIFICATIONS` requested at the point of use; iOS
  permissions requested explicitly (not at init).
- Release safety: `res/raw/keep.xml` keeps `ic_notification` and
  `ic_launcher` from resource shrinking.
- Monochrome small icon `@drawable/ic_notification` (white vector bell).
- Cold-start tap: launch details read once; router holds taps until splash
  has routed, then delivers or drops them.
- Duplicate scheduling avoided: settings signature skip, one-at-a-time alarm
  updates, WorkManager throttle.

## 3. Gaps against the requested design

| # | Area | Finding |
| --- | --- | --- |
| G1 | Style | Every notification is the platform default: one-line body, no `BigTextStyle`, no accent colour, no large icon, no sub text. Long Arabic bodies are cut to one line. |
| G2 | Actions | No action buttons on any notification, Android or iOS. No iOS categories registered. |
| G3 | Prayer content | Prayer alert does not show the prayer **time**; the "prayer is near" reminder has a title and no body. Reminder stays in the tray after the prayer alert arrives. |
| G4 | Daily verse | **No daily-verse notification exists.** The home card "الآيات اليومية" picks one of six verses per day. |
| G5 | Large icon | `@mipmap/ic_launcher` resolves to the adaptive-icon XML on Android 8+, which `BitmapFactory` cannot decode, so it cannot be used as a large icon; a PNG drawable is needed. |
| G6 | Grouping | No `groupKey` / iOS `threadIdentifier`. |
| G7 | Duplicate taps | No guard if the same response is delivered twice in quick succession (e.g. launch details and a resumed callback). |
| G8 | Consistency | `NotificationProvider.rescheduleAllAlarms` (test screen) treats a missing preference as **on**, while settings and WorkManager treat it as **off**. Settings always writes the keys, so this is latent. |
| G9 | Dead strings | `scheduleDailyNotification` replaces adhkar/Mulk/Baqarah titles with `notificationServiceMessage9–16`; `19–26` (which include hand-typed dhikr/hadith text) are passed in but never shown. Not changed here: religious text is not edited without owner review. |
| G10 | Khatma body | The Khatma body (today's range) is fixed when the reminder is scheduled and repeats daily until the plan is next updated. |
| G11 | iOS | No attachments, no categories, no thread ids. Foreground presentation flags are set. |

## 3.1 Resolution (after phases 3–6)

G1–G7 and G11 are addressed. G8 is fixed. G9 is unchanged on purpose:
it involves religious text that needs owner review. G10 was fixed in the
second pass: the Khatma reminder is refreshed on startup and on return to
the app when its range has changed. See
`SAKINA_NOTIFICATION_IMPLEMENTATION_PLAN.md` ("Second pass") for details.

## 4. Constraints carried into the plan

- Do not rename channel ids or change their importance/sound (Android ignores
  changes to an existing channel; a rename orphans user settings).
- Keep notification ids and payload types; new fields are additive.
- Keep every existing setting and its default (all reminders off).
- No new dependencies. No images that need licences. No Quranic text typed by
  hand: verse text must come from `assets/quran_master.json`.
- One entry point: new reminder settings go in the existing settings
  "التنبيهات" group, not a new screen.
