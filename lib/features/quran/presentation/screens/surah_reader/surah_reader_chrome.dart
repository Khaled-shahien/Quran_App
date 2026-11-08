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
      titleSpacing: 4,
      title: AnimatedSwitcher(
        duration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 300),
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
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 21,
                  color: primary,
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                appL10n.readerContentMessage2(
                  (_revelationLabel(revelationType)).toString(),
                  context.digits(totalAyah),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: primary.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
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
          icon: Icons.tune,
          color: primary,
          onPressed: _showReadingControlsSheet,
        ),
        _buildAppBarIconButton(
          tooltip: appL10n.appStringsMessage16,
          icon: Icons.settings,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.18)),
        ),
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
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

  Widget _buildBottomNavigation(
    ThemeData theme,
    Color pageSurface,
    Color pageBorder,
  ) {
    final int currentPage = _currentSurahPage + 1;
    final int totalPages = _surahPages.length;
    final double progress = totalPages == 0 ? 0 : currentPage / totalPages;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
        boxShadow: AppShadows.card,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: pageSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: pageBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: theme.colorScheme.secondary.withValues(
                  alpha: 0.55,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ReaderNavButton(
                  tooltip: appL10n.readerControlsMessage1,
                  icon: Icons.chevron_right,
                  onPressed: _currentSurahPage > 0
                      ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                        )
                      : null,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      if (MediaQuery.of(context).disableAnimations) {
                        return child;
                      }
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      appL10n.onboardingScreenMessage3(
                        context.digits(currentPage),
                        context.digits(totalPages),
                      ),
                      key: ValueKey<int>(currentPage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.78,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _ReaderNavButton(
                  tooltip: appL10n.readerControlsMessage2,
                  icon: Icons.chevron_left,
                  onPressed: _currentSurahPage < _surahPages.length - 1
                      ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
