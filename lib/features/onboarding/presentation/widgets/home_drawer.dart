import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../khatma/domain/models/khatma_model.dart';
import '../../../khatma/domain/services/khatma_quran_locator.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';
import '../../../quran/domain/entities/surah_entity.dart';
import '../../../quran/domain/repositories/surah_repository.dart';
import '../../../quran/presentation/providers/bookmark_provider.dart';
import '../providers/favorites_provider.dart';

part 'home_khatma_actions.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});
  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> with _HomeKhatmaActions {
  bool _favorites = false;
  void _open(String route) {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push(route);
  }

  Widget _link(String title, IconData icon, String route) => ListTile(
    title: Text(title),
    leading: Icon(icon),
    onTap: () => _open(route),
  );

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          ListTile(
            title: Text(
              l10nOf(context).appConstantsMessage1,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            trailing: IconButton(
              tooltip: l10nOf(context).homeDrawerMessage1,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10nOf(context).homeScreenMessage3),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10nOf(context).homeScreenMessage4),
                ),
              ],
              selected: {_favorites},
              onSelectionChanged: (value) =>
                  setState(() => _favorites = value.single),
            ),
          ),
          Expanded(
            child: _favorites
                ? _buildFavorites()
                : ListView(
                    children: [
                      _link(
                        l10nOf(context).appStringsMessage16,
                        Icons.settings_outlined,
                        '/settings',
                      ),
                      ListTile(title: Text(l10nOf(context).appRouterMessage1)),
                      ListTile(
                        title: Text(l10nOf(context).homeScreenMessage9),
                        leading: const Icon(Icons.history),
                        onTap: () => _showKhatmaWirdSheet(showCompleted: true),
                      ),
                      ListTile(
                        title: Text(l10nOf(context).homeScreenMessage10),
                        leading: const Icon(Icons.next_plan_outlined),
                        onTap: () => _showKhatmaWirdSheet(showCompleted: false),
                      ),
                      ListTile(
                        title: Text(l10nOf(context).homeScreenMessage26),
                        leading: const Icon(Icons.bookmark_border),
                        onTap: () {
                          final bookmark = context.read<BookmarkProvider>();
                          _open(
                            bookmark.hasBookmark
                                ? '/quran/surah/${bookmark.surahNumber}'
                                : '/quran',
                          );
                        },
                      ),
                      _link(
                        l10nOf(context).homeScreenMessage35,
                        Icons.add,
                        '/khatma/location',
                      ),
                      const Divider(),
                      _link(
                        l10nOf(context).homeScreenMessage28,
                        Icons.video_library_outlined,
                        '/media',
                      ),
                      _link(
                        l10nOf(context).homeScreenMessage30,
                        Icons.menu_book,
                        '/quran/surah/18',
                      ),
                      _link(
                        l10nOf(context).homeScreenMessage31,
                        Icons.menu_book,
                        '/quran/surah/67',
                      ),
                      _link(
                        l10nOf(context).homeScreenMessage32,
                        Icons.menu_book,
                        '/quran/surah/2',
                      ),
                      _link(
                        l10nOf(context).homeScreenMessage36,
                        Icons.mosque_outlined,
                        '/prayers',
                      ),
                      _link(
                        l10nOf(context).homeScreenMessage37,
                        Icons.explore_outlined,
                        '/qibla',
                      ),
                      _link(
                        l10nOf(context).homeScreenMessage25,
                        Icons.privacy_tip_outlined,
                        '/settings/data-sources',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFavorites() => Consumer<FavoritesProvider>(
    builder: (context, provider, _) {
      if (provider.favoriteVerses.isEmpty) {
        return Center(child: Text(l10nOf(context).homeScreenMessage59));
      }
      return ListView.builder(
        itemCount: provider.favoriteVerses.length,
        itemBuilder: (context, index) {
          final verse = provider.favoriteVerses[index];
          return ListTile(
            title: Text(
              verse['arabic'] ?? '',
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 22),
            ),
            subtitle: Text(verse['surah'] ?? ''),
            trailing: IconButton(
              tooltip: l10nOf(context).homeScreenMessage60,
              icon: const Icon(Icons.favorite),
              onPressed: () => provider.removeFavorite(verse),
            ),
          );
        },
      );
    },
  );
}
