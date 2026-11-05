import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/accessibility/digit_style.dart';

class DigitStyleController extends ChangeNotifier {
  DigitStyleController(this._prefs) : _style = _read(_prefs);

  static const String key = 'digit_style';

  final SharedPreferences _prefs;
  DigitStyle _style;

  DigitStyle get style => _style;

  static DigitStyle _read(SharedPreferences prefs) {
    final name = prefs.get(key);
    return DigitStyle.values.firstWhere(
      (s) => s.name == name,
      orElse: () => DigitStyle.western,
    );
  }

  Future<void> setStyle(DigitStyle value) async {
    if (value == _style) return;
    _style = value;
    notifyListeners();
    await _prefs.setString(key, value.name);
  }
}
