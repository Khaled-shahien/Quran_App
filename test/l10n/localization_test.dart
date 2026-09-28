import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/app_localizations_ar.dart';
import 'package:sakina_app/l10n/localization.dart';

class _TestStrings extends AppLocalizationsAr {
  @override
  String get prayerTitle => 'Delegate supplied title';
}

class _TestDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(_TestStrings());
  @override
  bool shouldReload(_TestDelegate old) => false;
}

void main() {
  test('Arabic messages preserve dynamic values and punctuation', () {
    expect(
      appL10n.currentWirdWidgetMessage20('الفاتحة', '7', '1'),
      'الفاتحة - الآية 7 - صفحة 1',
    );
    expect(appL10n.videoCategoryLabel1, 'خطب الجمعة');
    expect(appL10n.homeReminderTime1, 'AM 07:00');
    expect(appL10n.applicationTitle, 'Sakina');
  });

  testWidgets('lookup uses the supplied locale resources', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          _TestDelegate(),
          ...AppLocalizations.localizationsDelegates,
        ],
        home: Builder(builder: (context) => Text(l10nOf(context).prayerTitle)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delegate supplied title'), findsOneWidget);
  });

  testWidgets('isolated widgets retain Arabic fallback', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(builder: (context) => Text(l10nOf(context).prayerTitle)),
      ),
    );
    expect(find.text('أوقات الصلاة'), findsOneWidget);
  });

  test('ARB placeholders have typed metadata', () {
    final arb =
        jsonDecode(File('lib/l10n/app_ar.arb').readAsStringSync())
            as Map<String, dynamic>;
    for (final entry in arb.entries.where((e) => !e.key.startsWith('@'))) {
      final placeholders = RegExp(
        r'\{(\w+)\}',
      ).allMatches(entry.value as String);
      for (final placeholder in placeholders) {
        final metadata = arb['@${entry.key}'] as Map<String, dynamic>;
        expect(
          metadata['placeholders'][placeholder.group(1)]['type'],
          isNotEmpty,
          reason: '${entry.key}: ${placeholder.group(1)}',
        );
      }
    }
  });
}
