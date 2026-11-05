/// The five daily prayers, in order.
enum DailyPrayer { fajr, dhuhr, asr, maghrib, isha }

/// How the user wants to be told a prayer time has come.
enum PrayerAlertMode {
  /// The adhan recording (falls back to the alert sound until recordings
  /// are installed).
  adhan,

  /// The normal notification sound.
  sound,

  /// A notification with vibration but no sound.
  notificationOnly,

  /// Nothing at all.
  silent,
}

/// Per-prayer alert choices, the optional reminder before each prayer, and
/// the chosen muezzin.
class AdhanSettings {
  const AdhanSettings({
    this.modes = const {},
    this.reminderMinutes = 0,
    this.muezzinId = defaultMuezzin,
  });

  static const String defaultMuezzin = 'makkah';

  /// Allowed reminder offsets; 0 means no reminder.
  static const List<int> reminderOptions = [0, 5, 10, 15, 20, 30];

  /// Today's behaviour for every prayer until the user changes it.
  static const PrayerAlertMode defaultMode = PrayerAlertMode.sound;

  final Map<DailyPrayer, PrayerAlertMode> modes;
  final int reminderMinutes;
  final String muezzinId;

  PrayerAlertMode modeFor(DailyPrayer prayer) => modes[prayer] ?? defaultMode;

  bool get hasReminder => reminderMinutes > 0;

  AdhanSettings copyWith({
    Map<DailyPrayer, PrayerAlertMode>? modes,
    int? reminderMinutes,
    String? muezzinId,
  }) => AdhanSettings(
    modes: modes ?? this.modes,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    muezzinId: muezzinId ?? this.muezzinId,
  );

  AdhanSettings withMode(DailyPrayer prayer, PrayerAlertMode mode) =>
      copyWith(modes: {...modes, prayer: mode});
}
