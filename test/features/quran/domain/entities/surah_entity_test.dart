import 'package:flutter_test/flutter_test.dart';

import 'package:sakina_app/features/quran/domain/entities/surah_entity.dart';

void main() {
  test('SurahEntity exposes Arabic revelation labels and flags', () {
    final meccan = SurahEntity(
      number: 1,
      name: 'الفاتحة',
      englishName: 'Al-Fatiha',
      englishNameTranslation: 'The Opening',
      revelationType: 'mecca',
      totalAyah: 7,
    );

    final medinan = SurahEntity(
      number: 2,
      name: 'البقرة',
      englishName: 'Al-Baqara',
      englishNameTranslation: 'The Cow',
      revelationType: 'medina',
      totalAyah: 286,
    );

    expect(meccan.revelationTypeArabic, 'مكة');
    expect(meccan.isMeccan, isTrue);
    expect(meccan.isMedinan, isFalse);

    expect(medinan.revelationTypeArabic, 'المدينة');
    expect(medinan.isMedinan, isTrue);
    expect(medinan.isMeccan, isFalse);
  });

  test('SurahEntity equality and hashCode use number, name, totalAyah', () {
    final a = SurahEntity(
      number: 18,
      name: 'الكهف',
      englishName: 'Al-Kahf',
      englishNameTranslation: 'The Cave',
      revelationType: 'mecca',
      totalAyah: 110,
    );
    final b = SurahEntity(
      number: 18,
      name: 'الكهف',
      englishName: 'Different',
      englishNameTranslation: 'Different',
      revelationType: 'medina',
      totalAyah: 110,
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a.toString(), contains('SurahEntity(number: 18'));
  });
}
