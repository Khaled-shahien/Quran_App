import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/data/data_sources/quran_master_asset.dart';
import 'package:sakina_app/features/quran/data/data_sources/tafsir_asset.dart';
import 'package:sakina_app/features/quran/presentation/widgets/tafsir_sheet.dart';

void main() {
  late Map<int, List<String>> tafsir;

  setUpAll(() {
    tafsir = TafsirAsset.parse(File(TafsirAsset.path).readAsStringSync());
  });

  test('one tafsir entry for every ayah of the bundled mushaf', () {
    final surahs = QuranMasterAsset.parse(
      File(QuranMasterAsset.path).readAsStringSync(),
    );
    var total = 0;
    for (final surah in surahs) {
      final int number = (surah['number'] as num).toInt();
      final int ayahs = (surah['ayahs'] as List).length;
      expect(tafsir[number], hasLength(ayahs), reason: 'surah $number');
      expect(tafsir[number]!.every((t) => t.isNotEmpty), isTrue);
      total += ayahs;
    }
    expect(total, 6236);
  });

  test('the file is bundled unchanged, with its Tanzil header', () {
    final String raw = File(TafsirAsset.path).readAsStringSync();
    expect(raw, contains('ID: ar.muyassar'));
    expect(raw, contains('Source: Tanzil.net'));
    expect(raw, isNot(contains('\r')));
  });

  test('a damaged file is rejected', () {
    expect(() => TafsirAsset.parse('1|1|a\n1|3|b\n'), throwsFormatException);
    expect(() => TafsirAsset.parse('1|1|a\n'), throwsFormatException);
    expect(() => TafsirAsset.parse('x|1|a\n'), throwsFormatException);
  });

  testWidgets('the sheet shows the verse, its tafsir and the source', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTafsirSheet(
                context,
                surah: 112,
                ayah: 1,
                surahName: 'الإخلاص',
                verseText: 'verse',
                loader: (s, a) async => tafsir[s]![a - 1],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('الإخلاص، الآية 1'), findsOneWidget);
    expect(find.text(tafsir[112]![0]), findsOneWidget);
    expect(find.textContaining('tanzil.net'), findsOneWidget);
  });

  testWidgets('a failed read offers a retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTafsirSheet(
                context,
                surah: 1,
                ayah: 1,
                surahName: 'الفاتحة',
                verseText: 'verse',
                loader: (s, a) async {
                  calls++;
                  if (calls == 1) throw StateError('missing');
                  return 'text';
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('تعذّر فتح التفسير.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('text'), findsOneWidget);
  });
}
