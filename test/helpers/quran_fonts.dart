import 'package:flutter/services.dart';

bool _loaded = false;

/// Loads the app's real fonts into the test engine, so text is measured
/// with true glyphs rather than the default test font.
Future<void> loadQuranFonts() async {
  if (_loaded) return;
  final quran = FontLoader('AmiriQuran')
    ..addFont(rootBundle.load('fonts/AmiriQuran-Regular.ttf'));
  final script = FontLoader('Amiri')
    ..addFont(rootBundle.load('fonts/Amiri-Regular.ttf'))
    ..addFont(rootBundle.load('fonts/Amiri-Bold.ttf'));
  final ui = FontLoader('Cairo')..addFont(rootBundle.load('fonts/Cairo.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([quran.load(), script.load(), ui.load(), icons.load()]);
  _loaded = true;
}
