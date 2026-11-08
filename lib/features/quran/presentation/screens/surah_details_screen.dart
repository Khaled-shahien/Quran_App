import 'dart:async';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/utils/arabic_text.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/surah_entity.dart';
import '../../domain/services/basmala.dart';
import '../../../../core/accessibility/app_text_scale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/reading_mode_controller.dart';
import '../../../recitation/presentation/providers/recitation_controller.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/widgets/reading_preferences.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/quran_settings_dialog.dart';

part 'surah_reader/surah_reader_models.dart';
part 'surah_reader/surah_reader_chrome.dart';
part 'surah_reader/surah_reader_page.dart';
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

  const _SurahReaderBody({
    required this.surah,
    required this.surahNumber,
    this.initialSurahNumber,
    this.initialAyahNumber,
    this.initialPageNumber,
    this.rangeTrackingUnit,
    this.rangeFromUnit,
    this.rangeToUnit,
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
  bool _pagePressed = false;

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
    if (page >= 0 && page != _currentSurahPage && _pageController.hasClients) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        _pageController.jumpToPage(page);
      } else {
        _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
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
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(pageIndex);
      return;
    }

    _pageController.dispose();
    _pageController = PageController(initialPage: pageIndex);
  }

  void _setPagePressed(bool pressed) {
    if (_pagePressed == pressed || !mounted) return;
    setState(() {
      _pagePressed = pressed;
    });
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

    _setCurrentPage(targetPage);
    return true;
  }

  void _focusBookmarkedPage() {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );

    if (bookmarkProvider.surahNumber == widget.surahNumber &&
        bookmarkProvider.pageIndex != null &&
        _surahPages.isNotEmpty) {
      final int targetPage = bookmarkProvider.pageIndex!;
      if (targetPage < _surahPages.length) {
        _setCurrentPage(targetPage);
      }
    }
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
      final String jsonString = await rootBundle.loadString(
        'assets/quran_master.json',
      );
      final List<dynamic> jsonData = jsonDecode(jsonString) as List<dynamic>;

      final List<Map<String, dynamic>> quran = jsonData
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

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

      final List<_SurahPageData> paginatedVerses = [];
      List<_SurahVerseData> currentPageVerses = [];
      int currentLength = 0;
      int? currentPageStartVerseIndex;
      int? currentRangeSurahNumber;
      const int maxCharsPerPage = 550;

      for (int i = 0; i < selectedAyahs.length; i++) {
        final Map<String, dynamic> ayah = selectedAyahs[i];
        final int verseNumber = (ayah['numberInSurah'] as num?)?.toInt() ?? 1;
        final int pageNumber = (ayah['page'] as num?)?.toInt() ?? 1;
        final int surahNumber =
            (ayah['_surahNumber'] as num?)?.toInt() ?? widget.surahNumber;
        // The basmala is shown as an unnumbered header, not inside ayah 1.
        final BasmalaSplit basmala = splitLeadingBasmala(
          surahNumber: surahNumber,
          ayahNumber: verseNumber,
          text: (ayah['text'] as String? ?? '').trim(),
        );
        final String verseText = basmala.ayahText;
        if (verseText.isEmpty) {
          continue;
        }

        final bool showSurahHeader =
            hasRange && surahNumber != currentRangeSurahNumber;
        if (showSurahHeader) {
          if (currentPageVerses.isNotEmpty &&
              currentPageStartVerseIndex != null) {
            paginatedVerses.add(
              _SurahPageData(
                List<_SurahVerseData>.from(currentPageVerses),
                currentPageStartVerseIndex,
              ),
            );
            currentPageVerses = [];
            currentLength = 0;
            currentPageStartVerseIndex = null;
          }
          currentRangeSurahNumber = surahNumber;
          currentLength += 180;
        }

        currentPageStartVerseIndex ??= (verseNumber - 1).clamp(0, 9999);
        currentPageVerses.add(
          _SurahVerseData(
            text: verseText,
            surahNumber: surahNumber,
            verseNumber: verseNumber,
            pageNumber: pageNumber,
            surahName: ayah['_surahName']?.toString() ?? '',
            revelationType: ayah['_surahRevelationType']?.toString() ?? '',
            totalAyah: (ayah['_surahTotalAyah'] as num?)?.toInt() ?? 0,
            showSurahHeader: showSurahHeader,
            showBasmala: basmala.hasBasmala,
          ),
        );
        currentLength += verseText.length;
        if (basmala.hasBasmala) currentLength += uthmaniBasmala.length;

        if (currentLength >= maxCharsPerPage) {
          paginatedVerses.add(
            _SurahPageData(
              List<_SurahVerseData>.from(currentPageVerses),
              currentPageStartVerseIndex,
            ),
          );
          currentPageVerses = [];
          currentLength = 0;
          currentPageStartVerseIndex = null;
        }
      }

      if (currentPageVerses.isNotEmpty && currentPageStartVerseIndex != null) {
        paginatedVerses.add(
          _SurahPageData(
            List<_SurahVerseData>.from(currentPageVerses),
            currentPageStartVerseIndex,
          ),
        );
      }

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
        : theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFFFFCF5);
    final Color pageBorder = theme.colorScheme.primary.withValues(alpha: 0.22);

    return Scaffold(
      backgroundColor: paperColor,
      appBar: _immersiveMode ? null : _buildAppBar(theme),
      body: SafeArea(
        top: !_immersiveMode,
        child: Column(
          children: [
            if (!_immersiveMode && !_hasUnitRange && widget.surahNumber != 9)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: pageSurface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: pageBorder),
                  boxShadow: AppShadows.subtle,
                ),
                width: double.infinity,
                child: SelectableText(
                  l10nOf(context).readerContentMessage3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            Expanded(
              child: _buildBodyContent(
                textColor: textColor,
                pageSurface: pageSurface,
                pageBorder: pageBorder,
              ),
            ),
            if (!_immersiveMode &&
                _surahPages.isNotEmpty &&
                _surahPages.length > 1)
              _buildBottomNavigation(theme, pageSurface, pageBorder),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentSurahPage = index;
    });
    _rememberPage(index);
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10nOf(context).readerControlsMessage6,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                          textAlign: TextAlign.right,
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
                        textAlign: TextAlign.right,
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
                        textAlign: TextAlign.right,
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
