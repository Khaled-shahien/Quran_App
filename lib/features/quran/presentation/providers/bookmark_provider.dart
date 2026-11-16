import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  static const String _surahNumberKey = 'bookmark_surah_number';
  static const String _surahNameKey = 'bookmark_surah_name';
  static const String _pageIndexKey = 'bookmark_page_index';
  static const String _ayahKey = 'bookmark_ayah_number';

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

  int? _validatedInt(String key) {
    final value = prefs.get(key);

    if (value is int) {
      return value;
    }

    if (value is num && value.isFinite) {
      final parsed = value.toInt();
      prefs.setInt(key, parsed);
      return parsed;
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        prefs.setInt(key, parsed);
        return parsed;
      }
    }

    prefs.remove(key);
    return null;
  }

  String? _validatedString(String key) {
    final value = prefs.get(key);

    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    prefs.remove(key);
    return null;
  }

  void _loadBookmark() {
    _surahNumber = _validatedInt(_surahNumberKey);
    _surahName = _validatedString(_surahNameKey);
    _pageIndex = _validatedInt(_pageIndexKey);
    _ayahNumber = prefs.containsKey(_ayahKey) ? _validatedInt(_ayahKey) : null;

    if (_surahNumber == null || _pageIndex == null) {
      _surahName = null;
      prefs.remove(_surahNameKey);
    }

    notifyListeners();
  }

  Future<void> saveBookmark({
    required int surahNumber,
    required String surahName,
    required int pageIndex,
    int? ayahNumber,
  }) async {
    _surahNumber = surahNumber;
    _surahName = surahName;
    _pageIndex = pageIndex;
    _ayahNumber = ayahNumber;

    await prefs.setInt(_surahNumberKey, surahNumber);
    await prefs.setString(_surahNameKey, surahName);
    await prefs.setInt(_pageIndexKey, pageIndex);
    if (ayahNumber != null) {
      await prefs.setInt(_ayahKey, ayahNumber);
    } else {
      await prefs.remove(_ayahKey);
    }

    notifyListeners();
  }

  Future<void> clearBookmark() async {
    _surahNumber = null;
    _surahName = null;
    _pageIndex = null;
    _ayahNumber = null;

    await prefs.remove(_ayahKey);
    await prefs.remove(_surahNumberKey);
    await prefs.remove(_surahNameKey);
    await prefs.remove(_pageIndexKey);

    notifyListeners();
  }
}
