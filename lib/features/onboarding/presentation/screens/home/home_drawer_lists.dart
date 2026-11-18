part of '../home_screen.dart';

/// Settings and favourites lists shown in the home side menu.
extension _HomeDrawerLists on _HomeScreenState {
  Widget _buildSettingsList() {
    void showComingSoon() {
      _showOverlayMessage(appL10n.homeScreenMessage24);
    }

    final Color iconColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
          leadingIcon: Icon(Icons.history_rounded, color: iconColor),
          onTap: () => _showKhatmaWirdSheet(showCompleted: true),
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage10,
          leadingIcon: Icon(Icons.next_plan_outlined, color: iconColor),
          onTap: () => _showKhatmaWirdSheet(showCompleted: false),
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage26,
          leadingIcon: Icon(Icons.bookmark_outline_rounded, color: iconColor),
          onTap: _openSavedBookmark,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage35,
          leadingIcon: Icon(Icons.add_rounded, color: iconColor),
          onTap: () => context.push('/khatma/location'),
        ),

        // 3. كل الوسائط
        _buildSectionHeader(appL10n.homeScreenMessage27),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage28,
          leadingIcon: Icon(Icons.video_library_outlined, color: iconColor),
          onTap: () => context.push('/media'),
        ),

        // 4. سنن قرآنية
        _buildSectionHeader(appL10n.homeScreenMessage29),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage30,
          leadingIcon: Icon(Icons.book_outlined, color: iconColor),
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
          leadingIcon: Icon(Icons.menu_book_outlined, color: iconColor),
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
          leadingIcon: Icon(Icons.auto_stories_outlined, color: iconColor),
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

        // 6. الصلاة (prayer times open from the home header only)
        _buildSectionHeader(appL10n.drawerPrayerSection),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage37,
          leadingIcon: Icon(Icons.explore_outlined, color: iconColor),
          onTap: () {
            Navigator.pop(context);
            context.push('/qibla');
          },
        ),

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
          title: appL10n.homeScreenMessage52,
          leadingIcon: Icon(Icons.mail_outline_rounded, color: iconColor),
          onTap: showComingSoon,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage54,
          leadingIcon: Icon(Icons.alternate_email_rounded, color: iconColor),
          onTap: showComingSoon,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage55,
          leadingIcon: Icon(Icons.photo_camera_outlined, color: iconColor),
          onTap: showComingSoon,
        ),
        _buildMoreMenuItem(
          title: appL10n.homeScreenMessage56,
          leadingIcon: Icon(Icons.share_outlined, color: iconColor),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final verse = favorites[index];
            final text = Theme.of(context).textTheme;
            final scheme = Theme.of(context).colorScheme;
            return SakinaCard(
              tone: SakinaCardTone.tinted,
              margin: const EdgeInsets.only(bottom: AppSpacing.ms),
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.ms),
                          child: Text(
                            verse['arabic'] ?? '',
                            style: AppTypography.script.copyWith(
                              fontSize: 19,
                              color: scheme.onSecondary,
                            ),
                          ),
                        ),
                      ),
                      // Full 48dp target; the icon stays small.
                      IconButton(
                        tooltip: l10nOf(context).homeScreenMessage60,
                        icon: Icon(
                          Icons.close_rounded,
                          color: scheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          playFeedback(context, FeedbackEvent.favorite);
                          favoritesProvider.removeFavorite(verse);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    verse['surah'] ?? '',
                    style: text.labelMedium?.copyWith(color: scheme.primary),
                  ),
                  if (verse['english'] != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        verse['english']!,
                        textDirection: TextDirection.ltr,
                        style: text.bodySmall,
                      ),
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
