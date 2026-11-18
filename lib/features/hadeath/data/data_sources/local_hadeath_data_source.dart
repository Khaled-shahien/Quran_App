import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/hadeath_entity.dart';
import '../models/hadeath_model.dart';

class LocalHadeathDataSource {
  LocalHadeathDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _assetPath = 'assets/hadeath/ahadeth.txt';
  static const String studyPath = 'assets/hadeath/hadeethenc_nawawi.json';

  /// The fifty hadith in order. Each takes its text and study material
  /// from HadeethEnc when the study file has it, and keeps the bundled
  /// transcription otherwise.
  Future<List<HadeathModel>> loadAhadeth() async {
    try {
      final String fileContent = await _bundle.loadString(_assetPath);
      final List<HadeathModel> ahadethList = [
        for (final raw in fileContent.split('#'))
          if (raw.trim().isNotEmpty) HadeathModel.fromString(raw),
      ];
      final Map<int, ({String text, HadeathStudy study})> study =
          await _loadStudy();
      return [
        for (final (i, h) in ahadethList.indexed)
          if (study[i + 1] case final s?)
            HadeathModel(title: h.title, content: [s.text], study: s.study)
          else
            h,
      ];
    } catch (e) {
      throw Exception('Failed to load ahadeth data: $e');
    }
  }

  Future<Map<int, ({String text, HadeathStudy study})>> _loadStudy() async {
    final Object? decoded = jsonDecode(await _bundle.loadString(studyPath));
    final out = <int, ({String text, HadeathStudy study})>{};
    if (decoded is! Map || decoded['items'] is! List) return out;
    for (final Object? item in decoded['items'] as List) {
      if (item is! Map) continue;
      final number = item['number'];
      final fields = [
        for (final key in const [
          'id',
          'hadeeth',
          'grade',
          'attribution',
          'explanation',
          'reference',
        ])
          item[key],
      ];
      if (number is! int || fields.any((f) => f is! String || f.isEmpty)) {
        continue;
      }
      final hints = item['hints'];
      out[number] = (
        text: item['hadeeth'] as String,
        study: HadeathStudy(
          sourceId: item['id'] as String,
          grade: item['grade'] as String,
          attribution: item['attribution'] as String,
          explanation: item['explanation'] as String,
          reference: item['reference'] as String,
          hints: hints is List ? hints.whereType<String>().toList() : const [],
        ),
      );
    }
    return out;
  }
}
