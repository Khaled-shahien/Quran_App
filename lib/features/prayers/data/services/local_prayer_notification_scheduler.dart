import '../../domain/prayer_time_zone.dart';
import 'dart:developer' as developer;

import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/core/services/scheduling_generation.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/adhan_settings.dart';
import '../repositories/adhan_settings_store.dart';

abstract class PrayerNotificationGateway {
  Future<void> scheduleAllPrayersForDate({
    required Map<DailyPrayer, DateTime> prayerTimes,
    required AdhanSettings settings,
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
    return _notificationService.prayers.cancelAllPrayerNotifications();
  }

  @override
  Future<void> scheduleAllPrayersForDate({
    required Map<DailyPrayer, DateTime> prayerTimes,
    required AdhanSettings settings,
  }) {
    return _notificationService.prayers.scheduleAllPrayersForDate(
      prayerTimes: prayerTimes,
      settings: settings,
    );
  }
}

class LocalPrayerNotificationScheduler implements PrayerNotificationScheduler {
  LocalPrayerNotificationScheduler({
    required SharedPreferences prefs,
    PrayerNotificationGateway? notificationGateway,
    Future<void> Function()? onScheduled,
    bool claimsSchedule = false,
  }) : _prefs = prefs,
       _onScheduled = onScheduled,
       _claimsSchedule = claimsSchedule,
       _notificationGateway =
           notificationGateway ??
           NotificationServicePrayerNotificationGateway();

  static const String prayerNotificationsEnabledPreferenceKey =
      'prayer_notifications_enabled';

  final SharedPreferences _prefs;
  final PrayerNotificationGateway _notificationGateway;
  final Future<void> Function()? _onScheduled;

  /// True for the UI isolate's scheduler: each change first advances the
  /// [SchedulingGeneration], so a background reschedule already running
  /// stops before it overwrites this one.
  final bool _claimsSchedule;

  Future<void> _claim() async {
    if (_claimsSchedule) await SchedulingGeneration.bump(_prefs);
  }

  @override
  Future<void> cancelPrayerNotifications() async {
    await _claim();
    await _notificationGateway.cancelAllPrayerNotifications();
  }

  @override
  Future<void> schedulePrayerNotifications({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) async {
    await _claim();
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

    final Map<DailyPrayer, DateTime> schedule = buildPrayerSchedule(
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

    // Read on every schedule so background reschedules use current choices.
    await _notificationGateway.scheduleAllPrayersForDate(
      prayerTimes: schedule,
      settings: AdhanSettingsStore(_prefs).read(),
    );
    await _onScheduled?.call();
  }

  /// Parses a day's API timings without mutating pending notifications.
  static Map<DailyPrayer, DateTime> buildPrayerSchedule({
    required PrayerTimesEntity prayerTimes,
    required DateTime date,
  }) {
    final Map<DailyPrayer, DateTime> schedule = <DailyPrayer, DateTime>{};

    void addPrayer(DailyPrayer prayer, String? rawTime) {
      final DateTime? parsed = _parsePrayerTime(
        rawTime,
        date,
        prayerTimes.timezone,
      );
      if (parsed == null) {
        developer.log(
          'Unable to parse prayer time for ${prayer.name}: $rawTime',
          name: 'sakina_app.prayer_notifications',
          level: 900,
        );
        return;
      }
      schedule[prayer] = parsed;
    }

    addPrayer(DailyPrayer.fajr, prayerTimes.fajr);
    addPrayer(DailyPrayer.dhuhr, prayerTimes.dhuhr);
    addPrayer(DailyPrayer.asr, prayerTimes.asr);
    addPrayer(DailyPrayer.maghrib, prayerTimes.maghrib);
    addPrayer(DailyPrayer.isha, prayerTimes.isha);

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
