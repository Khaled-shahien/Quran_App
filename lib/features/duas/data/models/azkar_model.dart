import 'package:json_annotation/json_annotation.dart';

part 'azkar_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AzkarCategoryModel {
  final int id;
  final String category;

  @JsonKey(defaultValue: <AzkarItemModel>[])
  final List<AzkarItemModel> items;

  AzkarCategoryModel({
    required this.id,
    required this.category,
    required this.items,
  });

  factory AzkarCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$AzkarCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$AzkarCategoryModelToJson(this);
}

@JsonSerializable()
class AzkarItemModel {
  final int id;
  final String title;
  final String text;

  @JsonKey(defaultValue: 1)
  final int repeat;

  @JsonKey(defaultValue: '')
  final String reference;

  /// Guidance printed in the source before the dhikr (e.g. which foot to
  /// enter with). Shown separately so it is not recited as part of it.
  @JsonKey(defaultValue: '')
  final String instructionBefore;

  /// Guidance printed after the dhikr (e.g. "three times").
  @JsonKey(defaultValue: '')
  final String instructionAfter;

  AzkarItemModel({
    required this.id,
    required this.title,
    required this.text,
    required this.repeat,
    required this.reference,
    this.instructionBefore = '',
    this.instructionAfter = '',
  });

  factory AzkarItemModel.fromJson(Map<String, dynamic> json) =>
      _$AzkarItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$AzkarItemModelToJson(this);
}
