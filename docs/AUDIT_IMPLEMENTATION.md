# Audit implementation — 2026-09-22

This is the implementation follow-up to `AUDIT_REPORT.md`. The original report remains historical evidence. Existing user changes to the audit, prayer cache/test and splash were preserved. No release was published and no production identity was invented.

| Issue | Implemented | Remaining boundary |
|---|---|---|
| AUD-001 | Removed silent Cairo defaults from Home and prayer widgets; one shared provider; explicit GPS/manual coordinates, label/method persistence and validation; displayed coordinates/timezone | Manual city lookup, madhab/high-latitude controls and approved calculation policy; device permission/travel verification |
| AUD-002 | Central method policy, existing Egyptian default exposed with selectable MWL/Umm al-Qura alternatives | Religious/product approval of available policies |
| AUD-003 | Retained existing keyed write-through cache; added same-key stale network/API fallback and freshness metadata; preserved successful responses if cache writing fails; refresh on resume/date rollover; timezone-aware display/scheduling | Multi-day background replenishment; DST/travel/offline device matrix; cache retention limits |
| AUD-004 | Removed debug release signing; Gradle requires real key.properties for release tasks | Supply protected signing credentials; signed artifact verification |
| AUD-005/018 | Added native identity gate for approved IDs/project, Android config, real iOS plist and Xcode ID, wired to tags/manual CI | Final IDs, genuine Firebase files, regenerated Dart Firebase options and platform validation |
| AUD-006 | Platform default sound with a new Android channel ID instead of missing adhan resource | Licensed recording and device sound verification if adhan is desired |
| AUD-007 | Retained token redaction; documented actual backend gap | Registration/refresh/delete backend contract and implementation; not claimed complete |
| AUD-008 | Added the installed notification plugin's scheduled-notification and boot/update receivers | Real reboot/update tests and scheduling future days while closed |
| AUD-009 | Canonical `/khatma` screen reuses current-wird UI; notification handler now opens it; fixed-surah notification payload cannot override the intended surah | Foreground/background/terminated notification tap matrix |
| AUD-010 | Offline Quran verse search, Arabic normalization, unchanged original text highlighting, deterministic ordering, empty/error states and exact ayah/page navigation | Optional surah-name/multi-collection search and further ranking |
| AUD-011 | Added flutter_localizations/intl, Arabic ARB generation/delegates, migrated core prayer/search messages; removed English prayer states | Remaining feature strings, complete date formatting/bidi review and any additional languages |
| AUD-012 | Flexible prayer hero, wrapped time/countdown, explicit control tooltips, reduced-motion loader stops its ticker | Whole-app large-text, contrast and assistive-technology device audit |
| AUD-013 | Minute-based display refresh in place of second-based updates; shared Home/prayer source | Startup/background initialization refactor and measured startup/frame/memory/battery evidence |
| AUD-014 | SHA-256 baseline and CI integrity check for existing Quran/dua/prayer/hadith files; sources status page and review workflow | Source, edition, license, scholar/content-owner approvals and translations review |
| AUD-015 | Removed placeholder donation action | Add only an approved real URL if needed |
| AUD-016 | Preserved prior retry-test fix; updated tests for Arabic copy and explicit injected coordinates; added regression coverage | Production AppRoot smoke coverage (existing integration smoke remains a simple widget-tree test) |
| AUD-017 | Data inventory and in-app privacy/sources page; removed request query/response-body logging from shared API path and prayer service | Approved public policy, unified data deletion and backend deletion lifecycle |

## Validation

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: **204 passed**, zero failures.
- `flutter test --no-pub integration_test -d emulator-5554`: **4 passed**, zero failures, on Android 16/API 36 emulator; debug APK built and installed. These exercise the existing widget smoke, duas, prayer retry/display and Quran reading flows, not production AppRoot startup or notification delivery.
- `dart format --output=none --set-exit-if-changed lib test integration_test`: 214 files, zero formatting changes required.
- `python scripts/verify_content.py`: four original asset hashes passed.
- `python scripts/verify_release.py`: intentionally blocked on missing approved identities and genuine iOS Firebase configuration.
- `android/gradlew.bat :app:assembleRelease --dry-run --console=plain`: intentionally rejected with `Release signing required: configure android/key.properties. Debug signing is forbidden.` Debug builds remain functional.
- Diff whitespace checks passed for implementation files. The original report contains pre-existing Markdown hard line breaks and was not wholesale reformatted.

Debug emulator tests do not prove physical-device notification delivery, signed-release readiness, Qibla sensor accuracy or iOS behavior. No full visual or screen-reader audit was performed.

## Release inputs

See `RELEASE_REQUIREMENTS.md` and `PRIVACY_AND_CONTENT.md`. The release identity gate intentionally fails with the current sample/missing configuration. P2/P3 roadmap ideas such as widgets and analytics were not treated as authorization to invent product requirements.
