import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

/// The interface language chosen in Settings. Arabic unless the user picks
/// another; religious texts are Arabic in every language.
abstract final class AppLanguage {
  static const String key = 'app_language';
  static const List<String> codes = ['ar', 'en'];

  static String _code = 'ar';
  static String get code => _code;

  /// Reads the choice; call at start-up and in each background isolate.
  static void load(SharedPreferences prefs) => set(prefs.getString(key));

  static void set(String? code) => _code = codes.contains(code) ? code! : 'ar';
}

/// Strings in the chosen language. Also serves background notifications
/// and providers that have no widget context.
AppLocalizations get appL10n =>
    lookupAppLocalizations(Locale(AppLanguage.code));

/// Use the widget locale when available, including isolated widget previews.
AppLocalizations l10nOf(BuildContext context) =>
    AppLocalizations.of(context) ?? appL10n;
