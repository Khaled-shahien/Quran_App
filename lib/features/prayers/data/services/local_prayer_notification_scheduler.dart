import 'package:sakina_app/l10n/localization.dart';
import '../../domain/prayer_time_zone.dart';
import 'dart:developer' as developer;

import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PrayerNotificationGateway {
  Future<void> scheduleAllPrayersForDate({
    required Map<String, DateTime> prayerTimes,
  });

  Future<void> cancelAllPrayerNotifications();
}

class NotificationServicePrayerNotificationGateway
    implements PrayerNotificationGateway {
  NotificationServicePrayerNotificationGateway({
    NotificationService? notificationService,
  }) : _notificationService =
           notificationService ?? NotificationService.instance;

  final NotificationService _notificationService;

  @override
  Future<void> cancelAllPrayerNotifications() {
    return _notificationService.cancelAllPrayerNotifications();
  }

  @override
  Future<void> scheduleAllPrayersForDate({
    required Map<String, DateTime> prayerTimes,
  }) {
    return _notificationService.scheduleAllPrayersForDate(
      prayerTimes: prayerTimes,
    );
  }
}

class LocalPrayerNotificationScheduler implements PrayerNotificationScheduler {
  LocalPrayerNotificationScheduler({
    required SharedPreferences prefs,
    PrayerNotificationGateway? notificationGateway,
    Future<void> Function()? onScheduled,
  }) : _prefs = prefs,
       _onScheduled = onScheduled,
       _notificationGateway =
           notificationGateway ??
           NotificationServicePrayerNotificationGateway();

  static const String prayerNotificationsEnabledPreferenceKey =
      'prayer_notifications_enabled';

  final SharedPreferences _prefs;
  final PrayerNotificationGateway _notificationGateway;
  final Future<void> Function()? _onScheduled;

  @override
  Future<void> cancelPrayerNotifications() =>
      _notificationGateway.cancelAllPrayerNotifications();

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) async {
    final bool notificationsEnabled =
        _prefs.getBool(prayerNotificationsEnabledPreferenceKey) ?? true;

    if (!notificationsEnabled) {
      await _notificationGateway.cancelAllPrayerNotifications();
      developer.log(
        'Prayer notifications disabled by user preference',
        name: 'sakina_app.prayer_notifications',
      );
      return;
    }

    final Map<String, DateTime> schedule = buildPrayerSchedule(
      prayerTimes: prayerTimes,
      date: date,
    );

    if (schedule.isEmpty) {
      await _notificationGateway.cancelAllPrayerNotifications();
      developer.log(
        'No valid prayer times available for notification scheduling',
        name: 'sakina_app.prayer_notifications',
        level: 900,
      );
      return;
    }

    await _notificationGateway.scheduleAllPrayersForDate(prayerTimes: schedule);
    await _onScheduled?.call();
  }

  /// Parses a day's API timings without mutating pending notifications.
  static Map<String, DateTime> buildPrayerSchedule({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) {
    final Map<String, DateTime> schedule = <String, DateTime>{};

    void addPrayer(String arabicName, String? rawTime) {
      final DateTime? parsed = _parsePrayerTime(
        rawTime,
        date,
        prayerTimes.timezone,
      );
      if (parsed == null) {
        developer.log(
          'Unable to parse prayer time for $arabicName: $rawTime',
          name: 'sakina_app.prayer_notifications',
          level: 900,
        );
        return;
      }
      schedule[arabicName] = parsed;
    }

    addPrayer(appL10n.prayerTimesWidgetMessage8, prayerTimes.fajr);
    addPrayer(appL10n.prayerTimesWidgetMessage9, prayerTimes.dhuhr);
    addPrayer(appL10n.prayerTimesWidgetMessage10, prayerTimes.asr);
    addPrayer(appL10n.prayerTimesWidgetMessage11, prayerTimes.maghrib);
    addPrayer(appL10n.prayerTimesWidgetMessage12, prayerTimes.isha);

    return schedule;
  }

  static DateTime? _parsePrayerTime(
    String? rawTime,
    DateTime date,
    String? zone,
  ) {
    if (rawTime == null || rawTime.trim().isEmpty) {
      return null;
    }

    final RegExpMatch? match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(rawTime);
    if (match == null) {
      return null;
    }

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String normalized = rawTime.toUpperCase();

    if (normalized.contains('PM') && hour < 12) {
      hour += 12;
    } else if (normalized.contains('AM') && hour == 12) {
      hour = 0;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return prayerInstant(date, hour, minute, zone);
  }
}
