import 'package:sakina_app/l10n/localization.dart';

/// Existing Egyptian default, exposed to the user and changeable.
abstract final class PrayerCalculationPolicy {
  static const int defaultMethod = 5;
  static final Map<int, String> methods = {
    3: appL10n.prayerCalculationPolicyMessage1,
    4: appL10n.prayerCalculationPolicyMessage2,
    5: appL10n.prayerCalculationPolicyMessage3,
  };
}
