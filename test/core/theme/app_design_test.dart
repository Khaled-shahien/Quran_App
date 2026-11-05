import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/theme/app_theme.dart';
import 'package:sakina_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const palettes = {
    'sage light': AppPalette.sageLight,
    'sage dark': AppPalette.sageDark,
    'night': AppPalette.night,
  };

  for (final entry in palettes.entries) {
    final p = entry.value;
    test('${entry.key}: text, buttons and borders are readable', () {
      expect(contrast(p.text, p.background), greaterThanOrEqualTo(4.5));
      expect(contrast(p.body, p.background), greaterThanOrEqualTo(4.5));
      expect(contrast(p.caption, p.background), greaterThanOrEqualTo(4.5));
      expect(contrast(p.text, p.decor.card), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(4.5));
      expect(
        contrast(p.decor.onAccent, p.decor.accent),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(p.outline, p.background), greaterThanOrEqualTo(3));
      // Light text sits on the feature card in every design.
      expect(
        contrast(Colors.white, p.decor.featureCard),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  test('every design builds both themes with its decoration', () {
    for (final design in AppDesign.values) {
      for (final theme in [AppTheme.light(design), AppTheme.dark(design)]) {
        expect(theme.extension<SakinaDecor>(), isNotNull);
      }
    }
    expect(AppTheme.light(AppDesign.night).brightness, Brightness.dark);
  });

  test('the warm design is the original theme, unchanged', () {
    expect(
      AppTheme.light(AppDesign.warm).colorScheme.primary,
      AppTheme.lightTheme.colorScheme.primary,
    );
    expect(
      AppTheme.dark(AppDesign.warm).scaffoldBackgroundColor,
      AppTheme.darkTheme.scaffoldBackgroundColor,
    );
  });

  test('design choice defaults to warm, is remembered, and night forces '
      'dark without losing the light/dark choice', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs: prefs);
    expect(provider.design, AppDesign.warm);

    await provider.setThemeMode(ThemeMode.light);
    await provider.setDesign(AppDesign.night);
    expect(provider.effectiveThemeMode, ThemeMode.dark);
    expect(provider.themeMode, ThemeMode.light);

    final reloaded = ThemeProvider(prefs: prefs);
    expect(reloaded.design, AppDesign.night);

    await reloaded.setDesign(AppDesign.sage);
    expect(reloaded.effectiveThemeMode, ThemeMode.light);
  });
}
