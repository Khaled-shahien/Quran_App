# Sakina – Notification Implementation Plan (Phase 2)

Builds on `SAKINA_NOTIFICATION_AUDIT.md`. Each phase ends with
`flutter analyze`, `dart format` and the full test run; the status column is
updated as phases finish.

## Hybrid strategy

One shared look for every Sakina notification (brand colour, monochrome bell,
app large icon, Arabic sub text naming the category, expandable text), and a
small set of per-category differences: what the body says, which action
buttons appear, which channel (unchanged) carries it, and where a tap goes.
Android gets the native styles; iOS gets categories, actions, thread ids and
subtitles, and is not forced to look like Android.

## Phase 3 – shared style layer

New `lib/core/services/notification_style.dart`, pure (no plugin calls), so
it is unit-testable:

- `SakinaNotificationKind`: `adhkar`, `quranReading`, `prayer`,
  `prayerSilent`, `prayerReminder`, `dailyVerse`, `general`, `test`.
- `NotificationActions`: stable action ids (`open`, `open_prayer_times`,
  `read_now`) and their localised labels.
- `buildNotificationDetails(kind, {body, summary, when, timeoutAfter})`
  → `NotificationDetails`:
  - channel / importance / priority / sound / category **exactly as today**
    for that kind (no channel changes);
  - `BigTextStyleInformation(body, summaryText: summary)` so long Arabic
    text expands;
  - `color` brand primary, `icon: @drawable/ic_notification`,
    `largeIcon: @drawable/ic_notification_large` (new PNG copy of the
    launcher art, kept by `keep.xml`);
  - `subText` = category label (e.g. "أذكار", "الصلاة", "القرآن الكريم");
  - Android actions (all `showsUserInterface: true`, so no background
    isolate is needed);
  - iOS: `categoryIdentifier`, `threadIdentifier` per category, `subtitle`.
- `notificationCategories()` → `DarwinNotificationCategory` list registered
  in `DarwinInitializationSettings`.
- Grouping: iOS thread ids. On Android no `groupKey` is set: a group needs a
  posted summary notification, and scheduled alarms fire while the app is not
  running to post one; Android 7+ bundles an app's notifications itself.

## Phase 4 – per-category content

| Category | Body | Expanded | Actions | Tap |
| --- | --- | --- | --- | --- |
| A Morning / evening adhkar | existing title and body | BigText, sub text "أذكار" | "ابدأ الأذكار" | `/duas/morning` / `/duas/evening` |
| B Quran reading (Mulk, Baqarah, Khatma) | existing text | BigText, sub text "القرآن الكريم" | "اقرأ الآن" | reader at the surah; Khatma: `/khatma` |
| C Prayer alert | existing body + prayer time line | BigText, `when` = prayer time | "دعاء ما بعد الأذان", "مواقيت الصلاة" | after-adhan / prayer times |
| C Prayer is near | new body "موعد الصلاة {time}" | auto-dismissed at prayer time (`timeoutAfter`) | "مواقيت الصلاة" | prayer times |
| D Daily verse (new, opt-in) | full ayah from `quran_master.json` + "سورة … · آية …" | BigText | "اقرأ في المصحف" | reader opened at that ayah |
| E General / test | unchanged | BigText | — | home |

Daily verse:

- Same verse as the home card that day: the home card's list and day index
  move unchanged to `lib/features/quran/domain/daily_verses.dart`, next to
  their surah/ayah references. The notification shows the **full** ayah read
  from the Quran asset by reference (no typed Quranic text). A test checks
  each home fragment is contained in its referenced ayah.
- Setting: a fifth row in the existing settings "التنبيهات" group (same
  switch + time picker as the others), default **off**, default time 09:00,
  keys `daily_verse_alarm_enabled`, `verse_alarm_hour/minute`.
- Scheduling: one-off notifications for the next 7 days, ids
  `4000 + weekday` (4001–4007, 7 consecutive days never share a slot).
  Rebuilt with the other reminders on launch, settings change, boot and the
  12 h WorkManager task; the settings signature includes the date when the
  verse is on so the window rolls forward.

## Phase 5 – taps and actions

- `NotificationRouter.handleNotification(type, data, actionId)`; actions map
  to their own destinations (`open_prayer_times` → `/prayers`).
- Handler passes `initialAyahNumber` to the reader route for verse taps.
- Duplicate guard: the same notification id + action within 2 s is ignored.
- Running / background: `onDidReceiveNotificationResponse`; terminated:
  launch details; both go through one function. Invalid payloads → home.

## Phase 6 – tests

Style builder per kind (channel ids unchanged, BigText, actions, iOS
category), prayer time line, daily verse selection and asset lookup, id
range, payload round-trip, action routing, duplicate guard, invalid payloads,
settings/WorkManager parity, plus the existing notification suites.

## Phase 7 – documentation

Update this plan's status, the audit's gap table, `SAKINA_UI_UX_DEVELOPMENT_PLAN.md`
and `docs/MANUAL_QA_CHECKLIST_AR.md` (device checks).

## Status

| Phase | Status |
| --- | --- |
| 1 Audit | done |
| 2 Plan | done |
| 3 Style layer | done: `lib/core/services/notification_style.dart` |
| 4 Categories | done |
| 5 Taps / actions | done |
| 6 Tests | done: 743 tests pass, `flutter analyze` clean |
| 7 Docs | done |
| Second pass (R1, R2) | done: 747 tests pass, `flutter analyze` clean |

### Changes from the plan made during implementation

- Android 12+ does not show a big-text summary line. The detail (prayer
  time, verse reference) is shown in the header sub text instead, which the
  device check confirmed; the category label is used when there is no
  detail. iOS shows the same text as the subtitle.
- Prayer reminders: the time passed to the scheduler is when the reminder
  fires, so the prayer time shown is that plus the reminder minutes.
- A "prayer is near" reminder now opens prayer times (payload flag
  `reminder: true`); the prayer alert still opens the dua after the adhan.
- The duplicate-tap guard only applies to responses carrying a notification
  id (every real notification has one).
- The test-screen reschedule button treated unset reminders as on; it now
  treats them as off, like settings and WorkManager (audit G8).

### Device check (emulator-5554, debug x64 build, 16 Nov 2026)

Seen on the device, screenshots in `docs/notification-screenshots/`:

- Morning adhkar and daily verse fired at their set times; Android bundled
  them under one "سكينة" group with the brand-coloured bell.
- Each showed the app large icon, its header line and its button.
- Daily verse expanded to the whole of 2:286 from the asset; "اقرأ في
  المصحف" opened Al-Baqarah on page 49 (the page ending with 286).
- Header after the fix: "سورة البقرة · الآية 286".
- Test prayer alert: prayer channel, header "وقت الأذان 04:33 م", both
  buttons; "مواقيت الصلاة" opened the prayer times screen.
- Scheduling: ids 4001–4007 one per day at the set time; turning the
  reminders off cancelled 1001 and 4001–4007.
- The emulator has no exact-alarm access, so Android allowed a ~2.5 minute
  window (the existing inexact fallback).

Not seen on a device: iOS (no Mac/iPhone here), the "prayer is near"
reminder, Mulk/Baqarah/Khatma reminders (same code path as adhkar with a
different label), and a tap while the app was fully terminated (covered by
the existing launch-routing tests).

## Second pass (16 Nov 2026)

A second request restated the same brief (hybrid design, per-category
looks, actions, deep links, tests). The code from the first pass was
checked against each of its sections; it already meets them, so the
architecture, channels, ids and payloads stay as they are. Two
remaining gaps were found and fixed:

| # | Gap | Fix |
| --- | --- | --- |
| R1 | Khatma reminder text (audit G10): it named today's range only when it was scheduled. A plan with an end date (`byDate`) changes its daily range with the calendar, so after a day without reading the reminder showed an old range. | `KhatmaProvider.refreshReminder()` reschedules the reminder when its text or time differs from what was last scheduled. `AppRoot` calls it after startup and whenever the app comes back to the foreground. Same id (1205), same channel and payload. |
| R2 | The debug test screen used `now % 100000` as an id, which could land on a real reminder id (1001–4007) and replace it. | `NotificationService.debugNotificationId()` keeps test ids in 90000–99999, clear of every managed range. |

Checked and left unchanged on purpose:

- Notification taps arrive through one function for every app state
  (`routeNotificationResponse` for running and background,
  `routeLaunchDetails` for a terminated app), with a 2 s duplicate guard
  and a hold until the splash screen has routed.
- Old or invalid payloads are handled: an unknown type or malformed JSON
  opens home, an invalid surah opens the Quran index, an ayah number that is
  not in the surah opens the surah at its first page, and the after-adhan
  screen only shows the prayer name as a heading, so an unexpected value
  cannot break it. An old prayer alert tapped hours later still opens the
  dua after the adhan, which is not tied to the time.
- Not device-checked in this pass: R1 needs a plan with an end date and a
  day without reading (item added to `docs/MANUAL_QA_CHECKLIST_AR.md`).
- In-app presentation: while the app is open at prayer time, a
  Sakina-styled banner is shown in the app (`AppRoot._onPrayerArrived`).
  This is the place for custom cards. System notifications keep the native
  styles.
- Dark mode: Android and iOS draw the notification surface themselves.
  The accent colour and monochrome small icon read on both light and dark
  surfaces, and there is nothing for the app to switch.

## Known limits (stated up front)

- Images (BigPicture / iOS attachments) are not added: no licensed artwork
  is bundled for it, and a decorative picture would add size without
  meaning. The style layer accepts one later.
- MessagingStyle does not apply: Sakina has no conversations.
- Notification text uses the system font; Uthmani marks render as the
  device font draws them. Owner review on a device is required.
- A "remind me later" action would need a background isolate; left out.
