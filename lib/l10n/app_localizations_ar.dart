// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get prayerTitle => 'أوقات الصلاة';

  @override
  String get prayerLoadError => 'تعذر عرض مواقيت الصلاة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get choosePrayerLocation => 'حدد موقعك لعرض المواقيت';

  @override
  String get todayPrayerTimes => 'مواقيت اليوم';

  @override
  String get searchQuran => 'البحث في القرآن';

  @override
  String get searchAyah => 'ابحث عن آية';

  @override
  String get searchHint => 'يمكن البحث دون تشكيل';

  @override
  String get searchEmpty => 'لا توجد نتائج. جرّب تعديل كلمات البحث';
}
