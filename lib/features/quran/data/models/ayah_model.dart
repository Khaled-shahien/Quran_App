import 'package:json_annotation/json_annotation.dart';

part 'ayah_model.g.dart';

/// Ayah Model
///
/// Represents a single Ayah (verse) of the Quran with all its metadata
@JsonSerializable()
class AyahModel {
  @JsonKey(defaultValue: 0)
  final int number;

  @JsonKey(defaultValue: '')
  final String text;

  @JsonKey(defaultValue: 0)
  final int numberInSurah;

  @JsonKey(defaultValue: 0)
  final int juz;

  @JsonKey(defaultValue: 0)
  final int manzil;

  @JsonKey(defaultValue: 0)
  final int page;

  @JsonKey(defaultValue: 0)
  final int ruku;

  @JsonKey(defaultValue: 0)
  final int hizbQuarter;

  @JsonKey(defaultValue: false, fromJson: _sajdaFromJson, toJson: _sajdaToJson)
  final bool sajda;

  AyahModel({
    this.number = 0,
    required this.text,
    this.numberInSurah = 0,
    this.juz = 0,
    this.manzil = 0,
    this.page = 0,
    this.ruku = 0,
    this.hizbQuarter = 0,
    this.sajda = false,
  });

  /// Creates an AyahModel from JSON
  factory AyahModel.fromJson(Map<String, dynamic> json) =>
      _$AyahModelFromJson(json);

  /// Converts AyahModel to JSON
  Map<String, dynamic> toJson() => _$AyahModelToJson(this);

  static bool _sajdaFromJson(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is Map || value is List) {
      return true;
    }
    return false;
  }

  static Object _sajdaToJson(bool value) => value;

  @override
  String toString() {
    return 'AyahModel('
        'number: $number, text: $text, numberInSurah: $numberInSurah, '
        'juz: $juz, manzil: $manzil, page: $page, ruku: $ruku, '
        'hizbQuarter: $hizbQuarter, sajda: $sajda)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AyahModel &&
        other.number == number &&
        other.text == text &&
        other.numberInSurah == numberInSurah;
  }

  @override
  int get hashCode {
    return Object.hash(number, text, numberInSurah);
  }
}
