part of 'surah_details_screen.dart';

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

mixin _ReaderData on _ReaderState {
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
        if (verseText.isEmpty) continue;

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
}