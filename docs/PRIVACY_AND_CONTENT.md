# Data and content inventory

Implementation inventory, not a legally approved privacy policy. Publication remains blocked until the product owner approves the policy, contact details, retention and third-party disclosures.

| Data | Purpose and storage | Deletion/control |
|---|---|---|
| Selected prayer coordinates, label and method | Local SharedPreferences; coordinates sent to Aladhan on foreground refresh and background replenishment of today plus two future days; background work uses saved coordinates, not GPS | Change location in Prayer; disabling prayer reminders stops background prayer fetches; clearing app storage removes local preferences |
| Qibla location | Device location for direction calculation | Revoke location permission in OS settings |
| Prayer response cache | Local date/location/method cache with retrieval timestamp; old same-day cache labeled stale | Clearing app storage removes cache |
| Bookmarks, favorites, Khatma, preferences | Local SharedPreferences | Existing feature controls; clearing app storage removes all local state |
| Notification schedules | OS/plugin schedule storage | OS notification settings and existing notification controls |
| Optional crash/usage reports | Disabled by default; supported mobile builds require `ENABLE_FIREBASE_MONITORING=true` and user opt-in. Sends exception types/stacks and app/settings-open events, not reading/search/location values | Settings opt-out disables collection, deletes unsent reports and resets local analytics data; server retention needs owner approval |
| Push notifications | Not supported; messaging dependency, handlers and token controls removed | Local reminders do not register push tokens; optional monitoring is separately controlled |
| Media/network requests | Aladhan, configured media sources and externally opened links; Firebase when configured for optional monitoring | Network services receive request metadata; their retention is not controlled by this repository |

No claim is made that uninstall deletes third-party records or OS backups. A unified in-app data deletion flow and backend token deletion contract remain pending. API URL query values and prayer response bodies must not be logged.

## Religious content governance

`content_manifest.json` records SHA-256 baselines of existing assets. These hashes detect changes; they do not certify correctness, licensing, authenticity, edition or provenance. Source metadata is explicitly `pending_owner_review` until supplied and approved. Sacred text was not modified during these fixes.

For each collection, the content owner must record source, edition/version, license, reviewer, approval date and evidence. Hadith additionally needs attribution/grading where applicable; duas need count/source checks. Do not invent missing metadata. Changes to asset bytes require review before updating the manifest. Run `python scripts/verify_content.py` in CI.

The release workflow additionally runs `python scripts/verify_content.py --require-approved`; it intentionally fails while approval is pending. The in-app sources page exposes the pending provenance status. See `PRIVACY_POLICY_DRAFT_AR.md` for the public-policy draft and `THIRD_PARTY_ASSETS.md` for font and city-catalog attribution.

Adhan is currently the platform notification sound. A licensed, approved recording and real-device playback tests are needed before advertising adhan audio.
