// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'azkar_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AzkarCategoryModel _$AzkarCategoryModelFromJson(Map<String, dynamic> json) =>
    AzkarCategoryModel(
      id: (json['id'] as num).toInt(),
      category: json['category'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => AzkarItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AzkarCategoryModelToJson(AzkarCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

AzkarItemModel _$AzkarItemModelFromJson(Map<String, dynamic> json) =>
    AzkarItemModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      text: json['text'] as String,
      repeat: (json['repeat'] as num?)?.toInt() ?? 1,
      reference: json['reference'] as String? ?? '',
      instructionBefore: json['instructionBefore'] as String? ?? '',
      instructionAfter: json['instructionAfter'] as String? ?? '',
    );

Map<String, dynamic> _$AzkarItemModelToJson(AzkarItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'text': instance.text,
      'repeat': instance.repeat,
      'reference': instance.reference,
      'instructionBefore': instance.instructionBefore,
      'instructionAfter': instance.instructionAfter,
    };
