import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_design.dart';

class ThemeProvider extends ValueNotifier<ThemeMode> {
  final SharedPreferences prefs;
  static const String _themeModeKey = 'theme_mode';
  static const String designKey = 'app_design';

  ThemeProvider({required this.prefs}) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => value;

  AppDesign _design = AppDesign.warm;

  /// The chosen visual direction; the original warm look by default.
  AppDesign get design => _design;

  /// The mode actually applied: a dark-only design overrides the setting,
  /// which is kept so it returns when another design is chosen.
  ThemeMode get effectiveThemeMode =>
      _design.alwaysDark ? ThemeMode.dark : value;

  Future<void> setDesign(AppDesign design) async {
    if (design == _design) return;
    _design = design;
    notifyListeners();
    await prefs.setString(designKey, design.name);
  }

  bool get isDarkMode => value == ThemeMode.dark;

  void _loadThemeMode() {
    final storedDesign = prefs.get(designKey);
    _design = AppDesign.values.firstWhere(
      (d) => d.name == storedDesign,
      orElse: () => AppDesign.warm,
    );
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
