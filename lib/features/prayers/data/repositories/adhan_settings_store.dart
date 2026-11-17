import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/adhan_settings.dart';

/// Reads and writes [AdhanSettings]. Synchronous reads work in the
/// background isolate that reschedules alarms after reboot.
class AdhanSettingsStore {
  const AdhanSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static String modeKey(DailyPrayer p) => 'adhan_mode_${p.name}';
  static const String reminderKey = 'adhan_reminder_minutes';
  static String voiceKey(DailyPrayer p) => 'adhan_voice_${p.name}';

  /// Invalid stored values fall back to defaults instead of failing.
  AdhanSettings read() {
    final modes = <DailyPrayer, PrayerAlertMode>{};
    for (final prayer in DailyPrayer.values) {
      final stored = _prefs.get(modeKey(prayer));
      final mode = PrayerAlertMode.values.where((m) => m.name == stored);
      if (mode.isNotEmpty) modes[prayer] = mode.first;
    }
    final voices = <DailyPrayer, String>{};
    for (final prayer in DailyPrayer.values) {
      final stored = _prefs.get(voiceKey(prayer));
      if (stored is String && stored.isNotEmpty) voices[prayer] = stored;
    }
    final reminder = _prefs.get(reminderKey);
    return AdhanSettings(
      modes: modes,
      reminderMinutes:
          reminder is int && AdhanSettings.reminderOptions.contains(reminder)
          ? reminder
          : 0,
      voices: voices,
    );
  }

  Future<void> write(AdhanSettings settings) async {
    for (final prayer in DailyPrayer.values) {
      await _prefs.setString(modeKey(prayer), settings.modeFor(prayer).name);
    }
    await _prefs.setInt(reminderKey, settings.reminderMinutes);
    for (final MapEntry(key: prayer, value: id) in settings.voices.entries) {
      await _prefs.setString(voiceKey(prayer), id);
    }
  }
}
