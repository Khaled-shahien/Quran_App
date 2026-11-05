import 'dart:convert';

import 'package:flutter/services.dart';

import '../../quran/domain/repositories/ayah_repository.dart';
import '../../quran/domain/repositories/surah_repository.dart';
import '../domain/entities/guide_entities.dart';
import '../domain/repositories/islamic_guide_repository.dart';

typedef AssetStringLoader = Future<String> Function(String path);

class IslamicGuideRepositoryImpl implements IslamicGuideRepository {
  IslamicGuideRepositoryImpl({
    required AyahRepository ayahRepository,
    required SurahRepository surahRepository,
    AssetStringLoader? loadAsset,
  }) : _ayahRepository = ayahRepository,
       _surahRepository = surahRepository,
       _loadAsset = loadAsset ?? rootBundle.loadString;

  static const String assetPath = 'assets/islamic_guide.json';

  final AyahRepository _ayahRepository;
  final SurahRepository _surahRepository;
  final AssetStringLoader _loadAsset;
  List<GuideSection>? _cache;

  @override
  Future<List<GuideSection>> getSections() async {
    final List<GuideSection>? cached = _cache;
    if (cached != null) return cached;
    final String raw = await _loadAsset(assetPath);
    return _cache = parseGuide(raw);
  }

  @override
  Future<List<GuideVerse>> resolveQuran(QuranRef ref) async {
    final ayahs = await _ayahRepository.getAyahsForSurah(ref.surah);
    final String surahName = (await _surahRepository.getSurahByIndex(
      ref.surah,
    )).name;
    final List<GuideVerse> verses = <GuideVerse>[
      for (final ayah in ayahs)
        if (ayah.numberInSurah >= ref.from && ayah.numberInSurah <= ref.to)
          GuideVerse(
            surah: ref.surah,
            surahName: surahName,
            ayah: ayah.numberInSurah,
            text: ayah.text.replaceAll('\uFEFF', '').trim(),
          ),
    ];
    if (verses.length != ref.to - ref.from + 1) {
      throw StateError(
        'Quran reference ${ref.surah}:${ref.from}-${ref.to} is incomplete',
      );
    }
    return verses;
  }
}

/// Parses and validates the guide asset. Throws [FormatException] on any
/// structural problem so broken content never renders half-way.
List<GuideSection> parseGuide(String raw) {
  final Object? decoded = jsonDecode(raw);
  if (decoded is! Map || decoded['schemaVersion'] != 1) {
    throw const FormatException('Unsupported islamic guide schema');
  }
  final Object? sections = decoded['sections'];
  if (sections is! List || sections.isEmpty) {
    throw const FormatException('Islamic guide has no sections');
  }
  return <GuideSection>[for (final s in sections) _section(s)];
}

GuideSection _section(Object? json) {
  final Map<String, Object?> map = _map(json, 'section');
  final List<Object?> items = _list(map['items'], 'section.items');
  return GuideSection(
    id: _string(map['id'], 'section.id'),
    title: _string(map['title'], 'section.title'),
    intro: _optString(map['intro']),
    items: <GuideItem>[for (final i in items) _item(i)],
  );
}

GuideItem _item(Object? json) {
  final Map<String, Object?> map = _map(json, 'item');
  final List<Object?> blocks = _list(map['blocks'], 'item.blocks');
  return GuideItem(
    title: _string(map['title'], 'item.title'),
    subtitle: _optString(map['subtitle']),
    badges: _stringList(map['badges']),
    blocks: <GuideBlock>[for (final b in blocks) _block(b)],
  );
}

GuideBlock _block(Object? json) {
  final Map<String, Object?> map = _map(json, 'block');
  final Object? quran = map['quran'];
  final GuideBlock block = GuideBlock(
    label: _string(map['label'], 'block.label'),
    text: _optString(map['text']),
    dua: _optString(map['dua']),
    steps: _stringList(map['steps']),
    quran: quran == null
        ? const <QuranRef>[]
        : <QuranRef>[for (final r in _list(quran, 'block.quran')) _ref(r)],
    source: _optString(map['source']),
  );
  if (block.text == null &&
      block.dua == null &&
      block.steps.isEmpty &&
      block.quran.isEmpty) {
    throw FormatException('Empty guide block: ${block.label}');
  }
  return block;
}

QuranRef _ref(Object? json) {
  final Map<String, Object?> map = _map(json, 'quran ref');
  final Object? surah = map['surah'];
  final Object? from = map['from'];
  final Object? to = map['to'];
  if (surah is! int ||
      from is! int ||
      to is! int ||
      surah < 1 ||
      surah > 114 ||
      from < 1 ||
      to < from) {
    throw FormatException('Invalid quran ref: $json');
  }
  return QuranRef(surah: surah, from: from, to: to);
}

Map<String, Object?> _map(Object? value, String name) {
  if (value is! Map) throw FormatException('$name must be an object');
  return value.cast<String, Object?>();
}

List<Object?> _list(Object? value, String name) {
  if (value is! List || value.isEmpty) {
    throw FormatException('$name must be a non-empty list');
  }
  return value;
}

String _string(Object? value, String name) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$name must be a non-empty string');
  }
  return value.trim();
}

String? _optString(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Expected a string');
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _stringList(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List) throw const FormatException('Expected a list');
  return <String>[for (final v in value) _string(v, 'list entry')];
}
