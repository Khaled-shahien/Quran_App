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

  test(
    'steps run once each, in order, saving the version after each',
    () async {
      SharedPreferences.setMockInitialValues({PreferenceSchema.versionKey: 1});
      final preferences = await SharedPreferences.getInstance();
      final List<int> ran = [];
      Future<void> step(SharedPreferences p, int n) async {
        ran.add(n);
        expect(p.getInt(PreferenceSchema.versionKey), n);
      }

      final steps = <PreferenceMigrationStep>[
        (p) => step(p, 1),
        (p) => step(p, 2),
      ];
      await PreferenceSchema.migrate(preferences, steps: steps);
      await PreferenceSchema.migrate(preferences, steps: steps);

      expect(ran, [1, 2]);
      expect(preferences.getInt(PreferenceSchema.versionKey), 3);
    },
  );

  test('an interrupted upgrade resumes at the failed step', () async {
    SharedPreferences.setMockInitialValues({PreferenceSchema.versionKey: 1});
    final preferences = await SharedPreferences.getInstance();
    bool fail = true;
    final List<int> ran = [];
    final steps = <PreferenceMigrationStep>[
      (p) async => ran.add(1),
      (p) async {
        if (fail) throw StateError('killed');
        ran.add(2);
      },
    ];
    await expectLater(
      PreferenceSchema.migrate(preferences, steps: steps),
      throwsStateError,
    );
    expect(preferences.getInt(PreferenceSchema.versionKey), 2);
    fail = false;
    await PreferenceSchema.migrate(preferences, steps: steps);
    expect(ran, [1, 2]);
    expect(preferences.getInt(PreferenceSchema.versionKey), 3);
  });

  test('preferences from a newer build are left untouched', () async {
    SharedPreferences.setMockInitialValues({
      PreferenceSchema.versionKey: PreferenceSchema.currentVersion + 5,
    });
    final preferences = await SharedPreferences.getInstance();

    await PreferenceSchema.migrate(preferences);

    expect(
      preferences.getInt(PreferenceSchema.versionKey),
      PreferenceSchema.currentVersion + 5,
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
