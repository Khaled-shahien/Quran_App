import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/core/database/migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Set<String>> tables(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    return {for (final r in rows) r['name']! as String};
  }

  test('a fresh install gets every table at the current version', () async {
    final AppDatabase database = await AppDatabase.open(
      factory: factory,
      path: inMemoryDatabasePath,
    );
    addTearDown(database.close);

    expect(await database.db.getVersion(), AppDatabase.schemaVersion);
    expect(
      await tables(database.db),
      containsAll(<String>['saved_verses', 'verse_notes']),
    );
  });

  test('schema version equals the number of migrations', () {
    expect(AppDatabase.schemaVersion, databaseMigrations.length);
    expect(AppDatabase.schemaVersion, greaterThanOrEqualTo(1));
  });

  test('every migration step applies on top of the previous one', () async {
    final Database db = await factory.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    for (int step = 0; step < databaseMigrations.length; step++) {
      await AppDatabase.migrate(db, from: step, to: step + 1);
    }
    expect(
      await tables(db),
      containsAll(<String>['saved_verses', 'verse_notes']),
    );
  });

  test('a newer database is opened without losing its data', () async {
    final String path =
        '${(await factory.getDatabasesPath())}/downgrade_test.db';
    await factory.deleteDatabase(path);
    addTearDown(() => factory.deleteDatabase(path));

    // A later build wrote schema version + 1 with an extra table.
    final Database newer = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppDatabase.schemaVersion + 1,
        onCreate: (db, version) async {
          await AppDatabase.migrate(db, from: 0, to: AppDatabase.schemaVersion);
          await db.execute('CREATE TABLE future_feature (x INTEGER)');
          await db.insert('saved_verses', {
            'surah': 2,
            'ayah': 255,
            'color': 1,
            'created_at': 1,
            'updated_at': 1,
          });
        },
      ),
    );
    await newer.close();

    final AppDatabase older = await AppDatabase.open(
      factory: factory,
      path: path,
    );
    addTearDown(older.close);
    final rows = await older.db.query('saved_verses');
    expect(rows, hasLength(1));
    expect(await tables(older.db), contains('future_feature'));
  });

  test('constraints reject impossible verse references', () async {
    final AppDatabase database = await AppDatabase.open(
      factory: factory,
      path: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    expect(
      () => database.db.insert('saved_verses', {
        'surah': 115,
        'ayah': 1,
        'created_at': 0,
        'updated_at': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
    expect(
      () => database.db.insert('verse_notes', {
        'surah': 1,
        'ayah': 0,
        'body': 'x',
        'created_at': 0,
        'updated_at': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
