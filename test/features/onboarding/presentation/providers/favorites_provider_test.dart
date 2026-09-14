import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/features/onboarding/presentation/providers/favorites_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FavoritesProvider toggles and persists verse favorites', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = FavoritesProvider(prefs: prefs);

    final verse = <String, String>{
      'arabic': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً',
      'translation': 'Our Lord, give us in this world good',
    };

    expect(provider.isFavorite(verse), isFalse);

    await provider.toggleFavorite(verse);
    expect(provider.isFavorite(verse), isTrue);

    await provider.toggleFavorite(verse);
    expect(provider.isFavorite(verse), isFalse);
  });

  test('FavoritesProvider removes existing favorite', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_verses': '[{"arabic":"abc","translation":"def"}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = FavoritesProvider(prefs: prefs);

    final verse = <String, String>{'arabic': 'abc', 'translation': 'def'};
    expect(provider.isFavorite(verse), isTrue);

    await provider.removeFavorite(verse);

    expect(provider.isFavorite(verse), isFalse);
    expect(provider.favoriteVerses, isEmpty);
  });
}
