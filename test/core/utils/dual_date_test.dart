import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/utils/dual_date.dart';

void main() {
  test('formats Gregorian date and weekday in Arabic', () {
    final DualDate date = DualDate.of(DateTime(2024, 3, 11, 23, 59));
    expect(date.weekday, 'الاثنين');
    expect(date.gregorian, '11 مارس 2024م');
  });

  test('uses the Umm al-Qura calendar for known start-of-month dates', () {
    expect(DualDate.of(DateTime(2024, 3, 11)).hijri, '1 رمضان 1445هـ');
    expect(DualDate.of(DateTime(2023, 3, 23)).hijri, '1 رمضان 1444هـ');
  });

  test('offset shifts only the Hijri date', () {
    final DualDate date = DualDate.of(
      DateTime(2024, 3, 11),
      hijriOffsetDays: -1,
    );
    expect(date.hijri, '29 شعبان 1445هـ');
    expect(date.gregorian, '11 مارس 2024م');
  });

  test('dates outside the Umm al-Qura table hide the Hijri line', () {
    expect(DualDate.of(DateTime(2100, 1, 1)).hijri, isNull);
  });
}
