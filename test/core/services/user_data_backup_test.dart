import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/services/user_data_backup.dart';
import 'package:sakina_app/features/quran/data/repositories/verse_library_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late VerseLibraryRepository library;
  late SharedPreferences prefs;
  late UserDataBackup backup;

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    library = VerseLibraryRepository(() async => database);
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'prayer_latitude': 30.0,
      'prayer_method': 5,
      'prayer_notifications_enabled': true,
      'adhan_mode_fajr': 'adhan',
      'adhkar_progress_v1_1': '{"0":3}',
      // Device state: never exported.
      'diagnostics_log_v1': '[]',
      'onboarding_complete': true,
      'monitoring_enabled': true,
      'notification_scheduling_generation': 7,
    });
    prefs = await SharedPreferences.getInstance();
    backup = UserDataBackup(
      prefs: prefs,
      library: library,
      clock: () => DateTime.utc(2026, 11, 18, 8),
    );
    await library.saveVerse(2, 255, color: 1, label: 'الكرسي');
    await library.saveNote(1, 1, 'الحمد لله');
  });
  tearDown(() => database.close());

  test('export carries user data and nothing of the device state', () async {
    final Map<String, dynamic> file =
        jsonDecode(await backup.export()) as Map<String, dynamic>;
    expect(file['format'], 'sakina-backup');
    final Map<String, dynamic> p = file['preferences'] as Map<String, dynamic>;
    expect(p['theme_mode'], 'dark');
    expect(p['prayer_latitude'], 30.0);
    expect(p['adhan_mode_fajr'], 'adhan');
    expect(p['adhkar_progress_v1_1'], '{"0":3}');
    for (final key in [
      'diagnostics_log_v1',
      'onboarding_complete',
      'monitoring_enabled',
      'notification_scheduling_generation',
    ]) {
      expect(p.containsKey(key), isFalse, reason: key);
    }
    final db = file['database'] as Map<String, dynamic>;
    expect(db['saved_verses'], hasLength(1));
    expect(db['verse_notes'], hasLength(1));
  });

  test('a round trip restores everything, types included', () async {
    final String exported = await backup.export();
    await prefs.setString('theme_mode', 'light');
    await prefs.setDouble('prayer_latitude', 21.4);
    await prefs.setString('reading_last_ayah_2', '9');
    await library.clear();

    final summary = backup.inspect(exported);
    expect(summary.savedVerses, 1);
    expect(summary.notes, 1);
    await backup.restore(exported);

    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getDouble('prayer_latitude'), 30.0);
    expect(prefs.getInt('prayer_method'), 5);
    expect(prefs.getBool('prayer_notifications_enabled'), isTrue);
    expect(
      prefs.containsKey('reading_last_ayah_2'),
      isFalse,
      reason: 'not in the backup, so removed',
    );
    expect(prefs.getBool('onboarding_complete'), isTrue, reason: 'untouched');
    expect((await library.savedVerses()).single.label, 'الكرسي');
    expect((await library.notes()).single.body, 'الحمد لله');
  });

  test('foreign, damaged or newer files change nothing', () async {
    for (final raw in [
      'not json',
      '{"format":"other"}',
      jsonEncode({'format': 'sakina-backup', 'version': 99}),
    ]) {
      expect(() => backup.inspect(raw), throwsA(isA<BackupFormatException>()));
      await expectLater(
        backup.restore(raw),
        throwsA(isA<BackupFormatException>()),
      );
    }
    expect(prefs.getString('theme_mode'), 'dark');
    expect(await library.savedVerses(), hasLength(1));
  });

  test('unknown keys in a backup are ignored', () async {
    await backup.restore(
      jsonEncode({
        'format': 'sakina-backup',
        'version': 1,
        'preferences': {'theme_mode': 'light', 'monitoring_enabled': false},
        'database': {},
      }),
    );
    expect(prefs.getString('theme_mode'), 'light');
    expect(prefs.getBool('monitoring_enabled'), isTrue);
  });

  test('erase removes user data and keeps device state', () async {
    await backup.erase();
    expect(prefs.containsKey('theme_mode'), isFalse);
    expect(prefs.containsKey('adhkar_progress_v1_1'), isFalse);
    expect(prefs.getBool('onboarding_complete'), isTrue);
    expect(await library.savedVerses(), isEmpty);
    expect(await library.notes(), isEmpty);
  });
}
