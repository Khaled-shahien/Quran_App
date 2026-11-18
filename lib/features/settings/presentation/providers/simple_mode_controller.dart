import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple mode: a home screen of four large tiles for people who want
/// fewer, bigger choices.
class SimpleModeController extends ChangeNotifier {
  SimpleModeController(this._prefs) : _enabled = _prefs.getBool(key) ?? false;

  static const String key = 'simple_mode';

  final SharedPreferences _prefs;
  bool _enabled;

  bool get enabled => _enabled;

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    await _prefs.setBool(key, value);
  }
}
