import 'dart:async';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/utils/arabic_text.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/data_sources/quran_master_asset.dart';
import '../../domain/entities/surah_entity.dart';
import '../../domain/services/basmala.dart';
import '../../domain/services/reader_layout.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../../core/accessibility/app_text_scale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/reading_mode_controller.dart';
import '../../../recitation/presentation/providers/recitation_controller.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/widgets/reading_preferences.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';
import '../../../../core/feedback/feedback_service.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/quran_page_layout.dart';
import '../widgets/quran_settings_dialog.dart';
import '../widgets/tafsir_sheet.dart';
import '../widgets/verse_library_sheets.dart';
import '../providers/verse_library_controller.dart';

part 'surah_reader/surah_reader_models.dart';
part 'surah_reader/surah_reader_chrome.dart';
part 'surah_reader/surah_reader_page.dart';
part 'surah_reader/surah_reader_text.dart';
part 'surah_reader/surah_reader_buttons.dart';

/// The Quran reader. In night-reading mode the whole reader (page, ayah
/// markers, headers, app bar) uses the warm low-blue night theme.
class SurahDetailsScreen extends StatelessWidget {
  final SurahEntity surah;
  final int surahNumber;
  final int? initialSurahNumber;
  final int? initialAyahNumber;
  final int? initialPageNumber;
  final String? rangeTrackingUnit;
  final int? rangeFromUnit;
  final int? rangeToUnit;

  /// Opened from the saved bookmark: start at the bookmarked verse rather
  /// than where reading last stopped.
  final bool openAtBookmark;

  const SurahDetailsScreen({
    super.key,
    required this.surah,
    required this.surahNumber,
    this.initialSurahNumber,
    this.initialAyahNumber,
    this.initialPageNumber,
    this.rangeTrackingUnit,
    this.rangeFromUnit,
    this.rangeToUnit,
    this.openAtBookmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = _SurahReaderBody(
      surah: surah,
      surahNumber: surahNumber,
      initialSurahNumber: initialSurahNumber,
      initialAyahNumber: initialAyahNumber,
      initialPageNumber: initialPageNumber,
      rangeTrackingUnit: rangeTrackingUnit,
      rangeFromUnit: rangeFromUnit,
      rangeToUnit: rangeToUnit,
      openAtBookmark: openAtBookmark,
    );
    // Optional so the reader still works where the setting is not provided.
    final night = context.watch<ReadingModeController?>()?.night ?? false;
    return night ? Theme(data: AppTheme.nightReadingTheme, child: body) : body;
  }
}

class _SurahReaderBody extends StatefulWidget {
  final SurahEntity surah;
  final int surahNumber;
  final int? initialSurahNumber;
  final int? initialAyahNumber;
  final int? initialPageNumber;
  final String? rangeTrackingUnit;
  final int? rangeFromUnit;
  final int? rangeToUnit;
  final bool openAtBookmark;

  const _SurahReaderBody({
    required this.surah,
    required this.surahNumber,
    this.initialSurahNumber,
    this.initialAyahNumber,
    this.initialPageNumber,
    this.rangeTrackingUnit,
    this.rangeFromUnit,
    this.rangeToUnit,
    this.openAtBookmark = false,
  });

  @override
  State<_SurahReaderBody> createState() => _SurahDetailsScreenState();
}

class _SurahDetailsScreenState extends State<_SurahReaderBody> {
  List<_SurahPageData> _surahPages = [];
  bool _isLoading = true;
  String? _error;

  late PageController _pageController;
  int _currentSurahPage = 0;

  double _fontSize = 28;
  double _lineHeight = 1.95;
  bool _showVerseMarkers = true;
  bool _immersiveMode = false;
  ReaderLayout _layout = ReaderLayout.continuous;

  /// The mushaf-page block the scrolling layouts open at. It changes only
  /// when the reader jumps (opening, resuming, following recitation), never
  /// while the user scrolls.
  int _anchor = 0;

  /// A verse to open at, when the target is finer than a page.
  _VerseRef? _anchorVerse;

  /// The verse whose actions are open.
  _VerseRef? _selected;

  /// Measured sizes of fixed mushaf pages, by page, area and setting.
  final Map<String, QuranPageFit> _pageFits = <String, QuranPageFit>{};

  /// Whether the mushaf page in view had to be drawn below the comfortable
  /// reading size to fit the screen.
  bool get _currentPageCompressed {
    final String prefix = '$_currentSurahPage|';
    return _pageFits.entries.any(
      (entry) => entry.key.startsWith(prefix) && entry.value.compressed,
    );
  }

  /// Every verse on screen, in reading order.
  List<_SurahVerseData> get _allVerses => <_SurahVerseData>[
    for (final _SurahPageData page in _surahPages) ...page.verses,
  ];

  int _firstVerseIndexOfPage(int pageIndex) {
    int index = 0;
    for (int i = 0; i < pageIndex && i < _surahPages.length; i++) {
      index += _surahPages[i].verses.length;
    }
    return index;
  }

  int _pageIndexOfVerse(int verseIndex) {
    int seen = 0;
    for (int i = 0; i < _surahPages.length; i++) {
      seen += _surahPages[i].verses.length;
      if (verseIndex < seen) return i;
    }
    return _surahPages.isEmpty ? 0 : _surahPages.length - 1;
  }

  bool get _hasUnitRange =>
      widget.rangeTrackingUnit != null &&
      widget.rangeFromUnit != null &&
      widget.rangeToUnit != null;

  _SurahVerseData? get _currentPageLeadVerse {
    if (_surahPages.isEmpty) return null;
    final int pageIndex = _currentSurahPage.clamp(0, _surahPages.length - 1);
    final List<_SurahVerseData> verses = _surahPages[pageIndex].verses;
    if (verses.isEmpty) return null;
    return verses.first;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _restoreReadingPreferences();
    _loadVerses().then((_) => _focusInitialTarget());
  }

  /// Optional so the reader still works where preferences are not provided.
  SharedPreferences? get _prefs =>
      Provider.of<SharedPreferences?>(context, listen: false);

  void _restoreReadingPreferences() {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    _fontSize = ReadingPreferences.fontSize(prefs);
    _lineHeight = ReadingPreferences.lineHeight(prefs);
    _showVerseMarkers = prefs.getBool(ReadingPreferences.markersKey) ?? true;
    _layout = ReaderLayout.parse(prefs.get(ReadingPreferences.layoutKey));
  }

  /// Optional so the reader also works where no player is provided.
  RecitationController? _recitation;
  ({int surah, int ayah})? _highlighted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Provider.of<RecitationController?>(
      context,
      listen: false,
    );
    if (!identical(controller, _recitation)) {
      _recitation?.removeListener(_onRecitationChanged);
      _recitation = controller?..addListener(_onRecitationChanged);
    }
  }

  @override
  void dispose() {
    _recitation?.removeListener(_onRecitationChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// Highlights the ayah being recited and turns to its page.
  void _onRecitationChanged() {
    final c = _recitation;
    if (c == null || !mounted) return;
    final surah = c.surah;
    final ayah = c.currentAyah;
    final next = surah == null || ayah == null || !c.isActive
        ? null
        : (surah: surah, ayah: ayah);
    if (next == _highlighted) {
      setState(() {}); // play/pause icon
      return;
    }
    setState(() => _highlighted = next);
    if (next == null) return;
    final page = _surahPages.indexWhere(
      (p) => p.verses.any(
        (v) => v.surahNumber == next.surah && v.verseNumber == next.ayah,
      ),
    );
    if (page < 0) return;
    if (_layout != ReaderLayout.pages) {
      // The scrolling layouts move to the verse; verse-by-verse follows
      // every verse, continuous only when the page changes.
      if (_layout == ReaderLayout.verses || page != _currentSurahPage) {
        setState(() {
          _anchor = page;
          _anchorVerse = next;
          _currentSurahPage = page;
        });
      }
      return;
    }
    if (page != _currentSurahPage && _pageController.hasClients) {
      if (AppMotion.reduced(context)) {
        _pageController.jumpToPage(page);
      } else {
        _pageController.animateToPage(
          page,
          duration: AppMotion.medium,
          curve: AppMotion.standard,
        );
      }
    }
  }

  bool get _recitingThisPage {
    final c = _recitation;
    final lead = _currentPageLeadVerse;
    return c != null &&
        c.isPlaying &&
        lead != null &&
        c.surah == lead.surahNumber;
  }

  Future<void> _toggleRecitation() async {
    final c = _recitation;
    final lead = _currentPageLeadVerse;
    if (c == null || lead == null) return;
    if (_recitingThisPage) {
      await c.pause();
    } else if (c.surah == lead.surahNumber && c.isActive) {
      await c.togglePlay();
    } else {
      await c.playSurah(lead.surahNumber, fromAyah: lead.verseNumber);
    }
  }

  void _focusInitialTarget() {
    if (widget.openAtBookmark && _focusBookmarkedPage()) return;
    if (_focusInitialAyahIfProvided()) {
      return;
    }
    if (_focusInitialPageIfProvided()) {
      return;
    }
    if (_focusLastReadPage()) {
      return;
    }
    _focusBookmarkedPage();
  }

  /// Whole-surah reading resumes where it stopped; khatma ranges keep
  /// their own start.
  bool get _remembersPosition => widget.rangeFromUnit == null;

  bool _focusLastReadPage() {
    final prefs = _prefs;
    if (prefs == null || !_remembersPosition || _surahPages.isEmpty) {
      return false;
    }
    final ayah = ReadingPreferences.lastAyah(prefs, widget.surahNumber);
    if (ayah == null) return false;
    final index = _surahPages.indexWhere(
      (page) => page.verses.any(
        (verse) =>
            verse.surahNumber == widget.surahNumber &&
            verse.verseNumber == ayah,
      ),
    );
    if (index < 0) return false;
    _setCurrentPage(index);
    return true;
  }

  void _rememberPage(int index) {
    final prefs = _prefs;
    if (prefs == null || !_remembersPosition) return;
    if (index < 0 || index >= _surahPages.length) return;
    final lead = _surahPages[index].verses
        .where((verse) => verse.surahNumber == widget.surahNumber)
        .firstOrNull;
    if (lead == null) return;
    unawaited(
      ReadingPreferences.saveLastAyah(
        prefs,
        widget.surahNumber,
        lead.verseNumber,
      ),
    );
  }

  void _setCurrentPage(int pageIndex) {
    if (!mounted) return;

    setState(() {
      _currentSurahPage = pageIndex;
      _anchor = pageIndex;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(pageIndex);
      return;
    }

    _pageController.dispose();
    _pageController = PageController(initialPage: pageIndex);
  }

  bool _focusInitialPageIfProvided() {
    final int? targetPage = widget.initialPageNumber;
    if (targetPage == null || _surahPages.isEmpty) {
      return false;
    }

    final int safePage = targetPage.clamp(0, _surahPages.length - 1);
    _setCurrentPage(safePage);
    return true;
  }

  bool _focusInitialAyahIfProvided() {
    final int? targetAyah = widget.initialAyahNumber;
    if (targetAyah == null || _surahPages.isEmpty) {
      return false;
    }

    final int targetSurah = widget.initialSurahNumber ?? widget.surahNumber;
    int targetPage = 0;
    for (int i = 0; i < _surahPages.length; i++) {
      final _SurahPageData page = _surahPages[i];
      final bool hasTarget = page.verses.any(
        (verse) =>
            verse.surahNumber == targetSurah && verse.verseNumber == targetAyah,
      );
      if (hasTarget) {
        targetPage = i;
        break;
      }
    }

    _anchorVerse = (surah: targetSurah, ayah: targetAyah);
    _setCurrentPage(targetPage);
    return true;
  }

  /// Opens at the saved bookmark in this surah; false when there is none.
  bool _focusBookmarkedPage() {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );

    if (bookmarkProvider.surahNumber != widget.surahNumber ||
        _surahPages.isEmpty) {
      return false;
    }

    // Bookmarks store a verse. One saved by the old reader only has a page
    // index under the old pagination, which is replayed to find its verse.
    int? ayah = bookmarkProvider.ayahNumber;
    final int? legacyIndex = bookmarkProvider.pageIndex;
    if (ayah == null && legacyIndex != null) {
      ayah = legacyPageLeadAyah(
        verses: <LegacyVerse>[
          for (final _SurahVerseData verse in _allVerses)
            if (verse.surahNumber == widget.surahNumber)
              (
                ayah: verse.verseNumber,
                length: verse.text.length,
                basmala: verse.showBasmala,
              ),
        ],
        pageIndex: legacyIndex,
        basmalaLength: uthmaniBasmala.length,
      );
    }
    if (ayah == null) return false;

    final int page = _surahPages.indexWhere(
      (page) => page.verses.any(
        (verse) =>
            verse.surahNumber == widget.surahNumber &&
            verse.verseNumber == ayah,
      ),
    );
    if (page < 0) return false;
    _anchorVerse = (surah: widget.surahNumber, ayah: ayah);
    _setCurrentPage(page);
    return true;
  }

  int? _unitValueForAyah(Map<String, dynamic> ayah) {
    switch (widget.rangeTrackingUnit) {
      case 'page':
      case 'صفحة':
        return (ayah['page'] as num?)?.toInt();
      case 'hizb':
      case 'حزب':
      case 'ربع':
        final int? hizbQuarter = (ayah['hizbQuarter'] as num?)?.toInt();
        if (hizbQuarter == null) return null;
        return ((hizbQuarter - 1) ~/ 4) + 1;
      case 'juz':
      case 'جزء':
        return (ayah['juz'] as num?)?.toInt();
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> _ayahsForSurah(Map<String, dynamic> surahData) {
    if (surahData.isEmpty) return <Map<String, dynamic>>[];

    final int surahNumber =
        (surahData['number'] as num?)?.toInt() ?? widget.surahNumber;
    final List<dynamic> ayahs =
        surahData['ayahs'] as List<dynamic>? ?? <dynamic>[];

    return ayahs.map((ayah) {
      final Map<String, dynamic> mapped = Map<String, dynamic>.from(
        ayah as Map,
      );
      mapped['_surahNumber'] = surahNumber;
      mapped['_surahName'] = displaySurahName(
        surahData['name']?.toString() ?? '',
      );
      mapped['_surahRevelationType'] =
          surahData['revelationType']?.toString() ?? '';
      mapped['_surahTotalAyah'] =
          (surahData['numberOfAyahs'] as num?)?.toInt() ??
          (surahData['ayahs'] as List<dynamic>? ?? <dynamic>[]).length;
      return mapped;
    }).toList();
  }

  List<Map<String, dynamic>> _ayahsForUnitRange({
    required List<Map<String, dynamic>> quran,
    required int minUnit,
    required int maxUnit,
  }) {
    final List<Map<String, dynamic>> selected = <Map<String, dynamic>>[];

    for (final Map<String, dynamic> surah in quran) {
      final int surahNumber =
          (surah['number'] as num?)?.toInt() ?? widget.surahNumber;
      final List<dynamic> ayahs =
          surah['ayahs'] as List<dynamic>? ?? <dynamic>[];

      for (final dynamic rawAyah in ayahs) {
        final Map<String, dynamic> ayah = Map<String, dynamic>.from(
          rawAyah as Map,
        );
        final int? unitValue = _unitValueForAyah(ayah);
        if (unitValue == null || unitValue < minUnit || unitValue > maxUnit) {
          continue;
        }

        ayah['_surahNumber'] = surahNumber;
        ayah['_surahName'] = displaySurahName(surah['name']?.toString() ?? '');
        ayah['_surahRevelationType'] =
            surah['revelationType']?.toString() ?? '';
        ayah['_surahTotalAyah'] =
            (surah['numberOfAyahs'] as num?)?.toInt() ?? ayahs.length;
        selected.add(ayah);
      }
    }

    return selected;
  }

  Future<void> _loadVerses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> quran = await QuranMasterAsset.load();

      final Map<String, dynamic> surahData = quran.firstWhere(
        (item) => item['number'] == widget.surahNumber,
        orElse: () => <String, dynamic>{},
      );

      final List<Map<String, dynamic>> surahAyahs = _ayahsForSurah(surahData);

      final int? rangeFromUnit = widget.rangeFromUnit;
      final int? rangeToUnit = widget.rangeToUnit;
      final bool hasRange = _hasUnitRange;

      final int minUnit;
      final int maxUnit;
      if (hasRange) {
        final int fromUnit = rangeFromUnit!;
        final int toUnit = rangeToUnit!;
        minUnit = fromUnit <= toUnit ? fromUnit : toUnit;
        maxUnit = fromUnit <= toUnit ? toUnit : fromUnit;
      } else {
        minUnit = 0;
        maxUnit = 0;
      }

      final List<Map<String, dynamic>> selectedAyahs = hasRange
          // Khatma ranges can cross Surah boundaries, especially Juz 1.
          ? _ayahsForUnitRange(quran: quran, minUnit: minUnit, maxUnit: maxUnit)
          : surahAyahs;

      // The verses to show, the basmala taken off ayah 1 where it is shown
      // as a header. The verse text is otherwise exactly as stored.
      final List<_SurahVerseData> verses = <_SurahVerseData>[];
      int? previousSurah;
      for (final Map<String, dynamic> ayah in selectedAyahs) {
        final int verseNumber = (ayah['numberInSurah'] as num?)?.toInt() ?? 1;
        final int surahNumber =
            (ayah['_surahNumber'] as num?)?.toInt() ?? widget.surahNumber;
        final BasmalaSplit basmala = splitLeadingBasmala(
          surahNumber: surahNumber,
          ayahNumber: verseNumber,
          text: (ayah['text'] as String? ?? '').trim(),
        );
        if (basmala.ayahText.isEmpty) continue;
        verses.add(
          _SurahVerseData(
            text: basmala.ayahText,
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            pageNumber: (ayah['page'] as num?)?.toInt() ?? 1,
            surahName: ayah['_surahName']?.toString() ?? '',
            revelationType: ayah['_surahRevelationType']?.toString() ?? '',
            totalAyah: (ayah['_surahTotalAyah'] as num?)?.toInt() ?? 0,
            // A wird can cross surahs; each new surah gets its title.
            showSurahHeader: hasRange && surahNumber != previousSurah,
            showBasmala: basmala.hasBasmala,
          ),
        );
        previousSurah = surahNumber;
      }

      // Blocks follow the mushaf's pages and nothing else.
      final List<_SurahPageData> paginatedVerses = <_SurahPageData>[
        for (final List<int> page in groupByMushafPage(<int>[
          for (final _SurahVerseData verse in verses) verse.pageNumber,
        ]))
          _SurahPageData(<_SurahVerseData>[
            for (final int i in page) verses[i],
          ], (verses[page.first].verseNumber - 1).clamp(0, 9999)),
      ];

      setState(() {
        _surahPages = paginatedVerses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = appL10n.readerDataMessage1;
        _isLoading = false;
      });
      developer.log(
        'Error loading verses',
        name: 'sakina_app.quran_screen',
        level: 1000,
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color paperColor = theme.scaffoldBackgroundColor;
    final Color textColor = theme.colorScheme.primary;
    final bool night = context.watch<ReadingModeController?>()?.night ?? false;
    final Color pageSurface = night
        ? AppTheme.nightPage
        // The page sits just above the paper: between page and card colour.
        : Color.lerp(
            theme.scaffoldBackgroundColor,
            SakinaDecor.of(context).card,
            0.5,
          )!;
    final Color pageBorder = theme.colorScheme.outlineVariant;
    final bool paged = _layout == ReaderLayout.pages;

    return Scaffold(
      backgroundColor: paperColor,
      appBar: _immersiveMode ? null : _buildAppBar(theme),
      body: SafeArea(
        top: !_immersiveMode,
        child: Column(
          children: [
            // How far through the surah or wird the reader is.
            if (!_immersiveMode && !paged && _surahPages.length > 1)
              LinearProgressIndicator(
                value: (_currentSurahPage + 1) / _surahPages.length,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: SakinaDecor.of(context).accent,
              ),
            Expanded(child: _buildBodyContent(textColor: textColor)),
            if (!_immersiveMode && paged && _surahPages.length > 1)
              _buildBottomNavigation(theme, pageSurface, pageBorder),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    if (index == _currentSurahPage) return;
    setState(() {
      _currentSurahPage = index;
    });
    _rememberPage(index);
  }

  /// Rebuilds the app bar and page bar around unchanged pages.
  void _refreshChrome() => setState(() {});

  void _selectVerse(_VerseRef? verse) {
    setState(() => _selected = verse);
  }

  void _setLayout(ReaderLayout layout) {
    if (layout == _layout) return;
    playFeedback(context, FeedbackEvent.selection);
    // The new layout opens where the reader is now.
    _pageController.dispose();
    _pageController = PageController(initialPage: _currentSurahPage);
    setState(() {
      _layout = layout;
      _anchor = _currentSurahPage;
      _anchorVerse = null;
    });
    _prefs?.setString(ReadingPreferences.layoutKey, layout.name);
  }

  /// Saves the bookmark at [verse], or at the first verse of the page in
  /// view when none is given.
  Future<void> _saveBookmark({_SurahVerseData? verse}) async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );
    final KhatmaProvider? khatmaProvider = _hasUnitRange
        ? Provider.of<KhatmaProvider?>(context, listen: false)
        : null;
    final _SurahVerseData? currentVerse = verse ?? _currentPageLeadVerse;

    await bookmarkProvider.saveBookmark(
      surahNumber: widget.surahNumber,
      surahName: widget.surah.name,
      pageIndex: _currentSurahPage,
      // A wird can show other surahs; the bookmark belongs to this one.
      ayahNumber: currentVerse?.surahNumber == widget.surahNumber
          ? currentVerse?.verseNumber
          : null,
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
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReadingControlsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10nOf(context).readerControlsMessage5,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10nOf(context).readerLayoutTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<ReaderLayout>(
                      key: const Key('reader-layout'),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ReaderLayout.continuous,
                          label: Text(l10nOf(context).readerLayoutContinuous),
                        ),
                        ButtonSegment(
                          value: ReaderLayout.pages,
                          label: Text(l10nOf(context).readerLayoutPages),
                        ),
                        ButtonSegment(
                          value: ReaderLayout.verses,
                          label: Text(l10nOf(context).readerLayoutVerses),
                        ),
                      ],
                      selected: {_layout},
                      onSelectionChanged: (selection) {
                        _setLayout(selection.single);
                        setLocalState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _layout == ReaderLayout.pages
                          ? l10nOf(context).readerLayoutPagesHint
                          : l10nOf(context).readerVerseHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10nOf(context).readerControlsMessage6,
                      style: Theme.of(context).textTheme.titleSmall,
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
                        _prefs?.setDouble(ReadingPreferences.fontKey, value);
                        setLocalState(() {});
                      },
                    ),
                    Text(
                      l10nOf(context).readerControlsMessage7,
                      style: Theme.of(context).textTheme.titleSmall,
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
                        _prefs?.setDouble(ReadingPreferences.heightKey, value);
                        setLocalState(() {});
                      },
                    ),
                    if (Provider.of<ReadingModeController?>(
                          context,
                          listen: false,
                        )
                        case final mode?)
                      SwitchListTile(
                        value: mode.night,
                        onChanged: (value) async {
                          await mode.setNight(value);
                          setLocalState(() {});
                        },
                        title: Text(
                          l10nOf(context).readingNightMode,
                          textAlign: TextAlign.start,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(l10nOf(context).readingNightModeHint),
                      ),
                    SwitchListTile(
                      value: _showVerseMarkers,
                      onChanged: (value) {
                        setState(() {
                          _showVerseMarkers = value;
                        });
                        _prefs?.setBool(ReadingPreferences.markersKey, value);
                        setLocalState(() {});
                      },
                      title: Text(
                        l10nOf(context).readerControlsMessage8,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SwitchListTile(
                      value: _immersiveMode,
                      onChanged: (value) {
                        setState(() {
                          _immersiveMode = value;
                        });
                        setLocalState(() {});
                      },
                      title: Text(
                        l10nOf(context).readerControlsMessage9,
                        textAlign: TextAlign.start,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
