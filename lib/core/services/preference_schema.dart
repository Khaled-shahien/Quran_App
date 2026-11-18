import 'package:shared_preferences/shared_preferences.dart';

/// One upgrade of the stored preferences from version `n` to `n + 1`.
typedef PreferenceMigrationStep = Future<void> Function(SharedPreferences);

/// Versioned migration boundary for local application preferences.
///
/// Version 1 is the layout every release up to and including `1.0.0+3`
/// wrote (see `test/core/upgrade/upgrade_from_1_0_0_3_test.dart`). A change
/// to a stored format adds a step to [steps]; existing steps are never
/// edited. Steps run in order, each at most once, and the version is saved
/// after each step, so an interrupted upgrade resumes where it stopped.
/// Preferences written by a newer build are left untouched.
class PreferenceSchema {
  PreferenceSchema._();

  static const String versionKey = 'preferences_schema_version';

  /// Upgrades from version 1 (index 0 upgrades 1 → 2, and so on).
  static const List<PreferenceMigrationStep> steps =
      <PreferenceMigrationStep>[];

  static int get currentVersion => 1 + steps.length;

  static Future<void> migrate(
    SharedPreferences preferences, {
    List<PreferenceMigrationStep> steps = PreferenceSchema.steps,
  }) async {
    final int target = 1 + steps.length;
    final Object? stored = preferences.get(versionKey);
    // Missing or malformed: an install from before versioning, i.e. v1.
    int version = stored is int && stored >= 1 ? stored : 1;

    if (version > target) {
      // Written by a newer build after a downgrade: keep its data as is.
      return;
    }
    while (version < target) {
      await steps[version - 1](preferences);
      version++;
      await preferences.setInt(versionKey, version);
    }
    if (stored != version) await preferences.setInt(versionKey, version);
  }
}
