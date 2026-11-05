import 'package:sakina_app/core/utils/arabic_text.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/khatma_model.dart';

class KhatmaAyahPosition {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final String surahName;
  final String ayahText;

  const KhatmaAyahPosition({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.surahName,
    required this.ayahText,
  });
}

class KhatmaQuranLocator {
  static List<Map<String, dynamic>>? _cachedQuran;

  Future<KhatmaAyahPosition> resolveStartPosition({
    required KhatmaTrackingUnit trackingUnit,
    required int unitIndex,
  }) async {
    final List<Map<String, dynamic>> quran = await _loadQuran();

    Map<String, dynamic>? selectedAyah;
    Map<String, dynamic>? selectedSurah;

    switch (trackingUnit) {
      case KhatmaTrackingUnit.page:
        final int targetPage = unitIndex.clamp(1, 604);
        _scanQuran(
          quran,
          pick: (surah, ayah) {
            final int page = (ayah['page'] as num?)?.toInt() ?? 1;
            return page >= targetPage;
          },
          onFound: (surah, ayah) {
            selectedSurah = surah;
            selectedAyah = ayah;
          },
        );
        break;
      case KhatmaTrackingUnit.hizb:
        final int targetQuarter = ((unitIndex.clamp(1, 60) - 1) * 4) + 1;
        _scanQuran(
          quran,
          pick: (surah, ayah) {
            final int hizbQuarter = (ayah['hizbQuarter'] as num?)?.toInt() ?? 1;
            return hizbQuarter >= targetQuarter;
          },
          onFound: (surah, ayah) {
            selectedSurah = surah;
            selectedAyah = ayah;
          },
        );
        break;
      case KhatmaTrackingUnit.juz:
        final int targetJuz = unitIndex.clamp(1, 30);
        _scanQuran(
          quran,
          pick: (surah, ayah) {
            final int juz = (ayah['juz'] as num?)?.toInt() ?? 1;
            return juz >= targetJuz;
          },
          onFound: (surah, ayah) {
            selectedSurah = surah;
            selectedAyah = ayah;
          },
        );
        break;
    }

    selectedSurah ??= quran.last;
    final List<dynamic> fallbackAyahs =
        selectedSurah!['ayahs'] as List<dynamic>? ?? <dynamic>[];
    selectedAyah ??= Map<String, dynamic>.from(
      (fallbackAyahs.isEmpty ? <String, dynamic>{} : fallbackAyahs.last) as Map,
    );

    final int surahNumber = (selectedSurah!['number'] as num?)?.toInt() ?? 1;
    final int ayahNumber =
        (selectedAyah!['numberInSurah'] as num?)?.toInt() ?? 1;
    final int pageNumber = (selectedAyah!['page'] as num?)?.toInt() ?? 1;

    return KhatmaAyahPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber,
      surahName: displaySurahName(selectedSurah!['name']?.toString() ?? ''),
      ayahText: selectedAyah!['text']?.toString() ?? '',
    );
  }

  Future<List<KhatmaAyahPosition>> resolvePositionsForUnitRange({
    required KhatmaTrackingUnit trackingUnit,
    required int fromUnit,
    required int toUnit,
  }) async {
    final List<Map<String, dynamic>> quran = await _loadQuran();
    final int minUnit = fromUnit <= toUnit ? fromUnit : toUnit;
    final int maxUnit = fromUnit <= toUnit ? toUnit : fromUnit;
    final List<KhatmaAyahPosition> positions = <KhatmaAyahPosition>[];

    for (final Map<String, dynamic> surah in quran) {
      final List<dynamic> ayahs =
          surah['ayahs'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic rawAyah in ayahs) {
        final Map<String, dynamic> ayah = Map<String, dynamic>.from(
          rawAyah as Map,
        );
        final int? unitValue = _unitValueForTrackingUnit(trackingUnit, ayah);
        if (unitValue == null || unitValue < minUnit || unitValue > maxUnit) {
          continue;
        }

        positions.add(_positionFromAyah(surah: surah, ayah: ayah));
      }
    }

    return positions;
  }

  Future<KhatmaAyahPosition> resolvePositionFromStoredOrUnit({
    required KhatmaModel khatma,
  }) async {
    final int? storedSurah = khatma.nextSurahNumber;
    final int? storedAyah = khatma.nextAyahNumber;
    final int? storedPage = khatma.nextPageNumber;

    if (storedSurah != null && storedAyah != null && storedPage != null) {
      final List<Map<String, dynamic>> quran = await _loadQuran();
      final Map<String, dynamic> surah = quran
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (item) => (item['number'] as num?)?.toInt() == storedSurah,
            orElse: () => <String, dynamic>{},
          );
      final List<dynamic> ayahs =
          surah['ayahs'] as List<dynamic>? ?? <dynamic>[];
      final Map<String, dynamic> ayah = ayahs
          .map((a) => Map<String, dynamic>.from(a as Map))
          .firstWhere(
            (item) => (item['numberInSurah'] as num?)?.toInt() == storedAyah,
            orElse: () => <String, dynamic>{},
          );

      if (surah.isNotEmpty && ayah.isNotEmpty) {
        return KhatmaAyahPosition(
          surahNumber: storedSurah,
          ayahNumber: storedAyah,
          pageNumber: storedPage,
          surahName: displaySurahName(surah['name']?.toString() ?? ''),
          ayahText: ayah['text']?.toString() ?? '',
        );
      }
    }

    return resolveStartPosition(
      trackingUnit: khatma.trackingUnit,
      unitIndex: khatma.todayFromUnit,
    );
  }

  Future<KhatmaAyahPosition> resolveLastAyah() async {
    final List<Map<String, dynamic>> quran = await _loadQuran();
    final Map<String, dynamic> lastSurah = quran.last;
    final List<dynamic> ayahs =
        lastSurah['ayahs'] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> lastAyah = Map<String, dynamic>.from(
      (ayahs.isEmpty ? <String, dynamic>{} : ayahs.last) as Map,
    );

    return KhatmaAyahPosition(
      surahNumber: (lastSurah['number'] as num?)?.toInt() ?? 114,
      ayahNumber: (lastAyah['numberInSurah'] as num?)?.toInt() ?? 6,
      pageNumber: (lastAyah['page'] as num?)?.toInt() ?? 604,
      surahName: displaySurahName(lastSurah['name']?.toString() ?? ''),
      ayahText: lastAyah['text']?.toString() ?? '',
    );
  }

  void _scanQuran(
    List<Map<String, dynamic>> quran, {
    required bool Function(
      Map<String, dynamic> surah,
      Map<String, dynamic> ayah,
    )
    pick,
    required void Function(
      Map<String, dynamic> surah,
      Map<String, dynamic> ayah,
    )
    onFound,
  }) {
    for (final surah in quran) {
      final List<dynamic> ayahs =
          surah['ayahs'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic rawAyah in ayahs) {
        final Map<String, dynamic> ayah = Map<String, dynamic>.from(
          rawAyah as Map,
        );
        if (pick(surah, ayah)) {
          onFound(surah, ayah);
          return;
        }
      }
    }
  }

  int? _unitValueForTrackingUnit(
    KhatmaTrackingUnit trackingUnit,
    Map<String, dynamic> ayah,
  ) {
    switch (trackingUnit) {
      case KhatmaTrackingUnit.page:
        return (ayah['page'] as num?)?.toInt();
      case KhatmaTrackingUnit.hizb:
        final int? hizbQuarter = (ayah['hizbQuarter'] as num?)?.toInt();
        if (hizbQuarter == null) return null;
        return ((hizbQuarter - 1) ~/ 4) + 1;
      case KhatmaTrackingUnit.juz:
        return (ayah['juz'] as num?)?.toInt();
    }
  }

  KhatmaAyahPosition _positionFromAyah({
    required Map<String, dynamic> surah,
    required Map<String, dynamic> ayah,
  }) {
    return KhatmaAyahPosition(
      surahNumber: (surah['number'] as num?)?.toInt() ?? 1,
      ayahNumber: (ayah['numberInSurah'] as num?)?.toInt() ?? 1,
      pageNumber: (ayah['page'] as num?)?.toInt() ?? 1,
      surahName: displaySurahName(surah['name']?.toString() ?? ''),
      ayahText: ayah['text']?.toString() ?? '',
    );
  }

  Future<List<Map<String, dynamic>>> _loadQuran() async {
    if (_cachedQuran != null) {
      return _cachedQuran!;
    }

    final String jsonString = await rootBundle.loadString(
      'assets/quran_master.json',
    );
    final List<dynamic> jsonData = jsonDecode(jsonString) as List<dynamic>;

    _cachedQuran = jsonData
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return _cachedQuran!;
  }
}
