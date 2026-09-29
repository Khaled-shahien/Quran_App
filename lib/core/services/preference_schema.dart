import 'package:shared_preferences/shared_preferences.dart';

/// Versioned migration boundary for local application preferences.
class PreferenceSchema {
  PreferenceSchema._();

  static const String versionKey = 'preferences_schema_version';
  static const int currentVersion = 1;

  static Future<void> migrate(SharedPreferences preferences) async {
    final storedVersion = preferences.get(versionKey);
    final version = storedVersion is int && storedVersion >= 0
        ? storedVersion
        : 0;

    if (version < currentVersion) {
      await preferences.setInt(versionKey, currentVersion);
    } else if (storedVersion != version) {
      await preferences.setInt(versionKey, version);
    }
  }
}
