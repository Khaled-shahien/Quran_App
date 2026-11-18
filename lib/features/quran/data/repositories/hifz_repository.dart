import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/user_data_tables.dart';
import '../../../../core/utils/calendar_day.dart';

/// Days until the next review at each step: 1, 3, 7, 14 then 30 days.
const List<int> hifzIntervals = [1, 3, 7, 14, 30];

/// One memorised mushaf page and when it is next reviewed.
class HifzPage {
  const HifzPage({
    required this.page,
    required this.step,
    required this.due,
    this.reviews = 0,
  });

  final int page;

  /// Index into [hifzIntervals].
  final int step;
  final DateTime due;
  final int reviews;

  bool isDue(DateTime today) =>
      !due.isAfter(DateTime(today.year, today.month, today.day));

  /// After a review on [today]: remembered moves one step further apart,
  /// a stumble starts again from the first step.
  HifzPage reviewed({required bool remembered, required DateTime today}) {
    final int next = remembered
        ? (step + 1).clamp(0, hifzIntervals.length - 1)
        : 0;
    return HifzPage(
      page: page,
      step: next,
      due: DateTime(today.year, today.month, today.day + hifzIntervals[next]),
      reviews: reviews + 1,
    );
  }

  static HifzPage? fromRow(Map<String, Object?> row) {
    final page = row['page'], step = row['step'], due = row['due_day'];
    final reviews = row['reviews'];
    if (page is! int || page < 1 || page > 604) return null;
    if (step is! int || step < 0 || step >= hifzIntervals.length) return null;
    final DateTime? dueDate = due is String ? parseLogDay(due) : null;
    if (dueDate == null) return null;
    return HifzPage(
      page: page,
      step: step,
      due: dueDate,
      reviews: reviews is int && reviews >= 0 ? reviews : 0,
    );
  }
}

/// Memorised pages in the local database.
class HifzRepository implements UserDataTables {
  HifzRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Future<AppDatabase> Function() _database;
  final DateTime Function() _clock;

  static const String table = 'hifz_pages';

  Future<Database> get _db async => (await _database()).db;

  Map<String, Object?> _row(HifzPage p, {int? createdAt}) {
    final int now = _clock().millisecondsSinceEpoch;
    return {
      'page': p.page,
      'step': p.step,
      'due_day': logDay(p.due),
      'reviews': p.reviews,
      'created_at': createdAt ?? now,
      'updated_at': now,
    };
  }

  Future<List<HifzPage>> pages() async {
    final rows = await (await _db).query(table, orderBy: 'page');
    return [for (final row in rows) ?HifzPage.fromRow(row)];
  }

  /// Adds pages [from]..[to]; pages already memorised keep their schedule.
  /// The first review is tomorrow. Returns how many were new.
  Future<int> addPages(int from, int to) async {
    if (from < 1 || to > 604 || from > to) {
      throw ArgumentError('Pages must be within 1–604');
    }
    final today = _clock();
    final db = await _db;
    int added = 0;
    await db.transaction((txn) async {
      for (var page = from; page <= to; page++) {
        final id = await txn.insert(
          table,
          _row(
            HifzPage(
              page: page,
              step: 0,
              due: DateTime(today.year, today.month, today.day + 1),
            ),
          ),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (id != 0) added++;
      }
    });
    return added;
  }

  Future<void> remove(int page) async {
    await (await _db).delete(table, where: 'page = ?', whereArgs: [page]);
  }

  Future<HifzPage?> review(int page, {required bool remembered}) async {
    final db = await _db;
    final rows = await db.query(table, where: 'page = ?', whereArgs: [page]);
    final HifzPage? current = rows.isEmpty
        ? null
        : HifzPage.fromRow(rows.first);
    if (current == null) return null;
    final next = current.reviewed(remembered: remembered, today: _clock());
    await db.update(
      table,
      _row(next, createdAt: rows.first['created_at'] as int?),
      where: 'page = ?',
      whereArgs: [page],
    );
    return next;
  }

  @override
  Future<Map<String, List<Map<String, Object?>>>> exportRows() async => {
    table: await (await _db).query(table, orderBy: 'page'),
  };

  @override
  Future<int> replaceAll(Map<String, List<Map<String, Object?>>> rows) async {
    final db = await _db;
    int kept = 0;
    await db.transaction((txn) async {
      await txn.delete(table);
      for (final row in rows[table] ?? const []) {
        final page = HifzPage.fromRow(row);
        if (page == null) continue;
        final created = row['created_at'];
        await txn.insert(
          table,
          _row(page, createdAt: created is int ? created : null),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        kept++;
      }
    });
    return kept;
  }

  @override
  Future<void> clear() async {
    await (await _db).delete(table);
  }
}
