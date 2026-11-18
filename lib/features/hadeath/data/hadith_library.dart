import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../quran/domain/services/quran_search.dart';
import '../domain/entities/hadeath_entity.dart';

/// A topic of the encyclopedia (e.g. creed > faith in the unseen).
class HadithTopic {
  const HadithTopic({required this.id, required this.title, this.parent});

  final int id;
  final String title;
  final int? parent;
}

/// One hadith of the encyclopedia, its fields as published.
class HadithLibraryItem {
  const HadithLibraryItem({
    required this.id,
    required this.title,
    required this.hadeeth,
    required this.grade,
    required this.topics,
    this.attribution = '',
    this.explanation = '',
    this.reference = '',
    this.hints = const [],
  });

  final int id;
  final String title;
  final String hadeeth;
  final String grade;
  final String attribution;
  final String explanation;
  final String reference;
  final List<String> hints;
  final List<int> topics;

  /// The shape the hadith details screen shows.
  HadeathEntity toEntity() => HadeathEntity(
    title: title,
    content: [hadeeth],
    study: HadeathStudy(
      sourceId: '$id',
      grade: grade,
      attribution: attribution,
      explanation: explanation,
      reference: reference,
      hints: hints,
    ),
  );
}

/// The Arabic HadeethEnc encyclopedia bundled in
/// `assets/hadeath/hadeethenc_library.json` (built by
/// tool/build_hadith_library.py). Parsed once, off the UI thread.
class HadithLibrary {
  HadithLibrary._(this.topics, this.items)
    : _byTopic = _index(topics, items),
      _search = [
        for (final i in items) NormalizedText('${i.title}\n${i.hadeeth}'),
      ];

  static const String path = 'assets/hadeath/hadeethenc_library.json';
  static Future<HadithLibrary>? _loading;

  final List<HadithTopic> topics;
  final List<HadithLibraryItem> items;
  final Map<int, List<int>> _byTopic;
  final List<NormalizedText> _search;

  static Future<HadithLibrary> load({AssetBundle? bundle}) {
    if (bundle != null) return _read(bundle);
    return _loading ??= _read(rootBundle).catchError((Object e) {
      _loading = null;
      throw e;
    });
  }

  @visibleForTesting
  static void resetForTesting() => _loading = null;

  /// Parses [raw] on this thread (tests and small samples).
  @visibleForTesting
  static HadithLibrary parseNow(String raw) {
    final parsed = _parse(raw);
    return HadithLibrary._(parsed.$1, parsed.$2);
  }

  static Future<HadithLibrary> _read(AssetBundle bundle) async {
    final raw = await bundle.loadString(path, cache: false);
    final parsed = await compute(_parse, raw);
    return HadithLibrary._(parsed.$1, parsed.$2);
  }

  static (List<HadithTopic>, List<HadithLibraryItem>) _parse(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final topics = [
      for (final t in (decoded['topics'] as List).cast<Map<String, dynamic>>())
        HadithTopic(
          id: t['id'] as int,
          title: t['title'] as String,
          parent: t['parent'] as int?,
        ),
    ];
    final items = [
      for (final i in (decoded['items'] as List).cast<Map<String, dynamic>>())
        HadithLibraryItem(
          id: i['id'] as int,
          title: i['title'] as String,
          hadeeth: i['hadeeth'] as String,
          grade: i['grade'] as String,
          attribution: i['attribution'] as String? ?? '',
          explanation: i['explanation'] as String? ?? '',
          reference: i['reference'] as String? ?? '',
          hints: ((i['hints'] as List?) ?? const []).cast<String>(),
          topics: ((i['topics'] as List?) ?? const []).cast<int>(),
        ),
    ];
    return (topics, items);
  }

  /// Item indexes under each topic, its subtopics included.
  static Map<int, List<int>> _index(
    List<HadithTopic> topics,
    List<HadithLibraryItem> items,
  ) {
    final parent = {for (final t in topics) t.id: t.parent};
    final out = <int, Set<int>>{};
    for (final (i, item) in items.indexed) {
      for (final topic in item.topics) {
        int? t = topic;
        var guard = 0;
        while (t != null && guard++ < 20) {
          (out[t] ??= {}).add(i);
          t = parent[t];
        }
      }
    }
    return {for (final e in out.entries) e.key: e.value.toList()..sort()};
  }

  List<HadithTopic> childrenOf(int? parent) => [
    for (final t in topics)
      if (t.parent == parent && (_byTopic[t.id]?.isNotEmpty ?? false)) t,
  ];

  int countIn(int topic) => _byTopic[topic]?.length ?? 0;

  /// The hadith filed directly or below [topic].
  List<HadithLibraryItem> itemsIn(int topic) => [
    for (final i in _byTopic[topic] ?? const <int>[]) items[i],
  ];

  /// Hadith whose title or text contains [query] (marks ignored).
  List<HadithLibraryItem> search(String query, {int limit = 100}) {
    final out = <HadithLibraryItem>[];
    for (final (i, text) in _search.indexed) {
      if (text.find(query) != null) out.add(items[i]);
      if (out.length >= limit) break;
    }
    return out;
  }
}
