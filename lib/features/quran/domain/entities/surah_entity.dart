import 'package:sakina_app/l10n/localization.dart';

/// Surah Entity
///
/// Domain entity representing a Surah (chapter) of the Quran
class SurahEntity {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int totalAyah;

  SurahEntity({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.totalAyah,
  });

  /// Get revelation type in Arabic
  String get revelationTypeArabic {
    if (revelationType.toLowerCase() == 'mecca') {
      return appL10n.surahModelMessage1;
    } else if (revelationType.toLowerCase() == 'medina') {
      return appL10n.surahModelMessage2;
    }
    return revelationType;
  }

  /// Check if this is a Meccan Surah
  bool get isMeccan => revelationType.toLowerCase() == 'mecca';

  /// Check if this is a Medinan Surah
  bool get isMedinan => revelationType.toLowerCase() == 'medina';

  @override
  String toString() {
    return 'SurahEntity(number: $number, name: $name, '
        'englishName: $englishName, '
        'englishNameTranslation: $englishNameTranslation, '
        'revelationType: $revelationType, totalAyah: $totalAyah)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurahEntity &&
        other.number == number &&
        other.name == name &&
        other.totalAyah == totalAyah;
  }

  @override
  int get hashCode {
    return Object.hash(number, name, totalAyah);
  }
}
