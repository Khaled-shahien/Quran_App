# Sakina – Adhan Audio Library

The adhan recordings bundled with Sakina, where they came from, and how they
are played. Code: `lib/features/prayers/domain/adhan_voices.dart`.
Files: `android/app/src/main/res/raw/adhan_*.mp3`.

## Recordings

All four recordings were supplied directly by the app owner as MP3 files
(folder "اصوات الاذان", 17 Nov 2026). They are bundled **unchanged**: each
bundled file is a byte-identical copy of the supplied file (SHA-256 below).
Every recording is offered for all five prayers (Fajr, Dhuhr, Asr, Maghrib,
Isha); each prayer keeps its own choice.

| Id | Display name | Original filename | Bundled file | Duration | Size | Audio |
|---|---|---|---|---|---|---|
| `ali_mulla` | علي أحمد ملا | `الاذان بصوت ( علي احمد ملا ) .mp3` | `adhan_ali_mulla.mp3` | 3:25 | 4,348,364 B | MP3, 44.1 kHz stereo, ~170 kbit/s |
| `nasser_alqatami` | ناصر القطامي | `الاذان بصوت ( ناصر القطامى ) .mp3` | `adhan_nasser_alqatami.mp3` | 2:15 | 2,898,360 B | MP3, 44.1 kHz stereo, ~171 kbit/s |
| `naqshbandi` | النقشبندي | `الاذان بصوت ( النقشبندي ) .mp3` | `adhan_naqshbandi.mp3` | 2:43 | 2,779,557 B | MP3, 44.1 kHz stereo, 128 kbit/s (embedded cover image) |
| `islam_sobhi` | إسلام صبحي | `الاذان بصوت ( اسلام صبحي ) .mp3` | `adhan_islam_sobhi.mp3` | 2:52 | 3,302,243 B | MP3, 44.1 kHz stereo, ~154 kbit/s |

Category: adhan (all prayers). Display names come from the muezzin named
in each original filename; nothing else about the recordings (origin,
mosque, date) is stated, because it is not known.

SHA-256 of the bundled files:

```
4f345f5522d75bc53f7ad0d156f531419b9f33147c395eec3c492ce06887277d  adhan_ali_mulla.mp3
13338329635a8d2dd64e807c584b56f9b5c43d59ff77d4b750e8efe7097f82b3  adhan_nasser_alqatami.mp3
9e29d88b8790020b837feac2754e5eb66132cd3c97da36611b6c22a845d15af1  adhan_naqshbandi.mp3
8c5a949b48c709a93147b6f4610069e4eab6fe708e605ee6b5f3bca717a6403e  adhan_islam_sobhi.mp3
```

### Checks done on the supplied files

- All four decode fully with ffmpeg without errors; durations, sizes and
  bitrates above come from ffprobe.
- No file was corrupted, duplicated (four distinct hashes) or unsupported.
- No conversion was needed: Android plays MP3 from `res/raw` both as a
  notification channel sound and through just_audio for the preview. The
  audio was not trimmed, normalised, re-encoded or otherwise changed.

### Source and licence status

- **Source:** user-provided (the app owner).
- **Licence / redistribution rights:** **pending verification.** No licence
  is claimed for these files, and supplying a file does not by itself grant
  the right to redistribute it in a published app. Before a public or
  commercial release, the owner should obtain and record permission from the
  rights holder of each recording (the muezzin, the broadcaster or the
  publisher of the recording, as applicable) and add it here.
- The app's licences page no longer lists adhan recordings, since no
  attribution terms are known.

### Removed recordings

The five recordings bundled before (`adhan_asim_javed.ogg`,
`adhan_moazzam_mirza.ogg`, `adhan_shalqar.ogg`, `adhan_nigeria.ogg`,
`adhan_fajr_gocek.ogg`) were removed at the owner's request, with their
catalog entries, names and licence-page entries.

## How the adhan plays

### Android

- Each recording has its own notification channel
  (`prayer_adhan_<id>_v1`) whose sound is the raw resource. Android fixes a
  channel's sound when it is created, so choosing another recording moves
  the prayer to that recording's channel instead of editing a channel. The
  other prayer channels are unchanged.
- The channels of the five removed recordings
  (`AdhanVoices.retiredChannelIds`) are deleted at start-up, so the
  system settings do not list channels whose sound is gone. A saved choice
  of a removed recording falls back to the first recording
  (`ali_mulla`); the prayer's alert mode is kept.
- Choosing a recording saves it for that prayer (`adhan_voice_<prayer>`
  in shared preferences) and reschedules the prayer alerts, so the next
  alert uses the new channel.
- The prayer alert is scheduled with `zonedSchedule` as before (exact alarm
  when allowed); the system plays the recording when the notification
  appears, also when the app is closed and after a reboot (the existing
  boot rescheduling recreates the alerts).
- The sound follows the notification volume and Do Not Disturb, like other
  notification sounds. Swiping the notification away or tapping it stops
  the adhan (Android stops a notification's sound when it is removed).
- `keep.xml` keeps `@raw/adhan_*` from release resource shrinking. If a
  recording is still missing, Android rejects the schedule with
  `invalid_sound`; the app then schedules the same alert with the normal
  alert sound and logs why, so the prayer alert is never lost.
- Preview in settings ("استمع") plays the same raw resource through
  just_audio (`android.resource:///raw/<name>`), and pauses recitation first.

### iOS

iOS plays a notification sound only if it is at most 30 seconds long;
longer files are replaced by the default sound. These recordings are 2–3.5
minutes, so on iOS the adhan option uses the alert sound and the settings
screen says so ("الأذان الكامل غير متاح في إشعارات هذا الجهاز…"); the voice
row is not shown. Full playback on iOS would need the app to play the adhan
itself (app in foreground, or a background audio session), which is not
built.

## Adding or replacing a recording

Put the file in `res/raw` as `adhan_<id>.mp3`, add an `AdhanVoice` entry
(with its original filename, duration and size), a name in `app_ar.arb`
and `adhan_voice_labels.dart`, and a row here. Replacing the audio of an
existing id needs a new channel version (`_v2`), because Android keeps the
old sound on the old channel. The tests check the file, size, channel,
keep rule and this document.

## Checks

- Tests: `test/features/prayers/adhan_voices_test.dart` (each file exists,
  is MP3 and matches the catalog size; no stray files; removed recordings
  gone and their channels retired; keep rule; this document lists each
  file; every recording selectable for every prayer; per-prayer choice and
  fallback; channel and sound per recording; iOS behaviour; settings UI,
  preview and preview failure) and
  `test/features/prayers/domain/prayer_alert_planner_test.dart`.
- Device: see `docs/MANUAL_QA_CHECKLIST_AR.md` §2. **Owner review before
  release:** listen to each recording in full in Settings → prayer alerts →
  "استمع".
