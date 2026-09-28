import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  final SharedPreferences prefs;
  static const String _themeModeKey = 'theme_mode';

  ThemeProvider({required this.prefs}) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => value;

  bool get isDarkMode => value == ThemeMode.dark;

  void _loadThemeMode() {
    final String? themeString = prefs.getString(_themeModeKey);
    if (themeString == 'dark') {
      value = ThemeMode.dark;
    } else if (themeString == 'light') {
      value = ThemeMode.light;
    } else {
      value = ThemeMode.system;
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    value = mode;
    await prefs.setString(_themeModeKey, mode.name);
  }
}
