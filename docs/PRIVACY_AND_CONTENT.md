# Data and content inventory

Implementation inventory, not a legally approved privacy policy. Publication remains blocked until the product owner approves the policy, contact details, retention and third-party disclosures.

| Data | Purpose and storage | Deletion/control |
|---|---|---|
| Selected prayer coordinates, label and method | Local SharedPreferences; coordinates sent to Aladhan when requesting timings | Change location in Prayer; clearing app storage removes local preferences |
| Qibla location | Device location for direction calculation | Revoke location permission in OS settings |
| Prayer response cache | Local date/location/method cache with retrieval timestamp; old same-day cache labeled stale | Clearing app storage removes cache |
| Bookmarks, favorites, Khatma, preferences | Local SharedPreferences | Existing feature controls; clearing app storage removes all local state |
| Notification schedules | OS/plugin schedule storage | OS notification settings and existing notification controls |
| FCM token | Firebase installation/messaging delivery | Firebase deletion API exists; no app backend registration contract exists yet |
| Media/network requests | Aladhan, Firebase, configured media sources and externally opened links | Network services receive request metadata; their retention is not controlled by this repository |

No claim is made that uninstall deletes third-party records or OS backups. A unified in-app data deletion flow and backend token deletion contract remain pending. API URL query values and prayer response bodies must not be logged.

## Religious content governance

`content_manifest.json` records SHA-256 baselines of existing assets. These hashes detect changes; they do not certify correctness, licensing, authenticity, edition or provenance. Source metadata is explicitly `pending_owner_review` until supplied and approved. Sacred text was not modified during these fixes.

For each collection, the content owner must record source, edition/version, license, reviewer, approval date and evidence. Hadith additionally needs attribution/grading where applicable; duas need count/source checks. Do not invent missing metadata. Changes to asset bytes require review before updating the manifest. Run `python scripts/verify_content.py` in CI.

Adhan is currently the platform notification sound. A licensed, approved recording and real-device playback tests are needed before advertising adhan audio.
