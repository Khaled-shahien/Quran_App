part of 'surah_details_screen.dart';

mixin _ReaderControls on _ReaderState {
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

  @override
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
                        (currentPage).toString(),
                        (totalPages).toString(),
                      ),
                      key: ValueKey<int>(currentPage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
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

  Future<void> _saveBookmark() async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    final KhatmaProvider? khatmaProvider = _hasUnitRange
        ? Provider.of<KhatmaProvider?>(context, listen: false)
        : null;
    final _SurahVerseData? currentVerse = _currentPageLeadVerse;

    await bookmarkProvider.saveBookmark(
      surahNumber: widget.surahNumber,
      surahName: widget.surah.name,
      pageIndex: _currentSurahPage,
    );

    bool savedWirdPosition = false;
    if (_hasUnitRange && currentVerse != null && khatmaProvider != null) {
      savedWirdPosition = await khatmaProvider.saveWirdPosition(
        trackingUnitValue: widget.rangeTrackingUnit!,
        fromUnit: widget.rangeFromUnit!,
        toUnit: widget.rangeToUnit!,
        surahNumber: currentVerse.surahNumber,
        ayahNumber: currentVerse.verseNumber,
        pageNumber: currentVerse.pageNumber,
        pageIndex: _currentSurahPage,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedWirdPosition
              ? appL10n.readerControlsMessage3
              : appL10n.readerControlsMessage4,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReadingControlsSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10nOf(context).readerControlsMessage5,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10nOf(context).readerControlsMessage6,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _fontSize,
                      min: 22,
                      max: 38,
                      divisions: 16,
                      onChanged: (value) {
                        setState(() {
                          _fontSize = value;
                        });
                        _persistReadingPreferences();
                        setLocalState(() {});
                      },
                    ),
                    Text(
                      l10nOf(context).readerControlsMessage7,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      value: _lineHeight,
                      min: 1.5,
                      max: 2.5,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          _lineHeight = value;
                        });
                        _persistReadingPreferences();
                        setLocalState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _showVerseMarkers,
                      onChanged: (value) {
                        setState(() {
                          _showVerseMarkers = value;
                        });
                        _persistReadingPreferences();
                        setLocalState(() {});
                      },
                      title: Text(
                        l10nOf(context).readerControlsMessage8,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      value: _immersiveMode,
                      onChanged: (value) {
                        setState(() {
                          _immersiveMode = value;
                        });
                        _persistReadingPreferences();
                        setLocalState(() {});
                      },
                      title: Text(
                        l10nOf(context).readerControlsMessage9,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
