import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
