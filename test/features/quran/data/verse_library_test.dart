import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/features/quran/data/repositories/verse_library_repository.dart';
import 'package:sakina_app/features/quran/presentation/providers/verse_library_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late VerseLibraryRepository repository;
  var now = DateTime(2026, 11, 18, 9);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    now = DateTime(2026, 11, 18, 9);
    repository = VerseLibraryRepository(() async => database, clock: () => now);
  });
  tearDown(() => database.close());

  test('saving again updates colour and label, keeping one row', () async {
    await repository.saveVerse(2, 255, color: 1, label: 'الكرسي');
    now = now.add(const Duration(minutes: 5));
    await repository.saveVerse(2, 255, color: 3, label: '  ');

    final saved = await repository.savedVerses();
    expect(saved, hasLength(1));
    expect(saved.single.color, 3);
    expect(saved.single.label, isNull, reason: 'blank label is no label');
    final rows = await database.db.query('saved_verses');
    expect(
      rows.single['created_at'],
      DateTime(2026, 11, 18, 9).millisecondsSinceEpoch,
    );
  });

  test('impossible verses are refused and colours are clamped', () async {
    expect(() => repository.saveVerse(115, 1, color: 0), throwsArgumentError);
    expect(() => repository.saveNote(1, 0, 'x'), throwsArgumentError);
    await repository.saveVerse(1, 1, color: 99);
    expect((await repository.savedVerses()).single.color, 4);
  });

  test('an empty note deletes it; long notes are cut', () async {
    await repository.saveNote(18, 10, 'دعاء الفتية');
    expect((await repository.notes()).single.body, 'دعاء الفتية');
    await repository.saveNote(18, 10, '   ');
    expect(await repository.notes(), isEmpty);
    await repository.saveNote(1, 1, 'a' * (VerseNote.maxLength + 50));
    expect((await repository.notes()).single.body.length, VerseNote.maxLength);
  });

  test('replaceAll keeps valid rows only, in one transaction', () async {
    await repository.saveVerse(1, 1, color: 0);
    final kept = await repository.replaceAll({
      'saved_verses': [
        {'surah': 2, 'ayah': 255, 'color': 2, 'updated_at': 5},
        {'surah': 200, 'ayah': 1, 'color': 2, 'updated_at': 5},
        {'surah': 'x'},
      ],
      'verse_notes': [
        {'surah': 3, 'ayah': 8, 'body': 'ربنا لا تزغ', 'updated_at': 7},
        {'surah': 3, 'ayah': 9, 'body': ' ', 'updated_at': 7},
      ],
    });
    expect(kept, 2);
    expect((await repository.savedVerses()).single.ayah, 255);
    expect((await repository.notes()).single.ayah, 8);
  });

  test('the controller loads lazily and reflects writes', () async {
    final controller = VerseLibraryController(repository);
    addTearDown(controller.dispose);
    expect(controller.loaded, isFalse);
    await controller.ensureLoaded();
    expect(controller.loaded, isTrue);

    expect(await controller.saveVerse(36, 1, color: 2), isTrue);
    expect(controller.savedAt(36, 1)?.color, 2);
    expect(await controller.saveNote(36, 1, 'يس'), isTrue);
    expect(controller.noteAt(36, 1)?.body, 'يس');
    expect(await controller.removeVerse(36, 1), isTrue);
    expect(controller.savedAt(36, 1), isNull);
  });

  test('a failing database is reported, not thrown', () async {
    final controller = VerseLibraryController(
      VerseLibraryRepository(() async => throw StateError('no database')),
    );
    addTearDown(controller.dispose);
    await controller.ensureLoaded();
    expect(controller.failed, isTrue);
    expect(await controller.saveVerse(1, 1, color: 0), isFalse);
  });
}
