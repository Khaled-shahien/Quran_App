import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:sakina_app/features/settings/presentation/widgets/reading_preferences.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

final baqarah = SurahEntity(
  number: 2,
  name: 'البقرة',
  englishName: 'Al-Baqara',
  englishNameTranslation: 'The Cow',
  revelationType: 'Medinan',
  totalAyah: 286,
);

Future<void> openReader(
  WidgetTester tester,
  SharedPreferences prefs,
  BookmarkProvider bookmark, {
  int? rangeFromUnit,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          ChangeNotifierProvider.value(value: bookmark),
        ],
        child: MaterialApp(
          home: SurahDetailsScreen(
            surah: baqarah,
            surahNumber: 2,
            rangeFromUnit: rangeFromUnit,
          ),
        ),
      ),
    );
    await rootBundle.loadString('assets/quran_master.json');
  });
  await tester.pumpAndSettle();
}

double currentPage(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!.page!;

void main() {
  testWidgets('reopening a surah resumes on the last page read', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bookmark = BookmarkProvider(prefs: prefs);
    addTearDown(bookmark.dispose);

    await openReader(tester, prefs, bookmark);
    expect(currentPage(tester), 0);
    final next = find.byTooltip(appL10n.readerControlsMessage2);
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(currentPage(tester), 2);
    expect(ReadingPreferences.lastAyah(prefs, 2), isNotNull);

    // Close the reader, then open the same surah again.
    await tester.pumpWidget(const SizedBox.shrink());
    await openReader(tester, prefs, bookmark);
    expect(currentPage(tester), 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a khatma range keeps its own start and saves nothing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReadingPreferences.lastAyahKey(2): 100,
    });
    final prefs = await SharedPreferences.getInstance();
    final bookmark = BookmarkProvider(prefs: prefs);
    addTearDown(bookmark.dispose);

    await openReader(tester, prefs, bookmark, rangeFromUnit: 1);
    expect(currentPage(tester), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
