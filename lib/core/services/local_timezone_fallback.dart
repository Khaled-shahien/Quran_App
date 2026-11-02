import 'package:timezone/timezone.dart' as tz;

/// Picks a zone matching the device's current UTC offset when the platform
/// cannot name its timezone. A match can differ on future DST changes, but it
/// keeps reminders at the right local time today instead of assuming one city.
tz.Location fallbackLocationForOffset(Duration offset, {DateTime? now}) {
  final instantMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
  bool matches(tz.Location location) =>
      tz.TZDateTime.fromMillisecondsSinceEpoch(
        location,
        instantMs,
      ).timeZoneOffset ==
      offset;

  final cairo = tz.getLocation('Africa/Cairo');
  if (matches(cairo)) return cairo;

  final names = tz.timeZoneDatabase.locations.keys.toList()..sort();
  for (final name in names) {
    final location = tz.getLocation(name);
    if (matches(location)) return location;
  }
  return tz.UTC;
}
