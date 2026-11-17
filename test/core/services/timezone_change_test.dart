import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The process follows a device timezone change (audit NOTIF-02).
void main() {
  setUpAll(tzdata.initializeTimeZones);
  setUp(() => tz.setLocalLocation(tz.getLocation('Africa/Cairo')));

  test('reports no change when the device zone is the same', () async {
    expect(
      await NotificationService.applyDeviceTimezone(
        lookup: () async => 'Africa/Cairo',
      ),
      isFalse,
    );
    expect(tz.local.name, 'Africa/Cairo');
  });

  test('switches tz.local and reports a change after travel', () async {
    expect(
      await NotificationService.applyDeviceTimezone(
        lookup: () async => 'Europe/London',
      ),
      isTrue,
    );
    expect(tz.local.name, 'Europe/London');
    // A daily 07:00 reminder is now computed in the new zone.
    final next = NotificationService.nextDailyOccurrence(
      tz.TZDateTime(tz.local, 2026, 1, 10, 6),
      7,
      0,
    );
    expect(next.location.name, 'Europe/London');
    expect(next.hour, 7);
  });

  test('an unknown zone name falls back to a fixed offset zone', () async {
    await NotificationService.applyDeviceTimezone(
      lookup: () async => 'Not/AZone',
    );
    expect(tz.local.name, isNot('Not/AZone'));
  });
}
