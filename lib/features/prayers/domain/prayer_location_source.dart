/// Where the active prayer location came from. Exactly one is active, and
/// only an explicit user choice switches between them: a device lookup never
/// replaces a city the user picked, and picking a city stops device updates.
enum PrayerLocationSource {
  /// The phone's position. Refreshed when the app opens after
  /// [LocationQuality.deviceLocationRefreshAge], only with permission
  /// already granted and never with a dialog.
  device,

  /// A listed city or typed coordinates. Never changed automatically.
  manual;

  static const String preferenceKey = 'prayer_location_source';

  /// When the device fix behind a [device] location was measured (ms since
  /// epoch), and its reported accuracy in metres.
  static const String fixedAtKey = 'prayer_location_fixed_at_ms';
  static const String accuracyKey = 'prayer_location_accuracy_m';

  /// Installs from before this setting stored no source. Their GPS
  /// locations carried the "device location" label; anything else was
  /// chosen by hand.
  static PrayerLocationSource fromStorage(
    Object? value, {
    required bool legacyDeviceLabel,
  }) => switch (value) {
    'device' => device,
    'manual' => manual,
    _ => legacyDeviceLabel ? device : manual,
  };
}
