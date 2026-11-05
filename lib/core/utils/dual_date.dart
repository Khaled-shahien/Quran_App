import 'package:hijri/hijri_calendar.dart';

/// Hijri (Umm al-Qura) and Gregorian representations of one civil day.
///
/// Month and weekday names are kept here rather than read from
/// [HijriCalendar.language], which is mutable global state.
class DualDate {
  const DualDate({
    required this.weekday,
    required this.gregorian,
    required this.hijri,
  });

  /// e.g. `الخميس`
  final String weekday;

  /// e.g. `5 نوفمبر 2026م`
  final String gregorian;

  /// e.g. `14 جمادى الأولى 1448هـ`, or null when the date is outside the
  /// Umm al-Qura table (1356–1500 AH).
  final String? hijri;

  /// [hijriOffsetDays] lets a later setting shift the Hijri date to match a
  /// local moon sighting.
  factory DualDate.of(DateTime date, {int hijriOffsetDays = 0}) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return DualDate(
      weekday: _weekdays[day.weekday - 1],
      gregorian: '${day.day} ${_gregorianMonths[day.month - 1]} ${day.year}م',
      hijri: _hijri(day.add(Duration(days: hijriOffsetDays))),
    );
  }

  static String? _hijri(DateTime day) {
    try {
      final HijriCalendar h = HijriCalendar.fromDate(day);
      if (h.hMonth < 1 || h.hMonth > 12) return null;
      return '${h.hDay} ${_hijriMonths[h.hMonth - 1]} ${h.hYear}هـ';
    } on ArgumentError {
      return null;
    }
  }
}

const List<String> _weekdays = <String>[
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> _gregorianMonths = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> _hijriMonths = <String>[
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];
