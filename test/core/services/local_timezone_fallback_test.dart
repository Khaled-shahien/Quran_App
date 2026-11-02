import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/local_timezone_fallback.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);
  final instant = DateTime.utc(2026, 1, 15, 12);

  Duration offsetOf(tz.Location location) =>
      tz.TZDateTime.from(instant, location).timeZoneOffset;

  test('keeps Cairo when it matches the device offset', () {
    final location = fallbackLocationForOffset(
      offsetOf(tz.getLocation('Africa/Cairo')),
      now: instant,
    );
    expect(location.name, 'Africa/Cairo');
  });

  test('uses the device offset elsewhere instead of assuming Cairo', () {
    for (final hours in [-5, 0, 3, 8]) {
      final offset = Duration(hours: hours);
      final location = fallbackLocationForOffset(offset, now: instant);
      expect(offsetOf(location), offset);
    }
  });

  test('an offset no zone uses falls back to UTC', () {
    expect(
      fallbackLocationForOffset(const Duration(hours: 20), now: instant),
      tz.UTC,
    );
  });
}
