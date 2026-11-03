import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_zone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('resolving a prayer zone keeps the device zone used by alarms', () {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

    expect(prayerLocation('America/Los_Angeles')!.name, 'America/Los_Angeles');

    // Reloading the database would reset this to UTC and shift every alarm.
    expect(tz.local.name, 'Africa/Cairo');
  });
}
