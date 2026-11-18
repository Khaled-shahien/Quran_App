import 'package:flutter/widgets.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The interface language; changing it also re-words what is scheduled.
class LanguageController extends ChangeNotifier {
  LanguageController(this._prefs, {Future<void> Function()? onChanged})
    : _onChanged = onChanged {
    AppLanguage.load(_prefs);
  }

  final SharedPreferences _prefs;
  final Future<void> Function()? _onChanged;

  String get code => AppLanguage.code;
  Locale get locale => Locale(code);

  Future<void> setLanguage(String code) async {
    if (code == AppLanguage.code || !AppLanguage.codes.contains(code)) return;
    AppLanguage.set(code);
    await _prefs.setString(AppLanguage.key, code);
    notifyListeners();
    await _onChanged?.call();
  }
}
