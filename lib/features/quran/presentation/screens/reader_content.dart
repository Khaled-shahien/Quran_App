part of 'surah_details_screen.dart';

mixin _ReaderContent on _ReaderState {
  Widget _buildBodyContent({
    required Color textColor,
    required Color pageSurface,
    required Color pageBorder,
  }) {
    if (_isLoading) {
      return const Center(child: PulseLoader(lines: 8));
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.red,
            fontFamily: 'Amiri',
          ),
        ),
      );
    }

    if (_surahPages.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد آيات في هذه السورة',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Amiri',
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return PageView.builder(
          controller: _pageController,
          padEnds: false,
          reverse: false,
          itemCount: _surahPages.length,
          onPageChanged: (index) {
            setState(() {
              _currentSurahPage = index;
            });
          },
          itemBuilder: (context, pageIndex) {
            final pageData = _surahPages[pageIndex];

            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Listener(
                onPointerDown: (_) => _setPagePressed(true),
                onPointerUp: (_) => _setPagePressed(false),
                onPointerCancel: (_) => _setPagePressed(false),
                child: AnimatedContainer(
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: _pagePressed
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.07)
                        : pageSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: pageBorder),
                    boxShadow: AppShadows.card,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: SelectableText.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: _fontSize,
                                  color: textColor,
                                  height: _lineHeight,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: _buildVersesWithNumbers(
                                  pageData,
                                  constraints.maxWidth,
                                ),
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<InlineSpan> _buildVersesWithNumbers(
    _SurahPageData pageData,
    double pageWidth,
  ) {
    final List<InlineSpan> spans = [];

    for (int i = 0; i < pageData.verses.length; i++) {
      final _SurahVerseData verse = pageData.verses[i];

      if (verse.showSurahHeader) {
        if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _buildSurahHeader(verse, pageWidth),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
      }

      spans.add(TextSpan(text: '${verse.text}  '));

      if (_showVerseMarkers) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ),
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Text(
                verse.verseNumber.toString(),
                style: TextStyle(
                  fontSize: _fontSize * 0.45,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      }

      if (i < pageData.verses.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return spans;
  }

  Widget _buildSurahHeader(_SurahVerseData verse, double pageWidth) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final double headerWidth = pageWidth.clamp(180.0, 720.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: headerWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: Container(
                key: Key('surah-header-${verse.surahNumber}'),
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.45),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: primary.withValues(alpha: 0.18)),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(color: primary.withValues(alpha: 0.28)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            verse.surahName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: (_fontSize * 0.82).clamp(20.0, 28.0),
                              fontWeight: FontWeight.bold,
                              color: primary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_revelationLabel(verse.revelationType)} '
                            '• ${verse.totalAyah} آية',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Divider(color: primary.withValues(alpha: 0.28)),
                    ),
                  ],
                ),
              ),
            ),
            if (verse.showBasmala)
              SizedBox(
                width: double.infinity,
                child: Container(
                  key: Key('surah-basmala-${verse.surahNumber}'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primary.withValues(alpha: 0.14)),
                  ),
                  child: Text(
                    'بِسْمِ اللَّهِ '
                    'الرَّحْمَٰنِ الرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: (_fontSize * 0.78).clamp(19.0, 26.0),
                      fontWeight: FontWeight.bold,
                      color: primary,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}