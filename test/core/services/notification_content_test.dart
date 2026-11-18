import 'package:sakina_app/core/services/daily_reminder_notifications.dart';
import 'package:sakina_app/core/services/notification_content.dart';
import 'package:sakina_app/core/services/notification_tap_routing.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/navigation/notification_router.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/core/services/notification_style.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';

void main() {
  group('prayer content', () {
    final fajr = DateTime(2026, 3, 1, 4, 52);

    test('the alert keeps its words and adds the prayer time', () {
      final c = NotificationContent.prayerNotificationContent(
        prayerName: 'الفجر',
        prayerTime: fajr,
      );
      expect(c.kind, SakinaNotificationKind.prayer);
      expect(c.title, 'حان وقت صلاة الفجر');
      expect(c.body, 'اضغط لقراءة دعاء ما بعد الأذان');
      expect(c.summary, 'وقت الأذان 04:52 ص');
    });

    test('notification-only prayers use the silent channel', () {
      final c = NotificationContent.prayerNotificationContent(
        prayerName: 'الفجر',
        prayerTime: fajr,
        mode: PrayerAlertMode.notificationOnly,
      );
      expect(c.kind, SakinaNotificationKind.prayerSilent);
    });

    test('the reminder says when the prayer is, not when it fires', () {
      final c = NotificationContent.prayerNotificationContent(
        prayerName: 'الفجر',
        // Fires ten minutes before the prayer.
        prayerTime: fajr.subtract(const Duration(minutes: 10)),
        isReminder: true,
        reminderMinutes: 10,
        digits: DigitStyle.arabic,
      );
      expect(c.kind, SakinaNotificationKind.prayerReminder);
      expect(c.title, 'بقي ١٠ دقيقة على صلاة الفجر');
      expect(c.body, 'موعد الصلاة ٠٤:٥٢ ص');
    });
  });

  test('daily reminders keep the reminders channel and pick their look', () {
    expect(
      NotificationContent.dailyReminderKind('morning_adhkar'),
      SakinaNotificationKind.adhkar,
    );
    expect(
      NotificationContent.dailyReminderKind('evening_adhkar'),
      SakinaNotificationKind.adhkar,
    );
    for (final payload in ['mulk_surah', 'baqarah_surah', 'khatma']) {
      expect(
        NotificationContent.dailyReminderKind(payload),
        SakinaNotificationKind.quranReading,
      );
    }
  });

  test('debug test ids stay clear of every scheduled id', () {
    final start = DateTime(2026, 11, 16, 9);
    for (var ms = 0; ms < 20000; ms += 7) {
      final id = NotificationService.debugNotificationId(
        start.add(Duration(milliseconds: ms)),
      );
      expect(id, inInclusiveRange(90000, 99999));
    }
  });

  group('daily verse', () {
    test('a week of days never shares an id, and avoids other ranges', () {
      final start = DateTime(2026, 11, 16);
      final ids = {
        for (var d = 0; d < 7; d++)
          DailyReminderNotifications.dailyVerseNotificationId(
            start.add(Duration(days: d)),
          ),
      };
      expect(ids.length, 7);
      expect(ids.every((id) => id >= 4001 && id <= 4007), isTrue);
    });

    test('shows the whole ayah with where it is', () {
      final c = NotificationContent.dailyVerseNotificationContent((
        surah: 13,
        ayah: 28,
        text: 'نص الآية',
        surahName: 'سورة الرعد',
      ), DigitStyle.arabic);
      expect(c.title, 'آية اليوم');
      expect(c.body, 'نص الآية');
      expect(c.summary, 'سورة الرعد · الآية ٢٨');
    });
  });

  group('taps and buttons', () {
    late List<(String, Map<String, dynamic>?)> routes;

    setUp(() {
      routes = [];
      NotificationTapRouting.resetRoutingHistory();
      NotificationRouter.setNavigationCallback(
        (route, data) => routes.add((route, data)),
      );
    });
    tearDown(NotificationRouter.clearNavigationCallback);

    String prayerPayload({bool reminder = false}) => jsonEncode({
      'type': 'prayer_time',
      'data': {'prayerName': 'العصر', if (reminder) 'reminder': true},
    });

    test('the prayer alert opens the dua after the adhan', () {
      NotificationTapRouting.routeNotificationResponse(
        id: 2013,
        payload: prayerPayload(),
      );
      expect(routes.single.$1, '/prayers');
      expect(routes.single.$2?['prayerName'], 'العصر');
    });

    test('the prayer times button opens the times', () {
      NotificationTapRouting.routeNotificationResponse(
        id: 2013,
        actionId: NotificationActionIds.prayerTimes,
        payload: prayerPayload(),
      );
      expect(routes.single, ('/prayers', null));
    });

    test('a reminder before the prayer opens the times', () {
      NotificationTapRouting.routeNotificationResponse(
        id: 3013,
        payload: prayerPayload(reminder: true),
      );
      expect(routes.single, ('/prayers', null));
    });

    test('the daily verse opens the reader at its ayah', () {
      NotificationTapRouting.routeNotificationResponse(
        id: 4001,
        actionId: NotificationActionIds.open,
        payload: jsonEncode({
          'type': 'daily_verse',
          'data': {'surahNumber': 13, 'ayahNumber': 28},
        }),
      );
      expect(routes.single.$1, '/quran');
      expect(routes.single.$2?['surahNumber'], 13);
      expect(routes.single.$2?['ayahNumber'], 28);
    });

    test('a daily verse without a surah falls back to home', () {
      NotificationTapRouting.routeNotificationResponse(
        id: 4002,
        payload: jsonEncode({'type': 'daily_verse', 'data': 'broken'}),
      );
      expect(routes.single.$1, '/');
    });

    test('the same tap reported twice opens one screen', () {
      final at = DateTime(2026, 1, 1, 12);
      for (final offset in [0, 500, 1500]) {
        NotificationTapRouting.routeNotificationResponse(
          id: 1001,
          payload: jsonEncode({'type': 'morning_adhkar'}),
          now: at.add(Duration(milliseconds: offset)),
        );
      }
      expect(routes.length, 1);

      // A later tap, or another button, is a new request.
      NotificationTapRouting.routeNotificationResponse(
        id: 1001,
        payload: jsonEncode({'type': 'morning_adhkar'}),
        now: at.add(const Duration(seconds: 5)),
      );
      NotificationTapRouting.routeNotificationResponse(
        id: 1001,
        actionId: NotificationActionIds.open,
        payload: jsonEncode({'type': 'morning_adhkar'}),
        now: at.add(const Duration(seconds: 5)),
      );
      expect(routes.length, 3);
    });

    test('a tap during startup waits and keeps its button', () {
      NotificationRouter.hold();
      NotificationTapRouting.routeNotificationResponse(
        id: 2013,
        actionId: NotificationActionIds.prayerTimes,
        payload: prayerPayload(),
      );
      expect(routes, isEmpty);
      NotificationRouter.release();
      expect(routes.single, ('/prayers', null));
    });
  });
}
