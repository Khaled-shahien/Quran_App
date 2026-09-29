# Device QA and operations

Record build SHA, version, OS, model, locale, timezone, permission state, expected
result, actual result and evidence file for each run. An empty result is pending,
not a pass. Emulators do not establish physical sensor or OEM battery behavior.

## Required release matrix

| Device | Primary checks | Result |
|---|---|---|
| Small Android phone (320–360 dp) | Large text, RTL, reading controls, navigation | Pending physical device |
| Mid-range Samsung | All four reminders, five prayers, reboot, exact alarms | Pending |
| Xiaomi or other restricted-background OEM | Battery restrictions, reboot, delayed delivery | Pending |
| Android tablet | Settings, reader, dialogs, landscape | Pending |
| iPhone, if included in launch | Permissions, notification taps, VoiceOver, signed install | Pending launch decision |

## Notification cases

Set each reminder a few minutes ahead; observe foreground, background and terminated
delivery. Tap each notification and verify the exact destination. Repeat with
permission denied, exact-alarm access disabled, battery saver, reboot and upgrade.
For prayer times compare the explicitly selected city's method and timezone with
the provider response, including travel, DST and midnight rollover. Check the
following day without opening the app. The background worker now queues today
and the next two calendar days from saved coordinates and the selected method,
using the API timezone. Periodic execution remains OS-controlled: test delayed
jobs, offline gaps longer than the queued window, and location/setting changes
while a job runs. Physical delivery and iOS background execution remain unverified.

## Performance and accessibility

Run a profile build on the mid-range physical phone. Save startup timeline, frame
timings during reader swipes, peak memory and a long-reading-session trace. Confirm
the blueprint's cold-start target on hardware; a two-second splash is not a
measurement of total startup. Walk through primary flows using TalkBack, large
text, reduced motion, RTL and both themes. Compare approved screenshots per screen.

## Monitoring activation

1. Supply approved native Firebase configuration and regenerate Dart options with
   `flutterfire configure`; verify package/project identities.
2. Build with `--dart-define=ENABLE_FIREBASE_MONITORING=true` only for the approved
   Firebase project. Native collection defaults and the user toggle remain off.
3. Opt in using Settings on a test device. Verify `app_open` after relaunch and
   `settings_open`, then force a controlled test crash in a QA-only build.
4. Confirm the report in Crashlytics with the correct build and readable symbols.
   Opt out and verify no subsequent app events are sent.
5. Configure crash/ANR alerts and name a release owner. Check daily during the
   first week, then weekly; review user reports without collecting sacred-text
   queries, reading history or exact locations.

Implementation follows the [Flutter Crashlytics setup](https://firebase.google.com/docs/crashlytics/flutter/get-started)
and [opt-in collection guidance](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports).

## Release and recovery

Run formatting, analyzer, full unit/widget suite, integration flows, content
integrity verification, native identity gate, signed build and signed install.
Archive the AAB/APK, symbols, SHA, approvals and device evidence together. Start
with internal testing, then an owner-approved staged rollout. Pause the rollout
if crashes, notification errors or content issues exceed approved thresholds.
Prepare a corrective build with a higher version code; the first release has no
previous published artifact to restore. No store submission is performed by the
local test workflow.
