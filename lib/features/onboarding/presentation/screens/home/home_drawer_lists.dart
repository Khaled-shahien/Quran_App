part of '../home_screen.dart';

/// Settings and favourites lists shown in the home side menu.
extension _HomeDrawerLists on _HomeScreenState {
  Widget _buildSettingsList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    void showComingSoon() {
      _showOverlayMessage(appL10n.homeScreenMessage24);
    }

    final Color iconColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _buildMoreMenuItem(
          title: appL10n.appStringsMessage16,
          leadingIcon: Icon(Icons.settings_outlined, color: iconColor),
          onTap: () {
            Navigator.pop(context);
            context.push('/settings');
          },
        ),
        // 2. الختمة الحالية
        _buildSectionHeader(appL10n.appRouterMessage1),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage9,
          leadingIcon: Icon(Icons.history, color: iconColor),
          onTap: () => _showKhatmaWirdSheet(showCompleted: true),
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage10,
          leadingIcon: Icon(Icons.next_plan_outlined, color: iconColor),
          onTap: () => _showKhatmaWirdSheet(showCompleted: false),
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage26,
          leadingIcon: Icon(Icons.bookmark_border, color: iconColor),
          onTap: _openSavedBookmark,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage35,
          leadingIcon: Icon(Icons.add, color: iconColor),
          onTap: () => context.push('/khatma/location'),
        ),
        const Divider(height: 1),

        // 3. كل الوسائط
        _buildSectionHeader(appL10n.homeScreenMessage27),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage28,
          leadingIcon: Icon(Icons.video_library, color: iconColor),
          onTap: () => context.push('/media'),
        ),
        const Divider(height: 1),

        // 4. سنن قرآنية
        _buildSectionHeader(appL10n.homeScreenMessage29),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage30,
          leadingIcon: Icon(Icons.book, color: iconColor),
          onTap: () {
            context.push(
              '/quran/surah/18',
              extra: <String, dynamic>{
                'surah': SurahEntity(
                  number: 18,
                  name: appL10n.homeScreenMessage30,
                  englishName: 'Al-Kahf',
                  englishNameTranslation: 'The Cave',
                  revelationType: 'Meccan',
                  totalAyah: 110,
                ),
              },
            );
          },
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage31,
          leadingIcon: Icon(Icons.menu_book, color: iconColor),
          onTap: () {
            context.push(
              '/quran/surah/67',
              extra: <String, dynamic>{
                'surah': SurahEntity(
                  number: 67,
                  name: appL10n.homeScreenMessage31,
                  englishName: 'Al-Mulk',
                  englishNameTranslation: 'The Sovereignty',
                  revelationType: 'Meccan',
                  totalAyah: 30,
                ),
              },
            );
          },
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage32,
          leadingIcon: Icon(Icons.auto_stories, color: iconColor),
          onTap: () {
            context.push(
              '/quran/surah/2',
              extra: <String, dynamic>{
                'surah': SurahEntity(
                  number: 2,
                  name: appL10n.homeScreenMessage32,
                  englishName: 'Al-Baqarah',
                  englishNameTranslation: 'The Cow',
                  revelationType: 'Medinan',
                  totalAyah: 286,
                ),
              },
            );
          },
        ),
        const Divider(height: 1),

        // 6. الصلاة (prayer times open from the home header only)
        _buildSectionHeader(appL10n.drawerPrayerSection),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage37,
          leadingIcon: Image.asset(
            'assets/images/kaaba.png',
            width: 24,
            height: 24,
            color: isDark ? Colors.white : null,
            errorBuilder: (c, e, s) => Icon(Icons.explore, color: iconColor),
          ),
          onTap: () {
            Navigator.pop(context);
            context.push('/qibla');
          },
        ),
        const Divider(height: 1),

        // 9. تطبيق سكينة
        _buildSectionHeader(appL10n.homeScreenMessage48),
        _buildMoreMenuItem(
          title: appL10n.appStringsMessage6,
          leadingIcon: Icon(Icons.home_outlined, color: iconColor),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage49,
          leadingIcon: Icon(Icons.settings, color: iconColor),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(
                appL10n.homeScreenMessage50,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              content: Text(
                appL10n.homeScreenMessage51,
                style: const TextStyle(),
                textAlign: TextAlign.right,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    appL10n.appStringsMessage8,
                    style: const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage52,
          leadingIcon: Icon(Icons.info_outline, color: iconColor),
          onTap: showComingSoon,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage54,
          leadingIcon: const Icon(
            Icons.flutter_dash,
            color: Colors.lightBlue,
          ), // Placeholder for Twitter
          onTap: showComingSoon,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage55,
          leadingIcon: const Icon(
            Icons.camera_alt,
            color: Colors.purple,
          ), // Placeholder for Instagram
          onTap: showComingSoon,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage56,
          leadingIcon: Icon(Icons.share, color: iconColor),
          onTap: showComingSoon,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage58,
          leadingIcon: Icon(Icons.thumb_up_alt_outlined, color: iconColor),
          onTap: showComingSoon,
        ),
      ],
    );
  }

  Widget _buildFavoritesList() {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final favorites = favoritesProvider.favoriteVerses;

        if (favorites.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_outline,
            message: l10nOf(context).homeScreenMessage59,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final verse = favorites[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Full 48dp target; the icon stays small.
                      IconButton(
                        tooltip: l10nOf(context).homeScreenMessage60,
                        icon: Icon(
                          Icons.cancel,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () {
                          favoritesProvider.removeFavorite(verse);
                        },
                      ),
                      Expanded(
                        child: Text(
                          verse['arabic'] ?? '',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse['surah'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  if (verse['english'] != null)
                    Text(
                      verse['english']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.left,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
