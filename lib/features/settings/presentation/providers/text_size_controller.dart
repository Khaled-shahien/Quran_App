import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App text size, applied on top of the phone's own text size.
enum AppTextSize {
  normal(1.0),
  large(1.15),
  larger(1.3),
  largest(1.5);

  const AppTextSize(this.factor);
  final double factor;
}

class TextSizeController extends ChangeNotifier {
  TextSizeController(this._prefs) : _size = _read(_prefs);

  static const String key = 'ui_text_size';

  final SharedPreferences _prefs;
  AppTextSize _size;

  AppTextSize get size => _size;
  double get factor => _size.factor;

  static AppTextSize _read(SharedPreferences prefs) {
    final name = prefs.get(key);
    return AppTextSize.values.firstWhere(
      (s) => s.name == name,
      orElse: () => AppTextSize.normal,
    );
  }

  Future<void> setSize(AppTextSize value) async {
    if (value == _size) return;
    _size = value;
    notifyListeners();
    await _prefs.setString(key, value.name);
  }
}
