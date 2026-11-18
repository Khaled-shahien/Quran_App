import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import 'local_timezone_fallback.dart';

/// Time zone and wall-clock rules shared by every scheduled notification.
abstract final class NotificationTiming {
  /// Sets `tz.local` to the device's timezone ([lookup] defaults to the
  /// platform) and returns whether it changed. Falls back to a fixed zone
  /// for the current UTC offset when the name cannot be resolved.
  static Future<bool> applyDeviceTimezone({
    Future<String> Function()? lookup,
  }) async {
    final String before = tz.local.name;
    try {
      final String timezoneName =
          await (lookup ?? FlutterTimezone.getLocalTimezone)();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      tz.setLocalLocation(
        fallbackLocationForOffset(DateTime.now().timeZoneOffset),
      );
      developer.log(
        'Failed to resolve local timezone, using current UTC offset',
        name: 'sakina_app.notifications',
        level: 900,
        error: e,
      );
    }
    developer.log(
      'Notification timezone configured. Final selected timezone: ${tz.local.name}',
      name: 'sakina_app.notifications',
    );
    return tz.local.name != before;
  }

  /// Exact access can be denied or revoked. Scheduling exactly would then
  /// throw, so a slightly late reminder is the fallback to no reminder at all.
  static AndroidScheduleMode scheduleModeFor({
    required bool? canScheduleExact,
  }) => canScheduleExact == false
      ? AndroidScheduleMode.inexactAllowWhileIdle
      : AndroidScheduleMode.exactAllowWhileIdle;

  /// The next wall-clock [hour]:[minute] at least two minutes after [now].
  /// Calendar arithmetic keeps the time correct across a daylight-saving
  /// change, which adding 24 hours would shift by an hour.
  static tz.TZDateTime nextDailyOccurrence(
    tz.TZDateTime now,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime today = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!today.isBefore(now.add(const Duration(minutes: 2)))) return today;
    return tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }

  static String formatHHmm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
