part of '../surah_details_screen.dart';

/// The reading area in its three layouts.
extension _SurahReaderPage on _SurahDetailsScreenState {
  _ReaderStyle _readerStyle(Color textColor) {
    final ThemeData theme = Theme.of(context);
    return _ReaderStyle(
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      textColor: textColor,
      // The same ink as the text: the accent colour is too pale on light
      // paper to carry the verse numbers.
      markerColor: textColor,
      tintColor: theme.colorScheme.primary.withValues(alpha: 0.14),
      showMarkers: _showVerseMarkers,
    );
  }

  /// The verse being recited and the verse being acted on.
  Set<_VerseRef> get _tintedVerses => <_VerseRef>{?_highlighted, ?_selected};

  Widget _buildBodyContent({required Color textColor}) {
    if (_isLoading) {
      // Clipped rather than overflowing when large text leaves little room.
      return const ClipRect(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: PulseLoader(lines: 8),
        ),
      );
    }

    if (_error != null) return StatusView.error(message: _error!);

    if (_surahPages.isEmpty) {
      return EmptyState(
        icon: Icons.menu_book_outlined,
        message: appL10n.readerContentMessage1,
      );
    }

    final _ReaderStyle style = _readerStyle(textColor);
    // The Quran has its own size control in the reader, so the app's text
    // size setting does not scale it a second time.
    return SystemTextScale(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: switch (_layout) {
          ReaderLayout.continuous => _buildContinuous(style),
          ReaderLayout.pages => _buildPaged(style),
          ReaderLayout.verses => _buildVerseList(style),
        },
      ),
    );
  }

  static const EdgeInsets _readingPadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    AppSpacing.xl,
  );

  /// One vertical scroll; each mushaf page is a lazily built block.
  Widget _buildContinuous(_ReaderStyle style) {
    return _AnchoredList(
      key: const Key('reader-continuous'),
      itemCount: _surahPages.length,
      anchor: _anchor,
      padding: _readingPadding,
      onTopItemChanged: _onPageChanged,
      itemBuilder: (context, index) => _buildPageBlock(
        _surahPages[index],
        style,
        // The last block needs no marker below it.
        pageMarker: index < _surahPages.length - 1,
      ),
    );
  }

  /// One mushaf page per swipe. Each page is a fixed surface: its text is
  /// sized to fit the screen, and nothing on it scrolls vertically.
  Widget _buildPaged(_ReaderStyle style) {
    return PageView.builder(
      key: const Key('reader-pages'),
      controller: _pageController,
      // Horizontal only. In right-to-left the next page comes in from the
      // left, as in a printed mushaf.
      scrollDirection: Axis.horizontal,
      padEnds: false,
      itemCount: _surahPages.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, pageIndex) {
        return Padding(
          padding: _fixedPagePadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final QuranPageFit fit = _fitPage(
                pageIndex,
                constraints.biggest,
                style,
              );
              final _ReaderStyle fitted = style.copyWith(
                fontSize: fit.fontSize,
                lineHeight: fit.lineHeight,
              );
              // The fit is measured, so this never clips on a phone in
              // portrait; the clip only guards against a rounding pixel.
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: _buildPageBlock(
                    _surahPages[pageIndex],
                    fitted,
                    pageMarker: false,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static const EdgeInsets _fixedPagePadding = EdgeInsets.fromLTRB(
    AppSpacing.ms,
    AppSpacing.xs,
    AppSpacing.ms,
    AppSpacing.xs,
  );

  /// The pieces of a page, as [_buildPageBlock] draws them.
  List<QuranPagePiece> _pagePieces(_SurahPageData page) {
    final List<QuranPagePiece> pieces = <QuranPagePiece>[];
    List<QuranVerseText> run = <QuranVerseText>[];
    void flush() {
      if (run.isEmpty) return;
      pieces.add(QuranVersesPiece(run));
      run = <QuranVerseText>[];
    }

    for (final _SurahVerseData verse in page.verses) {
      if (verse.showSurahHeader || verse.showBasmala) {
        flush();
        if (verse.showSurahHeader) {
          pieces.add(
            QuranTitlePiece(
              name: verse.surahName,
              subtitle: _titleSubtitle(verse),
            ),
          );
        }
        if (verse.showBasmala) pieces.add(const QuranBasmalaPiece());
      }
      run.add((text: verse.text, number: verse.verseNumber));
    }
    flush();
    return pieces;
  }

  String _titleSubtitle(_SurahVerseData verse) => appL10n.readerContentMessage2(
    _revelationLabel(verse.revelationType),
    context.digits(verse.totalAyah),
  );

  /// The size page [pageIndex] is drawn at in [area], measured once per
  /// page, area and reading setting.
  QuranPageFit _fitPage(int pageIndex, Size area, _ReaderStyle style) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final String key =
        '$pageIndex|${area.width.toStringAsFixed(1)}x'
        '${area.height.toStringAsFixed(1)}|${style.fontSize}|'
        '${style.lineHeight}|${style.showMarkers}|${scaler.scale(100)}';
    final QuranPageFit? cached = _pageFits[key];
    if (cached != null) return cached;
    final QuranPageFit fit = _pageFits[key] = fitQuranPage(
      pieces: _pagePieces(_surahPages[pageIndex]),
      area: area,
      quranStyle: style.text,
      subtitleStyle: _subtitleStyle,
      markerColor: style.markerColor,
      showMarkers: style.showMarkers,
      textScaler: scaler,
      rootStyle: DefaultTextStyle.of(context).style,
      preferredSize: style.fontSize,
      preferredLineHeight: style.lineHeight,
    );
    // The page bar is built before pages measure themselves; let it catch
    // up once when the page in view turns out to be reduced.
    if (fit.compressed && pageIndex == _currentSurahPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshChrome();
      });
    }
    return fit;
  }

  TextStyle get _subtitleStyle {
    final ThemeData theme = Theme.of(context);
    return theme.textTheme.labelSmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// One verse per row.
  Widget _buildVerseList(_ReaderStyle style) {
    final List<_SurahVerseData> verses = _allVerses;
    final _VerseRef? target = _anchorVerse;
    int anchor = target == null
        ? -1
        : verses.indexWhere(
            (verse) =>
                verse.surahNumber == target.surah &&
                verse.verseNumber == target.ayah,
          );
    if (anchor < 0) anchor = _firstVerseIndexOfPage(_anchor);

    return _AnchoredList(
      key: const Key('reader-verses'),
      itemCount: verses.length,
      anchor: anchor,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.ms,
        AppSpacing.sm,
        AppSpacing.ms,
        AppSpacing.xl,
      ),
      onTopItemChanged: (index) {
        final int page = _pageIndexOfVerse(index);
        if (page != _currentSurahPage) _onPageChanged(page);
      },
      itemBuilder: (context, index) {
        final _SurahVerseData verse = verses[index];
        final bool tinted = _tintedVerses.contains((
          surah: verse.surahNumber,
          ayah: verse.verseNumber,
        ));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._headersFor(verse, style),
            _VerseRow(
              verse: verse,
              style: style,
              tinted: tinted,
              actionsTooltip: appL10n.readerVerseActions(
                context.digits(verse.verseNumber),
              ),
              onActions: () => _showVerseActions(verse),
            ),
            if (index < verses.length - 1)
              Divider(
                height: AppSpacing.sm,
                indent: AppSpacing.ms,
                endIndent: AppSpacing.ms,
                color: style.markerColor.withValues(alpha: 0.18),
              ),
          ],
        );
      },
    );
  }

  /// What precedes a verse that opens a surah: its title (inside a wird)
  /// and the basmala.
  List<Widget> _headersFor(_SurahVerseData verse, _ReaderStyle style) {
    return <Widget>[
      if (verse.showSurahHeader)
        _SurahTitleBand(
          verse: verse,
          style: style,
          subtitle: _titleSubtitle(verse),
        ),
      if (verse.showBasmala)
        _BasmalaLine(surahNumber: verse.surahNumber, style: style),
    ];
  }

  /// The verses of one mushaf page: flowing paragraphs, broken only where a
  /// surah begins.
  Widget _buildPageBlock(
    _SurahPageData page,
    _ReaderStyle style, {
    required bool pageMarker,
  }) {
    final List<Widget> children = <Widget>[];
    List<_SurahVerseData> run = <_SurahVerseData>[];

    void flush() {
      if (run.isEmpty) return;
      children.add(
        _QuranParagraph(
          verses: run,
          style: style,
          highlighted: _tintedVerses,
          onVerseLongPress: _showVerseActions,
        ),
      );
      run = <_SurahVerseData>[];
    }

    for (final _SurahVerseData verse in page.verses) {
      if (verse.showSurahHeader || verse.showBasmala) {
        flush();
        children.addAll(_headersFor(verse, style));
      }
      run.add(verse);
    }
    flush();

    if (pageMarker) {
      children.add(
        _PageMarker(
          label: appL10n.readerMushafPage(context.digits(page.pageNumber)),
          color: style.markerColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Selects [verse] and offers what can be done with it.
  Future<void> _showVerseActions(_SurahVerseData verse) async {
    playFeedback(context, FeedbackEvent.selection);
    _selectVerse((surah: verse.surahNumber, ayah: verse.verseNumber));
    final l10n = l10nOf(context);
    final RecitationController? recitation = _recitation;
    final VerseLibraryController? library = context
        .read<VerseLibraryController?>();
    final String reference = l10n.savedVerseReference(
      verse.surahName,
      context.digits(verse.verseNumber),
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final ThemeData theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  '${verse.surahName} • '
                  '${l10n.readerVerseActions(context.digits(verse.verseNumber))}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (recitation != null)
                ListTile(
                  leading: const Icon(Icons.play_arrow_rounded),
                  title: Text(l10n.readerVersePlay),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(
                      recitation.playSurah(
                        verse.surahNumber,
                        fromAyah: verse.verseNumber,
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.menu_book_rounded),
                title: Text(l10n.readerVerseTafsir),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(
                    showTafsirSheet(
                      context,
                      surah: verse.surahNumber,
                      ayah: verse.verseNumber,
                      surahName: verse.surahName,
                      verseText: verse.text,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(l10n.readerVerseBookmark),
                onTap: () {
                  Navigator.pop(sheetContext);
                  playFeedback(context, FeedbackEvent.bookmark);
                  unawaited(_saveBookmark(verse: verse));
                },
              ),
              if (library != null) ...[
                ListTile(
                  leading: const Icon(Icons.bookmarks_outlined),
                  title: Text(l10n.readerVerseSave),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(
                      showSaveVerseSheet(
                        context,
                        library: library,
                        surah: verse.surahNumber,
                        ayah: verse.verseNumber,
                        title: reference,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: Text(l10n.readerVerseNote),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(
                      showVerseNoteEditor(
                        context,
                        library: library,
                        surah: verse.surahNumber,
                        ayah: verse.verseNumber,
                        title: reference,
                      ),
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(l10n.readerVerseCopy),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(_copyVerse(verse));
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (mounted) _selectVerse(null);
  }

  /// Copies the verse exactly as stored, followed by its reference.
  Future<void> _copyVerse(_SurahVerseData verse) async {
    await Clipboard.setData(
      ClipboardData(
        text: '${verse.text}\n[${verse.surahName}: ${verse.verseNumber}]',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(appL10n.readerVerseCopied)));
  }
}
