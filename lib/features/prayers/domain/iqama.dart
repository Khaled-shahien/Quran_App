import 'package:shared_preferences/shared_preferences.dart';

import 'entities/adhan_settings.dart';

/// The user's mosque: how many minutes after the adhan each prayer's iqama
/// is, and an optional alert before it. Entered by hand and kept on the
/// phone; no mosque data or location is looked up.
class IqamaSettings {
  const IqamaSettings({this.minutes = const {}, this.alertMinutes = 0});

  /// 0 means "not set" for that prayer.
  static const List<int> options = [0, 5, 10, 15, 20, 25, 30, 40, 45];

  /// 0 means no alert.
  static const List<int> alertOptions = [0, 5, 10, 15];

  final Map<DailyPrayer, int> minutes;
  final int alertMinutes;

  int of(DailyPrayer prayer) => minutes[prayer] ?? 0;

  bool get isEmpty => DailyPrayer.values.every((p) => of(p) == 0);

  /// When the iqama is, or null when not set for [prayer].
  DateTime? iqamaAt(DailyPrayer prayer, DateTime adhan) =>
      of(prayer) == 0 ? null : adhan.add(Duration(minutes: of(prayer)));

  IqamaSettings withMinutes(DailyPrayer prayer, int value) => IqamaSettings(
    minutes: {...minutes, prayer: value},
    alertMinutes: alertMinutes,
  );

  IqamaSettings withAlert(int value) =>
      IqamaSettings(minutes: minutes, alertMinutes: value);
}

/// Synchronous, so the background rescheduler can read it.
class IqamaStore {
  const IqamaStore(this._prefs);

  final SharedPreferences _prefs;

  static String minutesKey(DailyPrayer p) => 'iqama_minutes_${p.name}';
  static const String alertKey = 'iqama_alert_minutes';

  IqamaSettings read() {
    final minutes = <DailyPrayer, int>{};
    for (final p in DailyPrayer.values) {
      final v = _prefs.get(minutesKey(p));
      if (v is int && IqamaSettings.options.contains(v) && v > 0) {
        minutes[p] = v;
      }
    }
    final alert = _prefs.get(alertKey);
    return IqamaSettings(
      minutes: minutes,
      alertMinutes: alert is int && IqamaSettings.alertOptions.contains(alert)
          ? alert
          : 0,
    );
  }

  Future<void> write(IqamaSettings settings) async {
    for (final p in DailyPrayer.values) {
      final m = settings.of(p);
      if (m == 0) {
        await _prefs.remove(minutesKey(p));
      } else {
        await _prefs.setInt(minutesKey(p), m);
      }
    }
    await _prefs.setInt(alertKey, settings.alertMinutes);
  }
}

/// Iqama alert ids: 8001 + weekday * 10 + prayer (8011–8075).
int iqamaNotificationId(DateTime day, DailyPrayer prayer) =>
    8001 + day.weekday * 10 + prayer.index;

Iterable<int> allIqamaNotificationIds() sync* {
  for (var weekday = 1; weekday <= 7; weekday++) {
    for (final p in DailyPrayer.values) {
      yield 8001 + weekday * 10 + p.index;
    }
  }
}
