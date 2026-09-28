import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:sakina_app/l10n/localization.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('RTL reader arrows and paging agree, dark=$dark', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final bookmark = BookmarkProvider(
        prefs: await SharedPreferences.getInstance(),
      );
      addTearDown(bookmark.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: bookmark,
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: SurahDetailsScreen(
                  surah: SurahEntity(
                    number: 2,
                    name: 'البقرة',
                    englishName: 'Al-Baqara',
                    englishNameTranslation: 'The Cow',
                    revelationType: 'Medinan',
                    totalAyah: 286,
                  ),
                  surahNumber: 2,
                ),
              ),
            ),
          ),
        );
        await rootBundle.loadString('assets/quran_master.json');
      });
      await tester.pumpAndSettle();

      // In RTL Quran reading, previous pages are to the right,
      // next pages are to the left. So:
      // - Previous button uses chevron_right (pointing toward earlier pages)
      // - Next button uses chevron_left (pointing toward later pages)
      final previous = find.byTooltip(appL10n.readerControlsMessage1);
      final next = find.byTooltip(appL10n.readerControlsMessage2);

      // Verify correct icon direction for RTL Quran reader.
      expect(
        find.descendant(
          of: previous,
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: next, matching: find.byIcon(Icons.chevron_left)),
        findsOneWidget,
      );

      // In RTL Row, the first child (previous) is on the right.
      expect(
        tester.getCenter(previous).dx,
        greaterThan(tester.getCenter(next).dx),
      );

      // At page 0, previous should be disabled.
      final previousButton = find.ancestor(
        of: previous,
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(previousButton).onPressed, isNull);

      // Verify PageView starts at page 0 and button navigation works.
      final pages = tester.widget<PageView>(find.byType(PageView));
      expect(pages.controller!.page, 0);

      // Tap next to go to page 1.
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(pages.controller!.page, 1);

      // Previous should now be enabled.
      expect(tester.widget<IconButton>(previousButton).onPressed, isNotNull);

      // Tap previous to return to page 0.
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(pages.controller!.page, 0);

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
