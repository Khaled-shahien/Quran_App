import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/domain/services/basmala.dart';
import 'package:sakina_app/features/quran/domain/services/reader_layout.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:sakina_app/features/settings/presentation/widgets/reading_preferences.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The reader must show the source verses exactly: every verse, in order,
/// character for character, with nothing added to the verse text itself.

/// What the reader should show for [surah]: the stored verses, with the
/// basmala taken off ayah 1 where it is shown as a header.
List<({int ayah, String text, int page})> _sourceVerses(int surah) {
  final quran =
      jsonDecode(File('assets/quran_master.json').readAsStringSync())
          as List<dynamic>;
  final data = quran.firstWhere((s) => (s as Map)['number'] == surah) as Map;
  return [
    for (final raw in data['ayahs'] as List<dynamic>)
      (
        ayah: (raw as Map)['numberInSurah'] as int,
        text: splitLeadingBasmala(
          surahNumber: surah,
          ayahNumber: raw['numberInSurah'] as int,
          text: (raw['text'] as String).trim(),
        ).ayahText,
        page: raw['page'] as int,
      ),
  ];
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

final Finder _quranRichText = find.byWidgetPredicate(
  (widget) => quranParagraphSpan(widget) != null,
);

/// The verse texts and the marker text after each, read from every flowing
/// paragraph and verse row currently built, top to bottom.
List<({String text, String marker})> _renderedVerses(WidgetTester tester) {
  final elements = _quranRichText.evaluate().toList()
    ..sort((a, b) {
      final ay = (a.renderObject! as RenderBox).localToGlobal(Offset.zero).dy;
      final by = (b.renderObject! as RenderBox).localToGlobal(Offset.zero).dy;
      return ay.compareTo(by);
    });
  final verses = <({String text, String marker})>[];
  for (final element in elements) {
    final spans = quranParagraphSpan(
      element.widget,
    )!.children!.cast<TextSpan>();
    expect(spans.length.isEven, isTrue, reason: 'verse then marker');
    for (var i = 0; i < spans.length; i += 2) {
      verses.add((text: spans[i].text!, marker: spans[i + 1].text!));
    }
  }
  return verses;
}

Future<void> _open(WidgetTester tester, int surah, ReaderLayout layout) async {
  rootBundle.evict('assets/quran_master.json');
  tester.view.physicalSize = const Size(1080, 8000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    ReadingPreferences.layoutKey: layout.name,
    ReadingPreferences.fontKey: 22.0,
  });
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
  for (var i = 0; i < 50 && _quranRichText.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // Short surahs fit one tall screen, so every verse is built at once.
  for (final surah in [1, 9, 36, 112]) {
    for (final layout in [ReaderLayout.continuous, ReaderLayout.verses]) {
      testWidgets('surah $surah, ${layout.name}: verses match the source', (
        tester,
      ) async {
        await _open(tester, surah, layout);
        final source = _sourceVerses(surah);
        // Only the first screenful is built; compare that prefix exactly.
        final rendered = _renderedVerses(tester);
        expect(rendered, isNotEmpty);
        expect(rendered.length, lessThanOrEqualTo(source.length));
        for (var i = 0; i < rendered.length; i++) {
          expect(rendered[i].text, source[i].text, reason: 'ayah ${i + 1}');
          expect(
            rendered[i].marker.trim().replaceAll(' ', ''),
            ayahEndMarker(source[i].ayah),
            reason: 'marker of ayah ${i + 1}',
          );
        }
        if (surah == 1 || surah == 112) {
          expect(rendered.length, source.length, reason: 'whole surah built');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('Al-Baqarah, page by page: all 286 verses, in order, on the '
      'right mushaf pages', (tester) async {
    await _open(tester, 2, ReaderLayout.pages);
    final source = _sourceVerses(2);
    final pages = source.map((v) => v.page).toSet().toList()..sort();

    final collected = <String>[];
    final next = find.byTooltip(appL10n.readerControlsMessage2);
    for (var i = 0; i < pages.length; i++) {
      final onPage = _renderedVerses(tester);
      final expected = source.where((v) => v.page == pages[i]).toList();
      expect(
        onPage.map((v) => v.text).toList(),
        expected.map((v) => v.text).toList(),
        reason: 'mushaf page ${pages[i]}',
      );
      collected.addAll(onPage.map((v) => v.text));
      if (i < pages.length - 1) {
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
    }
    expect(collected.length, 286);
    expect(collected, source.map((v) => v.text).toList());
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
