import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/domain/services/basmala.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:sakina_app/features/settings/presentation/widgets/reading_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _openReader(
  WidgetTester tester,
  int surahNumber, {
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => BookmarkProvider(prefs: prefs)),
      ],
      child: MaterialApp(
        home: SurahDetailsScreen(
          surah: SurahEntity(
            number: surahNumber,
            name: 'سورة',
            englishName: '',
            englishNameTranslation: '',
            revelationType: 'Meccan',
            totalAyah: 0,
          ),
          surahNumber: surahNumber,
        ),
      ),
    ),
  );
  // The 2.7 MB Quran asset is decoded off the fake clock; wait for the page.
  for (var i = 0; i < 50 && _pageTextFinder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 500));
  expect(_pageTextFinder, findsWidgets, reason: 'reader finished loading');
  return prefs;
}

/// The span of a flowing Quran paragraph inside [widget], or null.
///
/// `Text.rich` wraps the span it is given in an outer span, so the verses
/// are the children of that single child. The basmala line is a plain
/// `Text` with no children and is not matched.
TextSpan? quranParagraphSpan(Widget widget) {
  if (widget is! RichText || widget.text is! TextSpan) return null;
  final List<InlineSpan>? outer = (widget.text as TextSpan).children;
  if (outer == null || outer.length != 1 || outer.single is! TextSpan) {
    return null;
  }
  final TextSpan inner = outer.single as TextSpan;
  if (inner.style?.fontFamily != quranFontFamily) return null;
  return (inner.children?.isNotEmpty ?? false) ? inner : null;
}

final Finder _pageTextFinder = find.byWidgetPredicate(
  (widget) => quranParagraphSpan(widget) != null,
);

TextSpan _firstPageText(WidgetTester tester) =>
    quranParagraphSpan(tester.widget(_pageTextFinder.first))!;

void main() {
  setUp(() {
    // A cached load from a previous test's fake clock would never complete.
    rootBundle.evict('assets/quran_master.json');
  });

  testWidgets('surah 2 shows the basmala as a header, not inside ayah 1', (
    tester,
  ) async {
    await _openReader(tester, 2);

    expect(find.byKey(const Key('surah-basmala-2')), findsOneWidget);
    expect(find.text(uthmaniBasmala), findsOneWidget);
    final plain = _firstPageText(tester).toPlainText();
    expect(plain, isNot(contains(uthmaniBasmala)));
    expect(
      tester.getTopLeft(find.byKey(const Key('surah-basmala-2'))).dy,
      lessThan(tester.getTopLeft(_pageTextFinder.first).dy),
      reason: 'header first',
    );
  });

  testWidgets('At-Tawbah has no basmala header', (tester) async {
    await _openReader(tester, 9);

    expect(find.byKey(const Key('surah-basmala-9')), findsNothing);
    expect(find.text(uthmaniBasmala), findsNothing);
  });

  testWidgets('Al-Fatiha keeps the basmala as numbered ayah 1', (tester) async {
    await _openReader(tester, 1);

    expect(find.byKey(const Key('surah-basmala-1')), findsNothing);
    final plain = _firstPageText(tester).toPlainText();
    expect(plain, startsWith(uthmaniBasmala));
    // The basmala appears once: as ayah 1, with no separate banner.
    expect(find.text(uthmaniBasmala), findsNothing);
  });

  testWidgets('Quran text uses the Quran font at the saved size', (
    tester,
  ) async {
    await _openReader(tester, 2, stored: {ReadingPreferences.fontKey: 36.0});

    final style = _firstPageText(tester).style!;
    expect(style.fontFamily, quranFontFamily);
    expect(style.fontSize, 36.0);
  });

  testWidgets('large text is never shrunk to fit the page', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _openReader(tester, 2, stored: {ReadingPreferences.fontKey: 38.0});

    expect(find.byType(FittedBox), findsNothing);
    expect(
      find.ancestor(
        of: _pageTextFinder.first,
        matching: find.byType(CustomScrollView),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
