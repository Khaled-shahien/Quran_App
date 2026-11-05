import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';

/// Guards the owner-approved Hisn al-Muslim wording in the bundled adhkar.
/// Comparisons ignore diacritics so they do not depend on mark ordering.
void main() {
  final categories =
      (jsonDecode(File('assets/prayers_data.json').readAsStringSync())
              as List<dynamic>)
          .map((c) => AzkarCategoryModel.fromJson(c as Map<String, dynamic>))
          .toList();

  final marks = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );
  String plain(String s) => s.replaceAll(marks, '');

  AzkarItemModel item(String category, String title) => categories
      .firstWhere((c) => c.category == category)
      .items
      .firstWhere((i) => i.title == title);

  test('Al-Mu\'awwidhat contain the three surahs in full', () {
    final text = plain(item('أذكار الصباح', 'المعوذات').text);
    expect(text, isNot(contains('...')));
    expect(text, contains('ولم يكن له كفوا أحد'));
    expect(text, contains('ومن شر حاسد إذا حسد'));
    expect(text, contains('من الجنة و الناس'));
  });

  test('Al-Mu\'awwidhat cite Hisn al-Muslim, not the al-Baqarah hadith', () {
    final reference = item('أذكار الصباح', 'المعوذات').reference;
    expect(reference, 'حصن المسلم (76)');
    expect(item('أذكار الصباح', 'المعوذات').repeat, 3);
  });

  test('Istikhara includes the conditional core of the dua', () {
    final dua = item('أدعية مأثورة', 'الاستخارة');
    expect(plain(dua.text), contains('فاصرفه عني واصرفني عنه'));
    expect(plain(dua.instructionBefore), startsWith('قال جابر'));
  });

  test('travel dua is complete', () {
    expect(
      plain(item('دعاء السفر', 'دعاء السفر كامل').text),
      contains('لربنا حامدون'),
    );
  });

  test('after-prayer tasbih counts 33 as in Hisn al-Muslim', () {
    expect(item('بعد الصلاة', 'التسبيح').repeat, 33);
  });

  test('mosque guidance is shown apart from the dhikr', () {
    final enter = item('أذكار المسجد', 'دخول المسجد');
    expect(plain(enter.instructionBefore), contains('يبدأ برجله اليمنى'));
    expect(plain(enter.text), isNot(contains('يبدأ برجله')));
    expect(plain(enter.text), contains('اللهم افتح لي أبواب رحمتك'));
  });

  test('every Hisn-sourced entry names its Hisn number', () {
    final sourced = categories
        .expand((c) => c.items)
        .where((i) => i.reference.contains('حصن المسلم'))
        .toList();
    // 19 corrected entries + 20 added to the morning + 20 to the evening.
    expect(sourced, hasLength(59));
    for (final i in sourced) {
      expect(i.reference, matches(RegExp(r'حصن المسلم \(\d+\)')));
      expect(i.text.trim(), i.text, reason: '${i.title}: no stray spaces');
    }
  });

  test('morning and evening hold every Hisn al-Muslim dhikr, in order', () {
    List<int> hisnIds(String category) => categories
        .firstWhere((c) => c.category == category)
        .items
        .map((i) => RegExp(r'حصن المسلم \((\d+)\)').firstMatch(i.reference))
        .whereType<RegExpMatch>()
        .map((m) => int.parse(m.group(1)!))
        .toList();

    // 97 is said in the evening only.
    expect(hisnIds('أذكار الصباح'), [
      for (var id = 75; id <= 98; id++)
        if (id != 97) id,
    ]);
    // 93-95 are morning-only; 77 is present in its full evening form.
    expect(hisnIds('أذكار المساء'), [
      for (var id = 75; id <= 98; id++)
        if (id != 77 && (id < 93 || id > 95)) id,
    ]);
  });

  test('repeat counts follow Hisn al-Muslim', () {
    int repeat(String category, int hisnId) => categories
        .firstWhere((c) => c.category == category)
        .items
        .firstWhere((i) => i.reference.contains('حصن المسلم ($hisnId)'))
        .repeat;
    expect(repeat('أذكار الصباح', 80), 4);
    expect(repeat('أذكار الصباح', 83), 7, reason: 'the text says seven');
    expect(repeat('أذكار الصباح', 91), 100);
    expect(repeat('أذكار الصباح', 93), 100);
    expect(repeat('أذكار المساء', 97), 3);
    expect(repeat('أذكار المساء', 98), 10);
  });

  test('titles are unique within each category', () {
    for (final c in categories) {
      final titles = c.items.map((i) => i.title).toList();
      expect(titles.toSet(), hasLength(titles.length), reason: c.category);
    }
  });

  test('Quranic dua of Ibrahim 41 is exactly the Mushaf text', () {
    final quran =
        jsonDecode(File('assets/quran_master.json').readAsStringSync())
            as List<dynamic>;
    final ayah = (quran[13]['ayahs'] as List<dynamic>)[40]['text'] as String;
    final duas =
        (jsonDecode(File('assets/quran_duas.json').readAsStringSync())
                as List<dynamic>)
            .map((c) => AzkarCategoryModel.fromJson(c as Map<String, dynamic>))
            .expand((c) => c.items);
    final dua = duas.firstWhere((i) => i.reference.contains('إبراهيم'));
    expect(dua.text, ayah);
  });

  test('every entry has text, a reference and a positive repeat', () {
    for (final i in categories.expand((c) => c.items)) {
      expect(i.text, isNotEmpty, reason: i.title);
      expect(i.reference, isNotEmpty, reason: i.title);
      expect(i.repeat, greaterThan(0), reason: i.title);
    }
  });
}
