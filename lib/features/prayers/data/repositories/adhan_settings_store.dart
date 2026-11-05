import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/adhan_settings.dart';

/// Reads and writes [AdhanSettings]. Synchronous reads work in the
/// background isolate that reschedules alarms after reboot.
class AdhanSettingsStore {
  const AdhanSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static String modeKey(DailyPrayer p) => 'adhan_mode_${p.name}';
  static const String reminderKey = 'adhan_reminder_minutes';
  static const String muezzinKey = 'adhan_muezzin';

  /// Invalid stored values fall back to defaults instead of failing.
  AdhanSettings read() {
    final modes = <DailyPrayer, PrayerAlertMode>{};
    for (final prayer in DailyPrayer.values) {
      final stored = _prefs.get(modeKey(prayer));
      final mode = PrayerAlertMode.values.where((m) => m.name == stored);
      if (mode.isNotEmpty) modes[prayer] = mode.first;
    }
    final reminder = _prefs.get(reminderKey);
    final muezzin = _prefs.get(muezzinKey);
    return AdhanSettings(
      modes: modes,
      reminderMinutes:
          reminder is int && AdhanSettings.reminderOptions.contains(reminder)
          ? reminder
          : 0,
      muezzinId: muezzin is String && muezzin.isNotEmpty
          ? muezzin
          : AdhanSettings.defaultMuezzin,
    );
  }

  Future<void> write(AdhanSettings settings) async {
    for (final prayer in DailyPrayer.values) {
      await _prefs.setString(modeKey(prayer), settings.modeFor(prayer).name);
    }
    await _prefs.setInt(reminderKey, settings.reminderMinutes);
    await _prefs.setString(muezzinKey, settings.muezzinId);
  }
}
