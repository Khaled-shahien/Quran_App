import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:sakina_app/features/settings/presentation/widgets/reading_preferences.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/quran_fonts.dart';

/// Mushaf pages: one page at a time, turned only by horizontal swipes, each
/// page a fixed surface that fits the screen without scrolling.

final Finder _pages = find.byKey(const Key('reader-pages'));

/// Phones, in physical pixels and device pixel ratio.
const ({Size size, double ratio}) _pixel7 = (
  size: Size(1080, 2400),
  ratio: 2.625,
);
const ({Size size, double ratio}) _smallPhone = (
  size: Size(720, 1280),
  ratio: 2,
);
const ({Size size, double ratio}) _pixel7Landscape = (
  size: Size(2400, 1080),
  ratio: 2.625,
);

Future<void> _open(
  WidgetTester tester,
  int surah, {
  ({Size size, double ratio}) phone = _pixel7,
}) async {
  rootBundle.evict('assets/quran_master.json');
  tester.view.physicalSize = phone.size;
  tester.view.devicePixelRatio = phone.ratio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    ReadingPreferences.layoutKey: 'pages',
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => BookmarkProvider(prefs: prefs)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SurahDetailsScreen(
          surah: SurahEntity(
            number: surah,
            name: 'سورة',
            englishName: '',
            englishNameTranslation: '',
            revelationType: 'Meccan',
            totalAyah: 0,
          ),
          surahNumber: surah,
        ),
      ),
    ),
  );
  for (var i = 0; i < 50 && _pages.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(_pages, findsOneWidget, reason: 'reader opened in page layout');
}

PageController _controller(WidgetTester tester) =>
    tester.widget<PageView>(_pages).controller!;

/// Every built page's content against the area it was given.
void _expectBuiltPagesFit(WidgetTester tester, {String reason = ''}) {
  final boxes = find.descendant(of: _pages, matching: find.byType(OverflowBox));
  expect(boxes, findsWidgets);
  for (final element in boxes.evaluate()) {
    final box = element.renderObject! as RenderConstrainedOverflowBox;
    final child = box.child!;
    expect(
      child.size.height,
      lessThanOrEqualTo(box.size.height + 0.5),
      reason: 'page content fits its area $reason',
    );
  }
}

void main() {
  setUpAll(loadQuranFonts);

  testWidgets('pages turn horizontally and nothing on a page scrolls '
      'vertically', (tester) async {
    await _open(tester, 2);

    final view = tester.widget<PageView>(_pages);
    expect(view.scrollDirection, Axis.horizontal);

    // No vertical scrolling anywhere inside the pages.
    final vertical = find.descendant(
      of: _pages,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Scrollable &&
            axisDirectionToAxis(w.axisDirection) == Axis.vertical,
      ),
    );
    expect(vertical, findsNothing);
    expect(
      find.descendant(of: _pages, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );
    expect(
      find.descendant(of: _pages, matching: find.byType(ListView)),
      findsNothing,
    );
    // The only scrollable is the horizontal pager itself.
    final scrollables = find
        .descendant(of: _pages, matching: find.byType(Scrollable))
        .evaluate()
        .map((e) => e.widget as Scrollable)
        .where((s) => axisDirectionToAxis(s.axisDirection) == Axis.horizontal);
    expect(scrollables, isNotEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a vertical swipe changes nothing; swiping towards the right '
      'turns to the next page, as in an Arabic mushaf', (tester) async {
    await _open(tester, 2);
    expect(_controller(tester).page, 0);

    await tester.drag(_pages, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.drag(_pages, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(_controller(tester).page, 0, reason: 'vertical swipes ignored');

    await tester.fling(_pages, const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(_controller(tester).page, 1, reason: 'next page');

    await tester.fling(_pages, const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(_controller(tester).page, 0, reason: 'back to the first page');

    // At the first page, swiping back stays put: no wrap-around.
    await tester.fling(_pages, const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(_controller(tester).page, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('every page of Al-Baqarah fits a Pixel 7 screen without '
      'clipping', (tester) async {
    await _open(tester, 2);
    final count = tester
        .widget<PageView>(_pages)
        .childrenDelegate
        .estimatedChildCount!;
    expect(count, 48);
    for (var i = 0; i < count; i++) {
      _controller(tester).jumpToPage(i);
      await tester.pumpAndSettle();
      _expectBuiltPagesFit(tester, reason: 'page index $i');
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('short surahs and a small phone fit too', (tester) async {
    for (final surah in [1, 9, 36, 112]) {
      await _open(tester, surah, phone: _smallPhone);
      final count = tester
          .widget<PageView>(_pages)
          .childrenDelegate
          .estimatedChildCount!;
      for (var i = 0; i < count; i++) {
        _controller(tester).jumpToPage(i);
        await tester.pumpAndSettle();
        _expectBuiltPagesFit(tester, reason: 'surah $surah page index $i');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('in landscape every page fits at a comfortable size: a '
      'landscape line holds far more text', (tester) async {
    await _open(tester, 2, phone: _pixel7Landscape);
    final count = tester
        .widget<PageView>(_pages)
        .childrenDelegate
        .estimatedChildCount!;
    for (var i = 0; i < count; i++) {
      _controller(tester).jumpToPage(i);
      await tester.pumpAndSettle();
      _expectBuiltPagesFit(tester, reason: 'landscape page index $i');
      expect(
        find.byKey(const Key('reader-page-compressed')),
        findsNothing,
        reason: 'landscape page index $i is not reduced',
      );
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('on a short screen, a page drawn below the comfortable size '
      'is marked in the page bar', (tester) async {
    await _open(tester, 2, phone: (size: const Size(720, 1100), ratio: 2));
    final count = tester
        .widget<PageView>(_pages)
        .childrenDelegate
        .estimatedChildCount!;
    var marked = 0;
    for (var i = 0; i < count; i++) {
      _controller(tester).jumpToPage(i);
      await tester.pumpAndSettle();
      _expectBuiltPagesFit(tester, reason: 'short screen page index $i');
      marked += find
          .byKey(const Key('reader-page-compressed'))
          .evaluate()
          .length;
    }
    expect(marked, greaterThan(0), reason: 'some pages need reducing');
    expect(marked, lessThan(count), reason: 'but not every page');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
