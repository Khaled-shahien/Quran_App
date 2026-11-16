import 'package:flutter/material.dart';

/// Font used for Quranic text only (bundled unmodified, OFL). Interim until
/// permission to bundle KFGQPC Uthmanic Hafs is granted.
const String quranFontFamily = 'AmiriQuran';

/// The type scale. Cairo for the interface, Amiri for verses and adhkar.
///
/// Cairo's natural line height is about 1.87, which is loose for headings
/// and uneven between styles, so every style sets its own height: tight for
/// display sizes, open for body text that carries diacritics.
abstract class AppTypography {
  /// The app's UI font; set once on the theme.
  static const String uiFontFamily = 'Cairo';

  /// Verses, adhkar and other sacred text shown outside the Quran reader.
  static const String scriptFontFamily = 'Amiri';

  /// Sacred text on cards (verse of the day, wird preview, dhikr).
  static const TextStyle script = TextStyle(
    fontFamily: scriptFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.8,
    letterSpacing: 0,
  );

  /// Large numerals: counters, clocks, countdowns.
  static const TextStyle numeral = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle displayLarge = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
  );

  static TextStyle displayMedium = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
  );

  static TextStyle displaySmall = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  static TextStyle headlineLarge = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0,
  );

  static TextStyle headlineMedium = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0,
  );

  static TextStyle headlineSmall = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static TextStyle titleLarge = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.45,
    letterSpacing: 0,
  );

  static TextStyle titleMedium = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  static TextStyle titleSmall = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  static TextStyle bodyLarge = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.7,
    letterSpacing: 0,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.7,
    letterSpacing: 0,
  );

  static TextStyle bodySmall = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  static TextStyle labelLarge = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0,
  );

  static TextStyle labelMedium = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0,
  );

  static TextStyle labelSmall = const TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0,
  );
}
