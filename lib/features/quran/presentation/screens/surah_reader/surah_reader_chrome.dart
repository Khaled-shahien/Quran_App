part of '../surah_details_screen.dart';

/// App bar and bottom page navigation of the reader.
extension _SurahReaderChrome on _SurahDetailsScreenState {
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final Color primary = theme.colorScheme.primary;
    final _SurahVerseData? currentVerse = _hasUnitRange
        ? _currentPageLeadVerse
        : null;
    final String title = currentVerse?.surahName ?? widget.surah.name;
    final String revelationType =
        currentVerse?.revelationType ?? widget.surah.revelationType;
    final int totalAyah = currentVerse?.totalAyah ?? widget.surah.totalAyah;

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: _buildAppBarIconButton(
        tooltip: appL10n.appStringsMessage13,
        icon: Icons.arrow_back_ios_new,
        color: primary,
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: AppSpacing.xs,
      title: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.medium),
        transitionBuilder: (child, animation) {
          if (MediaQuery.of(context).disableAnimations) return child;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<String>(title),
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.script.copyWith(
                  fontSize: 21,
                  color: primary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                appL10n.readerContentMessage2(
                  (_revelationLabel(revelationType)).toString(),
                  context.digits(totalAyah),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_recitation != null)
          _buildAppBarIconButton(
            tooltip: _recitingThisPage
                ? appL10n.recitationPause
                : appL10n.recitationListenFromHere,
            icon: _recitingThisPage
                ? Icons.pause_rounded
                : Icons.headphones_rounded,
            color: primary,
            onPressed: _toggleRecitation,
          ),
        _buildAppBarIconButton(
          tooltip: appL10n.surahDetailsScreenMessage1,
          icon: Icons.tune_rounded,
          color: primary,
          onPressed: _showReadingControlsSheet,
        ),
        _buildAppBarIconButton(
          tooltip: appL10n.appStringsMessage16,
          icon: Icons.settings_outlined,
          color: primary,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const QuranSettingsDialog(),
            );
          },
        ),
        _BookmarkButton(color: primary, onTap: _saveBookmark),
      ],
      centerTitle: true,
    );
  }

  Widget _buildAppBarIconButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }

  String _revelationLabel(String value) {
    final String normalized = value.toLowerCase();
    if (normalized.contains('mecca') || normalized.contains('meccan')) {
      return appL10n.quranScreenMessage2;
    }
    if (normalized.contains('medina') || normalized.contains('medinan')) {
      return appL10n.quranScreenMessage3;
    }
    return value;
  }

  /// The page bar of the mushaf page layout: one slim row, so the page
  /// keeps as much of the screen as possible.
  Widget _buildBottomNavigation(
    ThemeData theme,
    Color pageSurface,
    Color pageBorder,
  ) {
    final int currentPage = _currentSurahPage + 1;
    final int totalPages = _surahPages.length;
    final double progress = totalPages == 0 ? 0 : currentPage / totalPages;
    final int mushafPage =
        _surahPages[_currentSurahPage.clamp(0, totalPages - 1)].pageNumber;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: pageBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            _ReaderNavButton(
              tooltip: appL10n.readerControlsMessage1,
              icon: Icons.chevron_right,
              onPressed: _currentSurahPage > 0
                  ? () => _pageController.previousPage(
                      duration: AppMotion.of(context, AppMotion.exit),
                      curve: AppMotion.enter,
                    )
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: AppMotion.of(context, AppMotion.base),
                            child: Text(
                              '${appL10n.readerMushafPage(context.digits(mushafPage))}'
                              '  •  ${context.digits('$currentPage/$totalPages')}',
                              key: ValueKey<int>(currentPage),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // The page only fits this screen at a reduced size;
                        // tapping the mark says so and what to do.
                        if (_currentPageCompressed) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Tooltip(
                            key: const Key('reader-page-compressed'),
                            message: appL10n.readerPageCompressed,
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(
                              Icons.text_decrease_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: AppRadius.pill,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: theme.colorScheme.secondary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ReaderNavButton(
              tooltip: appL10n.readerControlsMessage2,
              icon: Icons.chevron_left,
              onPressed: _currentSurahPage < totalPages - 1
                  ? () => _pageController.nextPage(
                      duration: AppMotion.of(context, AppMotion.exit),
                      curve: AppMotion.enter,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
