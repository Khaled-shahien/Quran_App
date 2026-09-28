import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

tz.Location? prayerLocation(String? name) {
  if (name == null || name.isEmpty) return null;
  if (!_initialized) {
    data.initializeTimeZones();
    _initialized = true;
  }
  // Reject an unknown API timezone instead of silently scheduling in device time.
  return tz.getLocation(name);
}

DateTime prayerWallTime(DateTime instant, String? zone) {
  final location = prayerLocation(zone);
  return location == null ? instant : tz.TZDateTime.from(instant, location);
}

DateTime prayerInstant(DateTime date, int hour, int minute, String? zone) {
  final location = prayerLocation(zone);
  return location == null
      ? DateTime(date.year, date.month, date.day, hour, minute)
      : tz.TZDateTime(location, date.year, date.month, date.day, hour, minute);
}
