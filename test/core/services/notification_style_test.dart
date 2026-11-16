import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/services/notification_channels.dart';
import 'package:sakina_app/core/services/notification_style.dart';
import 'package:sakina_app/core/theme/app_colors.dart';

void main() {
  AndroidNotificationDetails android(
    SakinaNotificationKind kind, {
    String? body = 'body',
  }) => buildNotificationDetails(kind, title: 'title', body: body).android!;

  group('channels', () {
    // Android keeps users' per-channel choices by id: these must not move.
    const expected = {
      SakinaNotificationKind.adhkar: 'sakina_alarms_channel',
      SakinaNotificationKind.quranReading: 'sakina_alarms_channel',
      SakinaNotificationKind.prayer: 'prayer_times_default_sound_v2',
      SakinaNotificationKind.prayerSilent: 'prayer_times_silent_v1',
      SakinaNotificationKind.prayerReminder: 'prayer_reminders_v1',
      SakinaNotificationKind.dailyVerse: 'sakina_daily_verse_v1',
      SakinaNotificationKind.general: 'sakina_app_channel',
      SakinaNotificationKind.test: 'test_channel',
    };

    for (final MapEntry(:key, :value) in expected.entries) {
      test('${key.name} uses $value', () {
        expect(android(key).channelId, value);
      });
    }

    test('every channel used is created, once', () {
      final ids = NotificationChannels.all().map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.toSet(), containsAll(expected.values.toSet()));
    });

    test('sound and importance stay as before', () {
      expect(android(SakinaNotificationKind.prayer).importance, Importance.max);
      expect(android(SakinaNotificationKind.prayer).playSound, isTrue);
      expect(
        android(SakinaNotificationKind.prayerSilent).playSound,
        isFalse,
        reason: 'notification-only prayers stay silent',
      );
      expect(android(SakinaNotificationKind.adhkar).importance, Importance.max);
      expect(
        android(SakinaNotificationKind.adhkar).category,
        AndroidNotificationCategory.alarm,
      );
      expect(
        android(SakinaNotificationKind.dailyVerse).importance,
        Importance.defaultImportance,
      );
    });
  });

  group('shared look', () {
    test('every kind has the brand colour and both icons', () {
      for (final kind in SakinaNotificationKind.values) {
        final details = android(kind);
        expect(details.icon, '@drawable/ic_notification');
        expect(details.color, AppColors.lightPrimary);
        final large = details.largeIcon as DrawableResourceAndroidBitmap;
        expect(large.data, '@drawable/ic_notification_large');
      }
    });

    test('long text expands instead of being cut to one line', () {
      final details = buildNotificationDetails(
        SakinaNotificationKind.dailyVerse,
        title: 'آية اليوم',
        body: 'نص طويل',
        summary: 'سورة الرعد · الآية 28',
      ).android!;
      final style = details.styleInformation as BigTextStyleInformation;
      expect(style.bigText, 'نص طويل');
      expect(style.contentTitle, 'آية اليوم');
      expect(details.subText, 'سورة الرعد · الآية 28', reason: 'in the header');
    });

    test('no body, no expanded style', () {
      expect(
        android(SakinaNotificationKind.general, body: null).styleInformation,
        isNull,
      );
    });

    test('the header names the category', () {
      expect(android(SakinaNotificationKind.adhkar).subText, 'الأذكار');
      expect(android(SakinaNotificationKind.prayer).subText, 'الصلاة');
      expect(android(SakinaNotificationKind.general).subText, isNull);
    });

    test('a reminder can leave the tray by itself', () {
      final details = buildNotificationDetails(
        SakinaNotificationKind.prayerReminder,
        timeoutAfter: const Duration(minutes: 10),
      ).android!;
      expect(details.timeoutAfter, 600000);
    });
  });

  group('actions', () {
    List<String> ids(SakinaNotificationKind kind) =>
        android(kind).actions!.map((a) => a.id).toList();

    test('each category offers its own buttons', () {
      expect(ids(SakinaNotificationKind.adhkar), [NotificationActionIds.open]);
      expect(ids(SakinaNotificationKind.quranReading), [
        NotificationActionIds.open,
      ]);
      expect(ids(SakinaNotificationKind.prayer), [
        NotificationActionIds.open,
        NotificationActionIds.prayerTimes,
      ]);
      expect(ids(SakinaNotificationKind.prayerReminder), [
        NotificationActionIds.prayerTimes,
      ]);
      expect(ids(SakinaNotificationKind.dailyVerse), [
        NotificationActionIds.open,
      ]);
      expect(ids(SakinaNotificationKind.general), isEmpty);
    });

    test('every button opens the app, so no background handler is needed', () {
      for (final kind in SakinaNotificationKind.values) {
        for (final action in android(kind).actions!) {
          expect(action.showsUserInterface, isTrue, reason: kind.name);
          expect(action.title, isNotEmpty);
        }
      }
    });

    test('iOS gets a category for every kind with buttons', () {
      final categories = {
        for (final c in darwinNotificationCategories()) c.identifier: c,
      };
      for (final kind in SakinaNotificationKind.values) {
        final ios = buildNotificationDetails(kind).iOS!;
        final buttons = notificationActionsFor(kind);
        if (buttons.isEmpty) {
          expect(ios.categoryIdentifier, isNull);
          continue;
        }
        final category = categories[ios.categoryIdentifier]!;
        expect(category.actions.map((a) => a.identifier), [
          for (final b in buttons) b.id,
        ]);
        for (final action in category.actions) {
          expect(
            action.options,
            contains(DarwinNotificationActionOption.foreground),
          );
        }
      }
    });

    test('iOS groups by category and keeps silent prayers silent', () {
      final prayer = buildNotificationDetails(SakinaNotificationKind.prayer);
      final reminder = buildNotificationDetails(
        SakinaNotificationKind.prayerReminder,
      );
      expect(prayer.iOS!.threadIdentifier, reminder.iOS!.threadIdentifier);
      expect(
        buildNotificationDetails(
          SakinaNotificationKind.prayerSilent,
        ).iOS!.presentSound,
        isFalse,
      );
    });
  });

  group('time', () {
    test('reads like the clock, in the chosen digits', () {
      expect(
        formatNotificationTime(DateTime(2026, 1, 1, 4, 52), DigitStyle.western),
        '04:52 ص',
      );
      expect(
        formatNotificationTime(DateTime(2026, 1, 1, 12, 5), DigitStyle.western),
        '12:05 م',
      );
      expect(
        formatNotificationTime(DateTime(2026, 1, 1, 0, 30), DigitStyle.western),
        '12:30 ص',
      );
      expect(
        formatNotificationTime(DateTime(2026, 1, 1, 18, 7), DigitStyle.arabic),
        '٠٦:٠٧ م',
      );
    });
  });
}
