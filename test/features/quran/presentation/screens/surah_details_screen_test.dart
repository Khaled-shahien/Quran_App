import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SurahDetailsScreen renders verses and app bar metadata', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bookmarkProvider = BookmarkProvider(prefs: prefs);

    await tester.pumpWidget(
      ChangeNotifierProvider<BookmarkProvider>.value(
        value: bookmarkProvider,
        child: MaterialApp(
          home: SurahDetailsScreen(
            surah: SurahEntity(
              number: 1,
              name: 'سورة الفاتحة',
              englishName: 'Al-Fatiha',
              englishNameTranslation: 'The Opening',
              revelationType: 'Meccan',
              totalAyah: 7,
            ),
            surahNumber: 1,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('سورة الفاتحة'), findsOneWidget);
    expect(find.textContaining('مكية'), findsOneWidget);
    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('SurahDetailsScreen saves bookmark and shows confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bookmarkProvider = BookmarkProvider(prefs: prefs);

    await tester.pumpWidget(
      ChangeNotifierProvider<BookmarkProvider>.value(
        value: bookmarkProvider,
        child: MaterialApp(
          home: SurahDetailsScreen(
            surah: SurahEntity(
              number: 1,
              name: 'سورة الفاتحة',
              englishName: 'Al-Fatiha',
              englishNameTranslation: 'The Opening',
              revelationType: 'Meccan',
              totalAyah: 7,
            ),
            surahNumber: 1,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('حفظ العلامة'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('تم حفظ علامة القراءة بنجاح'), findsOneWidget);
    expect(bookmarkProvider.surahNumber, 1);
  });
}
