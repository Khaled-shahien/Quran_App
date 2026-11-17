import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single reading bookmark.
///
/// Stored as one JSON value ([storageKey]) so it is always written whole:
/// a process killed mid-save can no longer leave a surah from one bookmark
/// with the page of another. Bookmarks saved by earlier versions under four
/// separate keys are migrated once, on first load.
class BookmarkProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  static const String storageKey = 'bookmark_v2';

  // Earlier versions (read once for migration, then removed).
  static const String _surahNumberKey = 'bookmark_surah_number';
  static const String _surahNameKey = 'bookmark_surah_name';
  static const String _pageIndexKey = 'bookmark_page_index';
  static const String _ayahKey = 'bookmark_ayah_number';
  static const List<String> _legacyKeys = [
    _surahNumberKey,
    _surahNameKey,
    _pageIndexKey,
    _ayahKey,
  ];

  /// The longest surah (Al-Baqarah) has 286 ayahs.
  static const int _maxAyah = 286;

  int? _surahNumber;
  String? _surahName;
  int? _pageIndex;
  int? _ayahNumber;

  BookmarkProvider({required this.prefs}) {
    _loadBookmark();
  }

  int? get surahNumber => _surahNumber;
  String? get surahName => _surahName;
  int? get pageIndex => _pageIndex;

  /// The bookmarked verse. Null for bookmarks saved before the reader
  /// stored verses; those only have [pageIndex] under the old pagination.
  int? get ayahNumber => _ayahNumber;

  bool get hasBookmark => _surahNumber != null && _pageIndex != null;

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _validSurah(int? n) => n != null && n >= 1 && n <= 114;
  static bool _validPage(int? n) => n != null && n >= 0;
  static bool _validAyah(int? n) => n == null || (n >= 1 && n <= _maxAyah);

  void _apply({
    required int? surah,
    required Object? name,
    required int? page,
    required int? ayah,
  }) {
    final label = name is String && name.trim().isNotEmpty ? name : null;
    if (_validSurah(surah) && _validPage(page) && label != null) {
      _surahNumber = surah;
      _surahName = label;
      _pageIndex = page;
      _ayahNumber = _validAyah(ayah) ? ayah : null;
    } else {
      _surahNumber = _surahName = _pageIndex = _ayahNumber = null;
    }
  }

  void _loadBookmark() {
    final stored = prefs.get(storageKey);
    if (stored is String) {
      try {
        final map = jsonDecode(stored) as Map<String, dynamic>;
        _apply(
          surah: _int(map['surah']),
          name: map['name'],
          page: _int(map['page']),
          ayah: _int(map['ayah']),
        );
      } catch (_) {
        _apply(surah: null, name: null, page: null, ayah: null);
      }
      if (!hasBookmark) prefs.remove(storageKey);
    } else {
      if (stored != null) prefs.remove(storageKey);
      _migrateLegacy();
    }
    notifyListeners();
  }

  void _migrateLegacy() {
    if (!_legacyKeys.any(prefs.containsKey)) return;
    _apply(
      surah: _int(prefs.get(_surahNumberKey)),
      name: prefs.get(_surahNameKey),
      page: _int(prefs.get(_pageIndexKey)),
      ayah: _int(prefs.get(_ayahKey)),
    );
    // Platform writes run in call order: the new value is stored before the
    // old keys go, so an interrupted migration is repeated next launch.
    if (hasBookmark) prefs.setString(storageKey, _encode());
    for (final key in _legacyKeys) {
      prefs.remove(key);
    }
  }

  String _encode() => jsonEncode({
    'surah': _surahNumber,
    'name': _surahName,
    'page': _pageIndex,
    if (_ayahNumber != null) 'ayah': _ayahNumber,
  });

  Future<void> saveBookmark({
    required int surahNumber,
    required String surahName,
    required int pageIndex,
    int? ayahNumber,
  }) async {
    if (!_validSurah(surahNumber) ||
        !_validPage(pageIndex) ||
        surahName.trim().isEmpty ||
        !_validAyah(ayahNumber)) {
      // Called unawaited from the reader: an impossible position is
      // dropped rather than thrown, and the previous bookmark is kept.
      developer.log(
        'Ignored invalid bookmark position',
        name: 'sakina_app.bookmark',
      );
      return;
    }
    _surahNumber = surahNumber;
    _surahName = surahName;
    _pageIndex = pageIndex;
    _ayahNumber = ayahNumber;

    await prefs.setString(storageKey, _encode());

    notifyListeners();
  }

  Future<void> clearBookmark() async {
    _surahNumber = null;
    _surahName = null;
    _pageIndex = null;
    _ayahNumber = null;

    await prefs.remove(storageKey);
    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }

    notifyListeners();
  }
}
