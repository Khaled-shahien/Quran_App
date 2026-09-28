import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../domain/entities/surah_entity.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/quran_settings_dialog.dart';

class _SurahPageData {
  final List<_SurahVerseData> verses;
  final int startVerseIndex;

  _SurahPageData(this.verses, this.startVerseIndex);
}

class _SurahVerseData {
  final String text;
  final int surahNumber;
  final int verseNumber;
  final int pageNumber;
  final String surahName;
  final String revelationType;
  final int totalAyah;
  final bool showSurahHeader;
  final bool showBasmala;

  const _SurahVerseData({
    required this.text,
    required this.surahNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.surahName,
    required this.revelationType,
    required this.totalAyah,
    this.showSurahHeader = false,
    this.showBasmala = false,
  });
}

class SurahDetailsScreen extends StatefulWidget {
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
  State<SurahDetailsScreen> createState() => _SurahDetailsScreenState();
}

class _SurahDetailsScreenState extends State<SurahDetailsScreen> {
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
    _loadVerses().then((_) => _focusInitialTarget());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _focusInitialTarget() {
    if (_focusInitialAyahIfProvided()) {
      return;
    }
    if (_focusInitialPageIfProvided()) {
      return;
    }
    _focusBookmarkedPage();
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
        return ((hizbQuarter - 1) ~/ 2) + 1;
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
      mapped['_surahName'] = surahData['name']?.toString() ?? '';
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
        ayah['_surahName'] = surah['name']?.toString() ?? '';
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
        final String verseText = (ayah['text'] as String? ?? '').trim();
        final int verseNumber = (ayah['numberInSurah'] as num?)?.toInt() ?? 1;
        final int pageNumber = (ayah['page'] as num?)?.toInt() ?? 1;
        final int surahNumber =
            (ayah['_surahNumber'] as num?)?.toInt() ?? widget.surahNumber;
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
            showBasmala: false,
          ),
        );
        currentLength += verseText.length;

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
        _error = 'حدث خطأ أثناء تحميل آيات السورة';
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
    final Color pageSurface = theme.brightness == Brightness.dark
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
                  'بِسْمِ اللَّهِ '
                  'الرَّحْمَٰنِ الرَّحِيمِ',
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
        tooltip: 'رجوع',
        icon: Icons.arrow_back_ios,
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
                '${_revelationLabel(revelationType)} • $totalAyah آية',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
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
        _buildAppBarIconButton(
          tooltip: 'خيارات القراءة',
          icon: Icons.tune,
          color: primary,
          onPressed: _showReadingControlsSheet,
        ),
        _buildAppBarIconButton(
          tooltip: 'الإعدادات',
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
      return 'مكية';
    }
    if (normalized.contains('medina') || normalized.contains('medinan')) {
      return 'مدنية';
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
                  tooltip: 'الصفحة السابقة',
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
                      'الصفحة $currentPage من $totalPages',
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
                  tooltip: 'الصفحة التالية',
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
              ? 'تم حفظ موضع الورد الحالي'
              : 'تم حفظ علامة القراءة بنجاح',
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
                      'تخصيص القراءة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'حجم الخط',
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
                        setLocalState(() {});
                      },
                    ),
                    const Text(
                      'تباعد الأسطر',
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
                        setLocalState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _showVerseMarkers,
                      onChanged: (value) {
                        setState(() {
                          _showVerseMarkers = value;
                        });
                        setLocalState(() {});
                      },
                      title: const Text(
                        'إظهار أرقام الآيات',
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
                        setLocalState(() {});
                      },
                      title: const Text(
                        'وضع القراءة الكاملة',
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

class _BookmarkButton extends StatefulWidget {
  final Color color;
  final Future<void> Function() onTap;

  const _BookmarkButton({required this.color, required this.onTap});

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.85,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;

    await widget.onTap();

    if (disableAnimations || !mounted) {
      return;
    }

    await _controller.animateTo(0.85, curve: Curves.easeIn);
    await _controller.animateTo(1, curve: Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: IconButton(
        tooltip: 'حفظ العلامة',
        style: IconButton.styleFrom(
          backgroundColor: widget.color.withValues(alpha: 0.1),
          side: BorderSide(color: widget.color.withValues(alpha: 0.18)),
        ),
        icon: Icon(Icons.bookmark, color: widget.color),
        onPressed: _handleTap,
      ),
    );
  }
}

class _ReaderNavButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ReaderNavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return IconButton(
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(
          alpha: onPressed == null ? 0.04 : 0.1,
        ),
        side: BorderSide(color: color.withValues(alpha: 0.14)),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: onPressed == null ? color.withValues(alpha: 0.35) : color,
      ),
    );
  }
}
