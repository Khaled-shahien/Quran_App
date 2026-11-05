import 'package:sakina_app/l10n/localization.dart';

/// Existing Egyptian default, exposed to the user and changeable.
///
/// Method ids keep the values used by earlier versions (and by AlAdhan), so
/// saved user choices stay valid.
abstract final class PrayerCalculationPolicy {
  static const int muslimWorldLeague = 3;
  static const int ummAlQura = 4;
  static const int egyptian = 5;

  static const int defaultMethod = egyptian;
  static final Map<int, String> methods = {
    muslimWorldLeague: appL10n.prayerCalculationPolicyMessage1,
    ummAlQura: appL10n.prayerCalculationPolicyMessage2,
    egyptian: appL10n.prayerCalculationPolicyMessage3,
  };
}

/// How the start of Asr is determined.
enum AsrMadhab {
  /// Shadow equals the object's height (Shafi'i, Maliki, Hanbali). Default.
  standard,

  /// Shadow equals twice the object's height.
  hanafi;

  static const String preferenceKey = 'prayer_asr_madhab';

  static AsrMadhab fromStorage(Object? value) =>
      value == 'hanafi' ? AsrMadhab.hanafi : AsrMadhab.standard;
}

/// Preference key for the chosen place's IANA timezone (absent = device).
const String prayerTimeZonePreferenceKey = 'prayer_timezone';
