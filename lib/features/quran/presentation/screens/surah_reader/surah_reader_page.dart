part of '../surah_details_screen.dart';

/// The page body: verses, surah header and basmala.
extension _SurahReaderPage on _SurahDetailsScreenState {
  Widget _buildBodyContent({
    required Color textColor,
    required Color pageSurface,
    required Color pageBorder,
  }) {
    if (_isLoading) {
      // Clipped rather than overflowing when large text leaves little room.
      return const ClipRect(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: PulseLoader(lines: 8),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.error,
            fontFamily: 'Amiri',
          ),
        ),
      );
    }

    if (_surahPages.isEmpty) {
      return Center(
        child: Text(
          appL10n.readerContentMessage1,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            _onPageChanged(index);
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
                    // Never scale the text down to fit: large Quran text and
                    // large system font sizes scroll within the page instead.
                    child: SingleChildScrollView(
                      key: PageStorageKey<String>('surah-page-$pageIndex'),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        // The Quran has its own size control in the reader.
                        child: SystemTextScale(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: SelectableText.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontFamily: quranFontFamily,
                                  fontSize: _fontSize,
                                  color: textColor,
                                  height: _lineHeight,
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
        if (spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _buildSurahHeader(verse, pageWidth),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
      } else if (verse.showBasmala) {
        // In range mode the surah header already includes the basmala.
        if (spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: SizedBox(
              width: pageWidth.clamp(180.0, 720.0),
              child: _buildBasmala(verse),
            ),
          ),
        );
        spans.add(const TextSpan(text: '\n'));
      }

      final bool reciting =
          _highlighted?.surah == verse.surahNumber &&
          _highlighted?.ayah == verse.verseNumber;
      spans.add(
        TextSpan(
          text: '${verse.text}  ',
          // The ayah being recited, so listeners can follow along.
          style: reciting
              ? TextStyle(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.16),
                )
              : null,
        ),
      );

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
                context.digits(verse.verseNumber),
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
                    Expanded(
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
                            appL10n.readerContentMessage2(
                              (_revelationLabel(
                                verse.revelationType,
                              )).toString(),
                              context.digits(verse.totalAyah),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
            if (verse.showBasmala) _buildBasmala(verse),
          ],
        ),
      ),
    );
  }

  /// Unnumbered basmala header above ayah 1 (never for Al-Fatiha or
  /// At-Tawbah; see [splitLeadingBasmala]). It scales with the Quran text
  /// size so large-text readers get a large basmala too.
  Widget _buildBasmala(_SurahVerseData verse) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    return Container(
      key: Key('surah-basmala-${verse.surahNumber}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        uthmaniBasmala,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: quranFontFamily,
          fontSize: _fontSize * 0.9,
          color: primary,
          height: 1.6,
        ),
      ),
    );
  }
}
