import 'dart:developer' as developer;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

/// The app's local SQLite database for user data that grows over time
/// (saved verses, notes). Simple settings stay in SharedPreferences.
///
/// The schema is versioned through `PRAGMA user_version`. Every change is a
/// new entry in [databaseMigrations]; existing migrations are never edited,
/// so any older install upgrades step by step. Data is never dropped: a
/// database newer than this build (after a downgrade) is opened as it is.
class AppDatabase {
  AppDatabase._(this.db);

  /// The open connection. Repositories use it; nothing else should.
  final Database db;

  static const String fileName = 'sakina.db';

  /// The schema this build writes: the number of migrations.
  static int get schemaVersion => databaseMigrations.length;

  /// Opens (creating or upgrading) the database at [path], by default the
  /// platform database directory. Tests pass an ffi [factory] and
  /// [inMemoryDatabasePath].
  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async => AppDatabase._(
    await _openFile(factory, path, fileName, databaseMigrations),
  );

  static Future<Database> _openFile(
    DatabaseFactory? factory,
    String? path,
    String name,
    List<List<String>> migrations,
  ) async {
    final DatabaseFactory f = factory ?? databaseFactory;
    final String location = path ?? p.join(await f.getDatabasesPath(), name);
    final int schemaVersion = migrations.length;
    return f.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) =>
            migrate(db, from: 0, to: version, migrations: migrations),
        onUpgrade: (db, from, to) =>
            migrate(db, from: from, to: to, migrations: migrations),
        // A newer schema came from a later build. Keep it and its data;
        // added tables and columns are ignored by this build.
        onDowngrade: (db, from, to) async {
          developer.log(
            'Database schema $from is newer than this build ($to)',
            name: 'sakina_app.database',
          );
        },
      ),
    );
  }

  /// Applies migrations `from`..`to` in one transaction each, in order.
  static Future<void> migrate(
    DatabaseExecutor db, {
    required int from,
    required int to,
    List<List<String>> migrations = databaseMigrations,
  }) async {
    for (int step = from; step < to; step++) {
      final List<String> statements = migrations[step];
      if (db is Database) {
        await db.transaction((txn) async {
          for (final String sql in statements) {
            await txn.execute(sql);
          }
        });
      } else {
        for (final String sql in statements) {
          await db.execute(sql);
        }
      }
    }
  }

  Future<void> close() => db.close();
}

/// A second database for sensitive records (the prayer and fasting log).
/// It is a separate file so Android cloud backup can leave it out
/// (privacy rule PV-3); it travels only in the user's own export file.
class PrivateDatabase extends AppDatabase {
  PrivateDatabase._(super.db) : super._();

  static const String fileName = 'sakina_private.db';

  static int get schemaVersion => privateDatabaseMigrations.length;

  static Future<PrivateDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async => PrivateDatabase._(
    await AppDatabase._openFile(
      factory,
      path,
      fileName,
      privateDatabaseMigrations,
    ),
  );

  /// Moves the log rows that earlier builds kept in [main] into this
  /// database, once; rows already here win. The main tables stay (never dropped)
  /// but end empty.
  Future<void> adoptLegacyLog(AppDatabase main) async {
    for (final String table in const ['prayer_log', 'fasting_log']) {
      final rows = await main.db.query(table);
      if (rows.isEmpty) continue;
      await db.transaction((txn) async {
        for (final row in rows) {
          await txn.insert(
            table,
            row,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });
      await main.db.delete(table);
    }
  }
}
