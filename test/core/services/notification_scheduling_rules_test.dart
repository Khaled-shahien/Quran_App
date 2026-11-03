import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back to inexact alarms only when exact access is denied', () {
    expect(
      NotificationService.scheduleModeFor(canScheduleExact: false),
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
    for (final allowed in [true, null]) {
      expect(
        NotificationService.scheduleModeFor(canScheduleExact: allowed),
        AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  });

  group('nextDailyOccurrence', () {
    late tz.Location newYork;
    setUpAll(() {
      tzdata.initializeTimeZones();
      newYork = tz.getLocation('America/New_York');
    });

    test('keeps the wall-clock time across a daylight-saving change', () {
      // Clocks move forward on 8 March 2026 in New York.
      final next = NotificationService.nextDailyOccurrence(
        tz.TZDateTime(newYork, 2026, 3, 7, 8),
        7,
        0,
      );
      expect((next.month, next.day, next.hour, next.minute), (3, 8, 7, 0));
    });

    test('uses today while the time is more than two minutes away', () {
      final next = NotificationService.nextDailyOccurrence(
        tz.TZDateTime(newYork, 2026, 6, 1, 6, 57),
        7,
        0,
      );
      expect((next.day, next.hour), (1, 7));
    });

    test('moves to tomorrow inside the two-minute margin', () {
      final next = NotificationService.nextDailyOccurrence(
        tz.TZDateTime(newYork, 2026, 6, 30, 6, 59),
        7,
        0,
      );
      expect((next.month, next.day, next.hour), (7, 1, 7));
    });
  });

  test('first initialization can request permissions without deadlock', () {
    expect(
      NotificationService()
          .initialize(requestPermissions: true)
          .timeout(const Duration(seconds: 5)),
      completes,
    );
  });
}
