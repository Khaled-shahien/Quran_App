import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';
import 'package:sakina_app/features/settings/presentation/providers/reading_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    rootBundle.evict('assets/quran_master.json');
  });

  test('night text is easy to read on the night page (WCAG AAA)', () {
    expect(contrast(AppTheme.nightText, AppTheme.nightPage), greaterThan(7));
    expect(contrast(AppTheme.nightText, AppTheme.nightPaper), greaterThan(7));
  });

  test('the night palette is warm (less blue than red)', () {
    for (final c in [
      AppTheme.nightPaper,
      AppTheme.nightPage,
      AppTheme.nightText,
    ]) {
      expect(c.b, lessThan(c.r));
    }
  });

  test('the choice is remembered', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await ReadingModeController(prefs).setNight(true);
    expect(ReadingModeController(prefs).night, isTrue);
  });

  testWidgets('night mode applies the night theme to the whole reader', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReadingModeController.nightKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          ChangeNotifierProvider(create: (_) => BookmarkProvider(prefs: prefs)),
          ChangeNotifierProvider(create: (_) => ReadingModeController(prefs)),
        ],
        child: MaterialApp(
          home: SurahDetailsScreen(
            surah: SurahEntity(
              number: 1,
              name: 'سورة',
              englishName: '',
              englishNameTranslation: '',
              revelationType: 'Meccan',
              totalAyah: 7,
            ),
            surahNumber: 1,
          ),
        ),
      ),
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppTheme.nightPaper);
    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.colorScheme.primary, AppTheme.nightText);
  });
}
