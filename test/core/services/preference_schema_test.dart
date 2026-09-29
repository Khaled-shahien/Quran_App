import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/services/preference_schema.dart';

void main() {
  test('preference schema initializes missing version', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await PreferenceSchema.migrate(preferences);

    expect(
      preferences.getInt(PreferenceSchema.versionKey),
      PreferenceSchema.currentVersion,
    );
  });

  test('preference schema repairs malformed and old versions', () async {
    SharedPreferences.setMockInitialValues({
      PreferenceSchema.versionKey: 'invalid',
    });
    final preferences = await SharedPreferences.getInstance();

    await PreferenceSchema.migrate(preferences);

    expect(
      preferences.getInt(PreferenceSchema.versionKey),
      PreferenceSchema.currentVersion,
    );
  });

  test('preference schema preserves the current version', () async {
    SharedPreferences.setMockInitialValues({
      PreferenceSchema.versionKey: PreferenceSchema.currentVersion,
    });
    final preferences = await SharedPreferences.getInstance();

    await PreferenceSchema.migrate(preferences);

    expect(
      preferences.getInt(PreferenceSchema.versionKey),
      PreferenceSchema.currentVersion,
    );
  });
}
