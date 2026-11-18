import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/user_data_tables.dart';
import '../../../core/utils/calendar_day.dart';

export '../../../core/utils/calendar_day.dart';
import '../../prayers/domain/entities/adhan_settings.dart';

/// How a prayer went, as the user marks it. Nothing is inferred.
enum PrayerLogStatus { onTime, late, missed, excused }

/// A day of fasting: kept (Ramadan or voluntary), a make-up fast, not
/// fasted for a valid excuse, or not fasted.
enum FastLogStatus { fasted, qada, excused, missed }

T? _byName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

/// The private prayer and fasting log. It stays on the device; it is only
/// in an export file the user makes.
class PracticeLogRepository implements UserDataTables {
  PracticeLogRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Future<AppDatabase> Function() _database;
  final DateTime Function() _clock;

  static const String prayerTable = 'prayer_log';
  static const String fastingTable = 'fasting_log';

  Future<Database> get _db async => (await _database()).db;

  /// Each logged prayer on days [from]..[to] (inclusive), by day.
  Future<Map<String, Map<DailyPrayer, PrayerLogStatus>>> prayers(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await (await _db).query(
      prayerTable,
      where: 'day BETWEEN ? AND ?',
      whereArgs: [logDay(from), logDay(to)],
    );
    final out = <String, Map<DailyPrayer, PrayerLogStatus>>{};
    for (final row in rows) {
      final prayer = _byName(DailyPrayer.values, row['prayer']);
      final status = _byName(PrayerLogStatus.values, row['status']);
      final day = row['day'];
      if (prayer == null || status == null || day is! String) continue;
      (out[day] ??= {})[prayer] = status;
    }
    return out;
  }

  /// Marks [prayer] on [day]; null clears it.
  Future<void> setPrayer(
    DateTime day,
    DailyPrayer prayer,
    PrayerLogStatus? status,
  ) async {
    final db = await _db;
    if (status == null) {
      await db.delete(
        prayerTable,
        where: 'day = ? AND prayer = ?',
        whereArgs: [logDay(day), prayer.name],
      );
      return;
    }
    await db.insert(prayerTable, {
      'day': logDay(day),
      'prayer': prayer.name,
      'status': status.name,
      'updated_at': _clock().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, FastLogStatus>> fasts(DateTime from, DateTime to) async {
    final rows = await (await _db).query(
      fastingTable,
      where: 'day BETWEEN ? AND ?',
      whereArgs: [logDay(from), logDay(to)],
    );
    return {
      for (final row in rows)
        if (row['day'] is String &&
            _byName(FastLogStatus.values, row['status']) != null)
          row['day']! as String: _byName(FastLogStatus.values, row['status'])!,
    };
  }

  /// Every fast logged, for the make-up count.
  Future<Map<String, FastLogStatus>> allFasts() async {
    final rows = await (await _db).query(fastingTable);
    return {
      for (final row in rows)
        if (row['day'] is String &&
            _byName(FastLogStatus.values, row['status']) != null)
          row['day']! as String: _byName(FastLogStatus.values, row['status'])!,
    };
  }

  Future<void> setFast(DateTime day, FastLogStatus? status) async {
    final db = await _db;
    if (status == null) {
      await db.delete(fastingTable, where: 'day = ?', whereArgs: [logDay(day)]);
      return;
    }
    await db.insert(fastingTable, {
      'day': logDay(day),
      'status': status.name,
      'updated_at': _clock().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<Map<String, List<Map<String, Object?>>>> exportRows() async {
    final db = await _db;
    return {
      prayerTable: await db.query(prayerTable, orderBy: 'day, prayer'),
      fastingTable: await db.query(fastingTable, orderBy: 'day'),
    };
  }

  @override
  Future<int> replaceAll(Map<String, List<Map<String, Object?>>> rows) async {
    final db = await _db;
    int kept = 0;
    await db.transaction((txn) async {
      await txn.delete(prayerTable);
      await txn.delete(fastingTable);
      for (final row in rows[prayerTable] ?? const []) {
        final day = row['day'], updated = row['updated_at'];
        if (day is! String ||
            parseLogDay(day) == null ||
            _byName(DailyPrayer.values, row['prayer']) == null ||
            _byName(PrayerLogStatus.values, row['status']) == null) {
          continue;
        }
        await txn.insert(prayerTable, {
          'day': day,
          'prayer': row['prayer'],
          'status': row['status'],
          'updated_at': updated is int ? updated : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        kept++;
      }
      for (final row in rows[fastingTable] ?? const []) {
        final day = row['day'], updated = row['updated_at'];
        if (day is! String ||
            parseLogDay(day) == null ||
            _byName(FastLogStatus.values, row['status']) == null) {
          continue;
        }
        await txn.insert(fastingTable, {
          'day': day,
          'status': row['status'],
          'updated_at': updated is int ? updated : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        kept++;
      }
    });
    return kept;
  }

  @override
  Future<void> clear() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(prayerTable);
      await txn.delete(fastingTable);
    });
  }
}
