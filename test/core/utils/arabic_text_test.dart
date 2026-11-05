import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/utils/arabic_text.dart';

void main() {
  test('surah names drop Uthmani marks that break letter joining', () {
    expect(displaySurahName('سُورَةُ ٱلْفَاتِحَةِ'), 'سورة الفاتحة');
    expect(displaySurahName('سُورَةُ آلِ عِمۡرَانَ'), 'سورة آل عمران');
    expect(displaySurahName('سُورَةُ المَائـِدَةِ'), 'سورة المائدة');
    expect(displaySurahName('سُورَةُ يسٓ'), 'سورة يس');
    expect(displaySurahName('سُورَةُ الرَّحۡمَٰن'), 'سورة الرحمن');
  });

  test('every surah name in the Quran asset becomes plain Arabic', () {
    final List<dynamic> surahs =
        jsonDecode(File('assets/quran_master.json').readAsStringSync())
            as List<dynamic>;
    expect(surahs, hasLength(114));

    // Plain Arabic letters (U+0621–U+064A), hamza forms and spaces only.
    final RegExp plain = RegExp(r'^سورة [ء-غف-ي ]+$');
    for (final dynamic surah in surahs) {
      final String name = displaySurahName((surah as Map)['name'] as String);
      expect(name, matches(plain), reason: 'surah ${surah['number']}: $name');
    }
  });
}
