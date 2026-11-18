import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/database/app_database.dart';
import 'package:sakina_app/features/quran/data/repositories/hifz_repository.dart';
import 'package:sakina_app/features/quran/presentation/screens/hifz_screens.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late DateTime now;
  late HifzRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    now = DateTime(2026, 11, 18, 9);
    repository = HifzRepository(() async => database, clock: () => now);
  });

  tearDown(() => database.db.close());

  test('the schedule spreads out on success and restarts on a stumble', () {
    var page = HifzPage(page: 1, step: 0, due: DateTime(2026, 11, 18));
    final today = DateTime(2026, 11, 18);
    final steps = <int>[];
    for (var i = 0; i < 6; i++) {
      page = page.reviewed(remembered: true, today: today);
      steps.add(page.due.difference(today).inDays);
    }
    expect(steps, [3, 7, 14, 30, 30, 30]);
    page = page.reviewed(remembered: false, today: today);
    expect(page.step, 0);
    expect(page.due, DateTime(2026, 11, 19));
    expect(page.reviews, 7);
  });

  test(
    'added pages are due tomorrow; existing ones keep their schedule',
    () async {
      expect(await repository.addPages(1, 3), 3);
      await repository.review(2, remembered: true);
      expect(await repository.addPages(2, 4), 1);
      final pages = await repository.pages();
      expect(pages.map((p) => p.page), [1, 2, 3, 4]);
      expect(pages[0].due, DateTime(2026, 11, 19));
      expect(pages[1].due, DateTime(2026, 11, 21));
      expect(pages[0].isDue(DateTime(2026, 11, 18)), isFalse);
      expect(pages[0].isDue(DateTime(2026, 11, 19, 23)), isTrue);
      expect(() => repository.addPages(0, 3), throwsArgumentError);
    },
  );

  test('export and import keep the schedule; bad rows are skipped', () async {
    await repository.addPages(10, 11);
    final rows = await repository.exportRows();
    await repository.clear();
    expect(await repository.pages(), isEmpty);
    final kept = await repository.replaceAll({
      'hifz_pages': [
        ...rows['hifz_pages']!,
        {'page': 999, 'step': 0, 'due_day': '2026-11-19'},
        {'page': 5, 'step': 9, 'due_day': '2026-11-19'},
      ],
    });
    expect(kept, 2);
    expect((await repository.pages()).map((p) => p.page), [10, 11]);
  });

  testWidgets('a review hides each ayah until tapped and reports the result', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const HifzReviewScreen(
                    page: 1,
                    ayahs: [
                      (surah: 1, ayah: 1, text: 'أ', surahName: 'س'),
                      (surah: 1, ayah: 2, text: 'ب', surahName: 'س'),
                    ],
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('أ '), findsNothing);
    await tester.tap(find.byKey(const Key('hifz-ayah-0')));
    await tester.pump();
    expect(find.textContaining('أ '), findsOneWidget);
    expect(find.byKey(const Key('hifz-ayah-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hifz-remembered')));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  test('every mushaf page has its ayahs, basmala split off', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final pages = await loadMushafPages();
    expect(pages.keys.length, 604);
    expect(pages[1]!.first, (
      surah: 1,
      ayah: 1,
      text: pages[1]!.first.text,
      surahName: pages[1]!.first.surahName,
    ));
    final baqarah = pages[2]!.first;
    expect(baqarah.surah, 2);
    expect(baqarah.text.startsWith('بِسْمِ'), isFalse);
  });
}
