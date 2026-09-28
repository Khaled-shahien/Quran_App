import 'package:sakina_app/l10n/localization.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ayah_model.dart';

part 'surah_model.g.dart';

/// Surah Model
///
/// Represents a single Surah (chapter) of the Quran with all its metadata
// TODO: Verify JSON field casing
@JsonSerializable(explicitToJson: true)
class SurahModel {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;

  @JsonKey(defaultValue: <AyahModel>[])
  final List<AyahModel> ayahs;

  SurahModel({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  /// Creates a SurahModel from JSON
  factory SurahModel.fromJson(Map<String, dynamic> json) =>
      _$SurahModelFromJson(json);

  /// Converts SurahModel to JSON
  Map<String, dynamic> toJson() => _$SurahModelToJson(this);

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

  /// Getter aliases for compatibility
  String get surahName => englishName;
  String get surahNameArabic => name;
  String get surahNameTranslation => englishNameTranslation;
  String get surahNameArabicLong => name; // Using the same Arabic name
  int get totalAyah => numberOfAyahs;
  String get revelationPlace => revelationType;

  @override
  String toString() {
    return 'SurahModel(number: $number, name: $name, '
        'englishName: $englishName, '
        'englishNameTranslation: $englishNameTranslation, '
        'revelationType: $revelationType, numberOfAyahs: $numberOfAyahs)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SurahModel &&
        other.number == number &&
        other.name == name &&
        other.numberOfAyahs == numberOfAyahs;
  }

  @override
  int get hashCode {
    return Object.hash(number, name, numberOfAyahs);
  }
}
