/// Existing Egyptian default, exposed to the user and changeable.
abstract final class PrayerCalculationPolicy {
  static const int defaultMethod = 5;
  static const Map<int, String> methods = {
    3: 'رابطة العالم الإسلامي',
    4: 'أم القرى',
    5: 'الهيئة المصرية العامة للمساحة',
  };
}
