/// Native Android alarms that notifications alone cannot provide: turning
/// on Do Not Disturb for a while after the adhan, and the Fajr wake alarm
/// (full screen, escalating sound, snooze limited by sunrise).
///
/// Every call is a no-op where the plugin is missing (tests, iOS), so the
/// prayer alerts themselves never depend on it.
library;

import 'package:flutter/services.dart';

/// A span during which the phone should be in Do Not Disturb.
typedef QuietWindow = ({DateTime start, DateTime end});

/// What the Fajr wake screen says. Everything is supplied by the app so
/// the native side holds no user-facing text.
class FajrWakeTexts {
  const FajrWakeTexts({
    required this.title,
    required this.body,
    required this.stop,
    required this.snooze,
    required this.untilSunrise,
    required this.sunriseReached,
    required this.channelName,
    this.arabicDigits = true,
  });

  final String title;
  final String body;
  final String stop;

  /// Snooze button label, minutes already included.
  final String snooze;

  /// Contains `%s` where the minutes left until sunrise go.
  final String untilSunrise;
  final String sunriseReached;
  final String channelName;
  final bool arabicDigits;

  Map<String, Object?> toMap() => {
    'title': title,
    'body': body,
    'stop': stop,
    'snooze': snooze,
    'untilSunrise': untilSunrise,
    'sunriseReached': sunriseReached,
    'channelName': channelName,
    'arabicDigits': arabicDigits,
  };
}

/// One morning's wake alarm.
class FajrWakeAlarm {
  const FajrWakeAlarm({
    required this.at,
    required this.sunrise,
    required this.snoozeMinutes,
    required this.texts,
    this.sound,
  });

  final DateTime at;
  final DateTime sunrise;
  final int snoozeMinutes;
  final FajrWakeTexts texts;

  /// Raw resource name of the recording; the device alarm sound when null.
  final String? sound;

  Map<String, Object?> toMap() => {
    'at': at.millisecondsSinceEpoch,
    'sunrise': sunrise.millisecondsSinceEpoch,
    'snoozeMinutes': snoozeMinutes,
    'sound': sound,
    'texts': texts.toMap(),
  };
}

abstract final class SakinaAlarms {
  static const MethodChannel _channel = MethodChannel('sakina/alarms');

  /// The calendar day key used to replace one day's entries.
  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Replaces the quiet windows of [day]; an empty list removes them.
  static Future<void> setQuietWindows(
    DateTime day,
    List<QuietWindow> windows,
  ) => _call<void>('setQuietWindows', {
    'day': dayKey(day),
    'windows': [
      for (final w in windows)
        [w.start.millisecondsSinceEpoch, w.end.millisecondsSinceEpoch],
    ],
  });

  /// Replaces the wake alarm of [day]; null removes it.
  static Future<void> setFajrWake(DateTime day, FajrWakeAlarm? alarm) =>
      _call<void>('setFajrWake', {'day': dayKey(day), 'alarm': alarm?.toMap()});

  /// Removes every quiet window and wake alarm (and ends a quiet period
  /// this app started).
  static Future<void> clearAll() => _call<void>('clearAll');

  /// Null where the question does not apply (no plugin, not Android).
  static Future<bool?> hasDndAccess() => _call<bool>('hasDndAccess');

  static Future<void> openDndAccessSettings() =>
      _call<void>('openDndAccessSettings');

  /// Android 14+ lets the user withdraw full-screen alarms per app.
  static Future<bool?> canUseFullScreenIntent() =>
      _call<bool>('canUseFullScreenIntent');

  static Future<void> openFullScreenIntentSettings() =>
      _call<void>('openFullScreenIntentSettings');
}
