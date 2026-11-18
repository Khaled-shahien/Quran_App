import 'dart:convert';

import 'package:flutter/services.dart';

/// One dhikr or dua of Hisn al-Muslim, its text exactly as bundled.
class HisnEntry {
  const HisnEntry({required this.id, required this.text, required this.repeat});

  final int id;
  final String text;

  /// How many times it is said; at least 1.
  final int repeat;
}

/// One chapter (باب) of Hisn al-Muslim.
class HisnChapter {
  const HisnChapter({
    required this.id,
    required this.title,
    required this.entries,
  });

  final int id;
  final String title;
  final List<HisnEntry> entries;
}

/// The complete Hisn al-Muslim (`assets/hisn_almuslim.json`, built by
/// `tool/build_hisn_almuslim.py` from the hisnmuslim.com Arabic API).
/// Read once and kept; a failed read is retried on the next call.
class HisnAlMuslim {
  HisnAlMuslim({Future<String> Function()? load})
    : _load = load ?? (() => rootBundle.loadString(path));

  static const String path = 'assets/hisn_almuslim.json';
  static final HisnAlMuslim bundled = HisnAlMuslim();

  final Future<String> Function() _load;
  List<HisnChapter>? _chapters;

  Future<List<HisnChapter>> chapters() async =>
      _chapters ??= parse(await _load());

  Future<HisnChapter?> chapter(int id) async {
    for (final HisnChapter c in await chapters()) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Throws [FormatException] for a damaged file rather than showing part
  /// of it.
  static List<HisnChapter> parse(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported Hisn al-Muslim file');
    }
    final Object? list = decoded['chapters'];
    if (list is! List || list.isEmpty) {
      throw const FormatException('No chapters');
    }
    return List.unmodifiable([
      for (final Object? c in list)
        if (c case {
          'id': final int id,
          'title': final String title,
          'items': final List<dynamic> items,
        })
          HisnChapter(
            id: id,
            title: title,
            entries: List.unmodifiable([
              for (final Object? i in items)
                if (i case {
                  'id': final int entryId,
                  'text': final String text,
                  'repeat': final int repeat,
                })
                  HisnEntry(
                    id: entryId,
                    text: text,
                    repeat: repeat < 1 ? 1 : repeat,
                  )
                else
                  throw const FormatException('Bad entry'),
            ]),
          )
        else
          throw const FormatException('Bad chapter'),
    ]);
  }
}
