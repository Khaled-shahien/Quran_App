import 'package:sakina_app/l10n/localization.dart';

/// The calculation methods offered, with the Egyptian default.
///
/// Method ids are AlAdhan's (`method=` parameter), as earlier versions
/// stored, so saved user choices stay valid and times can be compared with
/// AlAdhan. Only Sunni methods are offered; adding others is an owner
/// decision (docs/audit/EXTERNAL_BLOCKERS.md, B-10).
abstract final class PrayerCalculationPolicy {
  static const int karachi = 1;
  static const int northAmerica = 2;
  static const int muslimWorldLeague = 3;
  static const int ummAlQura = 4;
  static const int egyptian = 5;
  static const int gulfRegion = 8;
  static const int kuwait = 9;
  static const int qatar = 10;
  static const int singapore = 11;
  static const int france = 12;
  static const int turkiye = 13;
  static const int russia = 14;
  static const int moonsightingCommittee = 15;
  static const int dubai = 16;
  static const int tunisia = 18;
  static const int algeria = 19;
  static const int indonesia = 20;
  static const int morocco = 21;
  static const int portugal = 22;
  static const int jordan = 23;

  static const int defaultMethod = egyptian;

  /// Display name of every offered method, in the order shown.
  static final Map<int, String> methods = {
    egyptian: appL10n.prayerCalculationPolicyMessage3,
    ummAlQura: appL10n.prayerCalculationPolicyMessage2,
    muslimWorldLeague: appL10n.prayerCalculationPolicyMessage1,
    gulfRegion: appL10n.prayerMethodGulf,
    kuwait: appL10n.prayerMethodKuwait,
    qatar: appL10n.prayerMethodQatar,
    dubai: appL10n.prayerMethodDubai,
    jordan: appL10n.prayerMethodJordan,
    algeria: appL10n.prayerMethodAlgeria,
    tunisia: appL10n.prayerMethodTunisia,
    morocco: appL10n.prayerMethodMorocco,
    turkiye: appL10n.prayerMethodTurkiye,
    karachi: appL10n.prayerMethodKarachi,
    northAmerica: appL10n.prayerMethodNorthAmerica,
    moonsightingCommittee: appL10n.prayerMethodMoonsighting,
    france: appL10n.prayerMethodFrance,
    russia: appL10n.prayerMethodRussia,
    portugal: appL10n.prayerMethodPortugal,
    singapore: appL10n.prayerMethodSingapore,
    indonesia: appL10n.prayerMethodIndonesia,
  };

  /// The method commonly used in a country (ISO 3166-1 alpha-2), used only
  /// to *suggest* a method; the user confirms before anything changes.
  /// Countries without an entry get no suggestion.
  static const Map<String, int> recommendedByCountry = {
    'EG': egyptian,
    'SD': egyptian,
    'LY': egyptian,
    'SY': egyptian,
    'LB': egyptian,
    'IQ': egyptian,
    'PS': egyptian,
    'SA': ummAlQura,
    'YE': ummAlQura,
    'BH': gulfRegion,
    'OM': gulfRegion,
    'AE': dubai,
    'KW': kuwait,
    'QA': qatar,
    'JO': jordan,
    'DZ': algeria,
    'TN': tunisia,
    'MA': morocco,
    'TR': turkiye,
    'PK': karachi,
    'IN': karachi,
    'BD': karachi,
    'AF': karachi,
    'US': northAmerica,
    'CA': northAmerica,
    'GB': moonsightingCommittee,
    'IE': moonsightingCommittee,
    'FR': france,
    'RU': russia,
    'PT': portugal,
    'SG': singapore,
    'MY': singapore,
    'BN': singapore,
    'ID': indonesia,
    'DE': muslimWorldLeague,
    'NL': muslimWorldLeague,
    'BE': muslimWorldLeague,
    'AT': muslimWorldLeague,
    'CH': muslimWorldLeague,
    'IT': muslimWorldLeague,
    'ES': muslimWorldLeague,
    'SE': muslimWorldLeague,
    'NO': muslimWorldLeague,
    'DK': muslimWorldLeague,
  };

  static int? recommendedFor(String? countryCode) =>
      countryCode == null ? null : recommendedByCountry[countryCode];
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
