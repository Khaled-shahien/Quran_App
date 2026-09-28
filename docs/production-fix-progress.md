# Production fix progress

## 2026-09-28 — Prayer location request ordering

Compared the blueprint's first blockers with the current implementation:

- Prayer location already supports device GPS and manual coordinates. An
  unconfigured installation does not silently use Cairo. Manual city search
  and physical-device location verification remain separate work.
- Android release builds already require release signing properties and forbid
  falling back to debug signing. A production-signed artifact was not verified.

Fixed asynchronous request ordering in `PrayerTimesProvider`: late location
lookups, failures, and manual selections cannot overwrite a newer request.
Pending lookups cannot start repository requests after disposal. Date correction
also stops when another request has taken ownership of the state.

Added four regression tests covering stale lookup success, stale lookup failure,
overlapping manual selections, and completion after disposal.

Validation:

- `flutter test test/features/prayers`: 31 tests passed.
- `dart analyze lib/features/prayers test/features/prayers`: no issues.

This batch does not establish production readiness. Device notification delivery,
release credentials, remaining blueprint findings, and full release verification
still require work.
