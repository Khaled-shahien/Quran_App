import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';

/// A verse the user kept, with one of [colorCount] colours and an
/// optional short label.
class SavedVerse {
  const SavedVerse({
    required this.surah,
    required this.ayah,
    required this.color,
    required this.updatedAt,
    this.label,
  });

  static const int colorCount = 5;

  final int surah;
  final int ayah;
  final int color;
  final String? label;
  final DateTime updatedAt;

  Map<String, Object?> toRow(DateTime createdAt) => {
    'surah': surah,
    'ayah': ayah,
    'color': color,
    'label': label,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  static SavedVerse? fromRow(Map<String, Object?> row) {
    final surah = row['surah'], ayah = row['ayah'], color = row['color'];
    final updated = row['updated_at'], label = row['label'];
    if (surah is! int || ayah is! int || color is! int || updated is! int) {
      return null;
    }
    return SavedVerse(
      surah: surah,
      ayah: ayah,
      color: color.clamp(0, colorCount - 1),
      label: label is String && label.trim().isNotEmpty ? label.trim() : null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updated),
    );
  }
}

/// A private note on one verse. Notes never leave the device unless the
/// user exports them.
class VerseNote {
  const VerseNote({
    required this.surah,
    required this.ayah,
    required this.body,
    required this.updatedAt,
  });

  static const int maxLength = 4000;

  final int surah;
  final int ayah;
  final String body;
  final DateTime updatedAt;

  static VerseNote? fromRow(Map<String, Object?> row) {
    final surah = row['surah'], ayah = row['ayah'], body = row['body'];
    final updated = row['updated_at'];
    if (surah is! int || ayah is! int || body is! String || updated is! int) {
      return null;
    }
    return VerseNote(
      surah: surah,
      ayah: ayah,
      body: body,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updated),
    );
  }
}

bool _validVerse(int surah, int ayah) =>
    surah >= 1 && surah <= 114 && ayah >= 1 && ayah <= 286;

/// Saved verses and notes in the local database.
class VerseLibraryRepository {
  VerseLibraryRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Future<AppDatabase> Function() _database;
  final DateTime Function() _clock;

  Future<Database> get _db async => (await _database()).db;

  Future<List<SavedVerse>> savedVerses() async {
    final rows = await (await _db).query(
      'saved_verses',
      orderBy: 'updated_at DESC',
    );
    return [for (final row in rows) ?SavedVerse.fromRow(row)];
  }

  Future<void> saveVerse(
    int surah,
    int ayah, {
    required int color,
    String? label,
  }) async {
    if (!_validVerse(surah, ayah)) throw ArgumentError('Invalid verse');
    final Database db = await _db;
    final DateTime now = _clock();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'saved_verses',
        columns: ['created_at'],
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah],
      );
      final Object? created = existing.isEmpty
          ? null
          : existing.first['created_at'];
      await txn.insert(
        'saved_verses',
        SavedVerse(
          surah: surah,
          ayah: ayah,
          color: color.clamp(0, SavedVerse.colorCount - 1),
          label: label,
          updatedAt: now,
        ).toRow(
          created is int ? DateTime.fromMillisecondsSinceEpoch(created) : now,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> removeVerse(int surah, int ayah) async {
    await (await _db).delete(
      'saved_verses',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
    );
  }

  Future<List<VerseNote>> notes() async {
    final rows = await (await _db).query(
      'verse_notes',
      orderBy: 'updated_at DESC',
    );
    return [for (final row in rows) ?VerseNote.fromRow(row)];
  }

  /// Saves [body] as the note of the verse; an empty body deletes it.
  Future<void> saveNote(int surah, int ayah, String body) async {
    if (!_validVerse(surah, ayah)) throw ArgumentError('Invalid verse');
    final String text = body.trim();
    final Database db = await _db;
    if (text.isEmpty) {
      await db.delete(
        'verse_notes',
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah],
      );
      return;
    }
    final String kept = text.length > VerseNote.maxLength
        ? text.substring(0, VerseNote.maxLength)
        : text;
    final int now = _clock().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'verse_notes',
        {'body': kept, 'updated_at': now},
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah],
      );
      if (updated == 0) {
        await txn.insert('verse_notes', {
          'surah': surah,
          'ayah': ayah,
          'body': kept,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  /// Every row of both tables, for export.
  Future<Map<String, List<Map<String, Object?>>>> exportRows() async {
    final Database db = await _db;
    return {
      'saved_verses': await db.query('saved_verses'),
      'verse_notes': await db.query('verse_notes'),
    };
  }

  /// Replaces both tables in one transaction (import). Invalid rows are
  /// skipped; the count of rows kept is returned.
  Future<int> replaceAll(Map<String, List<Map<String, Object?>>> rows) async {
    final Database db = await _db;
    int kept = 0;
    await db.transaction((txn) async {
      await txn.delete('saved_verses');
      await txn.delete('verse_notes');
      for (final row in rows['saved_verses'] ?? const []) {
        final verse = SavedVerse.fromRow(row);
        final created = row['created_at'];
        if (verse == null || !_validVerse(verse.surah, verse.ayah)) continue;
        await txn.insert(
          'saved_verses',
          verse.toRow(
            created is int
                ? DateTime.fromMillisecondsSinceEpoch(created)
                : verse.updatedAt,
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        kept++;
      }
      for (final row in rows['verse_notes'] ?? const []) {
        final note = VerseNote.fromRow(row);
        final created = row['created_at'];
        if (note == null ||
            !_validVerse(note.surah, note.ayah) ||
            note.body.trim().isEmpty) {
          continue;
        }
        await txn.insert('verse_notes', {
          'surah': note.surah,
          'ayah': note.ayah,
          'body': note.body.length > VerseNote.maxLength
              ? note.body.substring(0, VerseNote.maxLength)
              : note.body,
          'created_at': created is int
              ? created
              : note.updatedAt.millisecondsSinceEpoch,
          'updated_at': note.updatedAt.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        kept++;
      }
    });
    return kept;
  }

  Future<void> clear() async {
    final Database db = await _db;
    await db.transaction((txn) async {
      await txn.delete('saved_verses');
      await txn.delete('verse_notes');
    });
  }
}
