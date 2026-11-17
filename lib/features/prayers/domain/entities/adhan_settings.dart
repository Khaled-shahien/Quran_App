/// The five daily prayers, in order.
enum DailyPrayer { fajr, dhuhr, asr, maghrib, isha }

/// How the user wants to be told a prayer time has come.
enum PrayerAlertMode {
  /// The adhan recording chosen for that prayer (Android). Where the
  /// platform cannot play a full adhan in a notification, the alert sound.
  adhan,

  /// The normal notification sound.
  sound,

  /// A notification with vibration but no sound.
  notificationOnly,

  /// Nothing at all.
  silent,
}

/// Per-prayer alert choices, the optional reminder before each prayer, and
/// the adhan recording chosen for each prayer.
class AdhanSettings {
  const AdhanSettings({
    this.modes = const {},
    this.reminderMinutes = 0,
    this.voices = const {},
  });

  /// Allowed reminder offsets; 0 means no reminder.
  static const List<int> reminderOptions = [0, 5, 10, 15, 20, 30];

  /// Today's behaviour for every prayer until the user changes it.
  static const PrayerAlertMode defaultMode = PrayerAlertMode.sound;

  final Map<DailyPrayer, PrayerAlertMode> modes;
  final int reminderMinutes;

  /// Chosen recording id per prayer; see `AdhanVoices.resolve` for the
  /// recording actually used when an id is missing or not valid.
  final Map<DailyPrayer, String> voices;

  PrayerAlertMode modeFor(DailyPrayer prayer) => modes[prayer] ?? defaultMode;

  bool get hasReminder => reminderMinutes > 0;

  AdhanSettings copyWith({
    Map<DailyPrayer, PrayerAlertMode>? modes,
    int? reminderMinutes,
    Map<DailyPrayer, String>? voices,
  }) => AdhanSettings(
    modes: modes ?? this.modes,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    voices: voices ?? this.voices,
  );

  AdhanSettings withMode(DailyPrayer prayer, PrayerAlertMode mode) =>
      copyWith(modes: {...modes, prayer: mode});

  AdhanSettings withVoice(DailyPrayer prayer, String voiceId) =>
      copyWith(voices: {...voices, prayer: voiceId});
}
