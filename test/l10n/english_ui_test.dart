import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/settings/presentation/providers/language_controller.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

final _arabic = RegExp('[؀-ۿ]');

void main() {
  final ar = _arb('app_ar.arb');
  final en = _arb('app_en.arb');
  final keys = [
    for (final k in ar.keys)
      if (!k.startsWith('@')) k,
  ];

  test('every string has an English version with the same placeholders', () {
    Set<String> placeholders(String s) => {
      for (final m in RegExp(r'\{(\w+)\}').allMatches(s)) m[1]!,
    };
    for (final k in keys) {
      expect(en[k], isA<String>(), reason: k);
      expect(
        placeholders(en[k] as String),
        placeholders(ar[k] as String),
        reason: k,
      );
    }
  });

  test(
    'English strings are English, except the religious texts kept in Arabic',
    () {
      // Verses, the basmala, dhikr phrases and quoted hadith stay Arabic in
      // every language; so does the name of the Arabic language itself.
      const keptArabic = {
        'appStringsMessage5',
        'hadeathDetailsScreenMessage1',
        'readerContentMessage3',
        'qiblaScreenMessage25',
        'tasbeehScreenMessage1',
        'tasbeehScreenMessage2',
        'tasbeehScreenMessage3',
        'tasbeehScreenMessage4',
        'notificationServiceMessage20',
        'notificationServiceMessage22',
        'notificationServiceMessage24',
        'notificationServiceMessage26',
        'digitStyleArabic',
        'languageArabic',
        'prayerCitySearchHint',
      };
      for (final k in keys) {
        final value = en[k] as String;
        if (keptArabic.contains(k)) continue;
        expect(_arabic.hasMatch(value), isFalse, reason: '$k: $value');
      }
      for (final k in const [
        'appStringsMessage5',
        'readerContentMessage3',
        'qiblaScreenMessage25',
        'tasbeehScreenMessage1',
      ]) {
        expect(en[k], ar[k], reason: 'religious text $k is copied unchanged');
      }
    },
  );

  test('the chosen language words notifications and screens alike', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var rescheduled = 0;
    final c = LanguageController(prefs, onChanged: () async => rescheduled++);
    expect(c.code, 'ar');
    expect(appL10n.prayerTitle, 'أوقات الصلاة');
    await c.setLanguage('en');
    expect(appL10n.prayerTitle, 'Prayer times');
    expect(prefs.getString(AppLanguage.key), 'en');
    expect(rescheduled, 1);
    await c.setLanguage('xx');
    expect(c.code, 'en');

    // A background isolate reads the same choice.
    AppLanguage.set(null);
    AppLanguage.load(prefs);
    expect(AppLanguage.code, 'en');
    AppLanguage.set('ar');
  });
}
