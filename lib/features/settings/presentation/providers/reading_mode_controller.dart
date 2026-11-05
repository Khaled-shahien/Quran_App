import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the Quran reader uses the warm night-reading look.
class ReadingModeController extends ChangeNotifier {
  ReadingModeController(this._prefs)
    : _night = _prefs.getBool(nightKey) ?? false;

  static const String nightKey = 'reading_night_mode';

  final SharedPreferences _prefs;
  bool _night;

  bool get night => _night;

  Future<void> setNight(bool value) async {
    if (value == _night) return;
    _night = value;
    notifyListeners();
    await _prefs.setBool(nightKey, value);
  }
}
