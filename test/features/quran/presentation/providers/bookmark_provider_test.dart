import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  bookmarkV2Tests();

  test('BookmarkProvider saves and restores bookmark', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final provider = BookmarkProvider(prefs: prefs);

    await provider.saveBookmark(
      surahNumber: 2,
      surahName: 'البقرة',
      pageIndex: 5,
    );

    expect(provider.hasBookmark, isTrue);
    expect(provider.surahNumber, 2);
    expect(provider.surahName, 'البقرة');
    expect(provider.pageIndex, 5);

    final reloaded = BookmarkProvider(prefs: prefs);
    expect(reloaded.hasBookmark, isTrue);
    expect(reloaded.surahNumber, 2);
    expect(reloaded.pageIndex, 5);
  });

  test('BookmarkProvider clears persisted bookmark', () async {
    SharedPreferences.setMockInitialValues({
      'bookmark_surah_number': 2,
      'bookmark_surah_name': 'البقرة',
      'bookmark_page_index': 5,
    });
    final prefs = await SharedPreferences.getInstance();

    final provider = BookmarkProvider(prefs: prefs);
    await provider.clearBookmark();

    expect(provider.hasBookmark, isFalse);
    expect(prefs.getInt('bookmark_surah_number'), isNull);
    expect(prefs.getString('bookmark_surah_name'), isNull);
    expect(prefs.getInt('bookmark_page_index'), isNull);
  });

  test(
    'BookmarkProvider discards malformed persisted bookmark values',
    () async {
      SharedPreferences.setMockInitialValues({
        'bookmark_surah_number': 'bad-value',
        'bookmark_surah_name': 42,
        'bookmark_page_index': 'bad-page',
      });
      final prefs = await SharedPreferences.getInstance();

      final provider = BookmarkProvider(prefs: prefs);

      expect(provider.hasBookmark, isFalse);
      expect(provider.surahNumber, isNull);
      expect(provider.surahName, isNull);
      expect(provider.pageIndex, isNull);

      expect(prefs.get('bookmark_surah_number'), isNull);
      expect(prefs.getString('bookmark_surah_name'), isNull);
      expect(prefs.getInt('bookmark_page_index'), isNull);
    },
  );
}

void bookmarkV2Tests() {
  test(
    'a bookmark from an earlier version migrates once to one value',
    () async {
      SharedPreferences.setMockInitialValues({
        'bookmark_surah_number': 2,
        'bookmark_surah_name': 'البقرة',
        'bookmark_page_index': 7,
        'bookmark_ayah_number': 200,
      });
      final prefs = await SharedPreferences.getInstance();

      final provider = BookmarkProvider(prefs: prefs);
      expect(provider.surahNumber, 2);
      expect(provider.ayahNumber, 200);
      expect(prefs.getString(BookmarkProvider.storageKey), isNotNull);
      for (final key in [
        'bookmark_surah_number',
        'bookmark_surah_name',
        'bookmark_page_index',
        'bookmark_ayah_number',
      ]) {
        expect(prefs.containsKey(key), isFalse, reason: key);
      }

      final reloaded = BookmarkProvider(prefs: prefs);
      expect(reloaded.pageIndex, 7);
      expect(reloaded.ayahNumber, 200);
    },
  );

  test('a save writes a single preference value', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await BookmarkProvider(
      prefs: prefs,
    ).saveBookmark(surahNumber: 18, surahName: 'الكهف', pageIndex: 3);
    expect(prefs.getKeys(), {BookmarkProvider.storageKey});
  });

  test('out-of-range positions are never stored or restored', () async {
    SharedPreferences.setMockInitialValues({
      BookmarkProvider.storageKey:
          '{"surah": 115, "name": "x", "page": 1, "ayah": 1}',
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = BookmarkProvider(prefs: prefs);
    expect(provider.hasBookmark, isFalse);
    expect(prefs.containsKey(BookmarkProvider.storageKey), isFalse);

    await provider.saveBookmark(surahNumber: 0, surahName: 'x', pageIndex: 1);
    expect(provider.hasBookmark, isFalse);
  });

  test('an impossible ayah keeps the surah but drops the ayah', () async {
    SharedPreferences.setMockInitialValues({
      BookmarkProvider.storageKey:
          '{"surah": 1, "name": "الفاتحة", "page": 0, "ayah": 999}',
    });
    final provider = BookmarkProvider(
      prefs: await SharedPreferences.getInstance(),
    );
    expect(provider.surahNumber, 1);
    expect(provider.ayahNumber, isNull);
  });

  test('a corrupt stored value is discarded', () async {
    SharedPreferences.setMockInitialValues({
      BookmarkProvider.storageKey: 'not json',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(BookmarkProvider(prefs: prefs).hasBookmark, isFalse);
    expect(prefs.containsKey(BookmarkProvider.storageKey), isFalse);
  });
}
