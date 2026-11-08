# Runtime dependencies and licences

Versions are the resolved ones in `pubspec.lock`; licence types were read from
each package's own LICENSE file. Dev-only packages (tests, code generation,
lints) are not shipped and are not listed.

| Package | Version | Licence | Used for |
|---|---|---|---|
| adhan_dart | 2.0.1 | MIT | On-device prayer time calculation |
| audio_service | 0.18.19 | MIT | Background recitation and lock-screen controls |
| audio_session | 0.2.4 | MIT | Audio focus (pausing for calls, adhan) |
| just_audio | 0.10.6 | Apache-2.0 | Recitation playback |
| cupertino_icons | 1.0.9 | MIT | iOS icons |
| firebase_core | 3.15.2 | BSD-3-Clause | Firebase setup (monitoring, opt-in) |
| firebase_crashlytics | 4.3.10 | BSD-3-Clause | Opt-in crash reports |
| flutter_local_notifications | 18.0.1 | BSD-3-Clause | Prayer alerts and reminders |
| flutter_timezone | 4.1.1 | Apache-2.0 | Device timezone |
| timezone | 0.9.4 | BSD-2-Clause | Timezone database for scheduling |
| geolocator | 14.0.2 | MIT | Optional location for prayer times and qibla |
| get_it | 7.7.0 | MIT | Service locator |
| go_router | 17.5.0 | BSD-3-Clause | Navigation |
| hijri | 3.0.1 | BSD-2-Clause | Hijri calendar |
| http | 1.6.0 | BSD-3-Clause | Network requests |
| intl | 0.20.3 | BSD-3-Clause | Localisation and formatting |
| json_annotation | 4.12.0 | BSD-3-Clause | JSON models |
| path_provider | 2.1.6 | BSD-3-Clause | Recitation download folder |
| provider | 6.1.5+1 | MIT | State management |
| shared_preferences | 2.5.5 | BSD-3-Clause | Settings and progress |
| url_launcher | 6.3.2 | BSD-3-Clause | External links (with confirmation) |
| workmanager | 0.9.3 | MIT | Re-scheduling alerts in the background |

All are permissive licences. Apache-2.0 and BSD/MIT packages require keeping
their notices; Flutter's built-in licence page (`showLicensePage`, reachable from
About) lists them automatically.

## Bundled assets and content

Fonts, city data and their licences: see `THIRD_PARTY_ASSETS.md`. Religious
content sources and their review status: see `PRIVACY_AND_CONTENT.md` and
`assets/content_manifest.json`. UI feedback uses system sounds only; no audio
files are bundled for it.

## Open permissions (owner action)

- KFGQPC Uthmanic Hafs font: written approval needed; Amiri Quran is used meanwhile.
- quran.com recitation API: production approval (developers@quran.com).
- Hisn al-Muslim text: site permission.
- Adhan recordings: licensed files to be supplied.
