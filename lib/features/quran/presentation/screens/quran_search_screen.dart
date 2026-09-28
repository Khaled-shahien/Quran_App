import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_ar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/ayah_entity.dart';
import '../../domain/repositories/ayah_repository.dart';
import '../../domain/services/quran_search.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key, this.repository});
  final AyahRepository? repository;
  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  Map<int, List<AyahEntity>>? _source;
  List<QuranSearchResult> _results = [];
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> get _matchingSurahs {
    final query = normalizeArabicSearch(_query).trim().replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => (m[0]!.codeUnitAt(0) - 0x660).toString(),
    );
    if (query.isEmpty) return [];
    return _surahs
        .where(
          (surah) =>
              surah['number'].toString() == query ||
              normalizeArabicSearch(surah['name'] as String).contains(query) ||
              normalizeArabicSearch(
                surah['englishName'] as String,
              ).contains(query),
        )
        .toList();
  }

  String _query = '';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSurahNames();
  }

  Future<void> _loadSurahNames() async {
    try {
      final decoded =
          jsonDecode(await rootBundle.loadString('assets/quran_master.json'));
      if (decoded is! List) {
        throw const FormatException('Quran metadata must be a list');
      }

      final data = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(
            (surah) =>
                surah['number'] != null &&
                surah['name'] is String &&
                surah['englishName'] is String,
          )
          .toList();
      if (mounted) setState(() => _surahs = data);
    } catch (error) {
      debugPrint('Surah metadata load failed: $error');
    }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final data = await (widget.repository ?? getIt<AyahRepository>())
          .getAllAyahs();
      if (data.length != 114 || data.values.any((ayahs) => ayahs.isEmpty)) {
        throw StateError('Incomplete Quran search index');
      }
      if (!mounted) return;
      setState(() {
        _source = data;
        _results = searchQuran(data, _query);
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsAr();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l10n.searchQuran)),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.searchAyah,
                hintText: 'اسم السورة أو رقمها أو جزء من آية',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() {
                _query = value;
                _results = searchQuran(_source ?? {}, value);
              }),
            ),
          ),
          Expanded(
            child: _failed
                ? Center(
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('تعذر تحميل القرآن. إعادة المحاولة'),
                    ),
                  )
                : _source == null
                ? const Center(child: CircularProgressIndicator())
                : _query.trim().isEmpty
                ? const Center(child: Text('اكتب كلمة أو جزءاً من آية'))
                : _results.isEmpty && _matchingSurahs.isEmpty
                ? Center(child: Text(l10n.searchEmpty))
                : ListView.builder(
                    itemCount: _matchingSurahs.length + _results.length,
                    itemBuilder: (context, index) {
                      final surahs = _matchingSurahs;
                      if (index < surahs.length) {
                        final surah = surahs[index];
                        return ListTile(
                          leading: const Icon(Icons.menu_book),
                          title: Text(surah['name'] as String),
                          subtitle: Text('سورة ${surah['number']}'),
                          onTap: () =>
                              context.push('/quran/surah/${surah['number']}'),
                        );
                      }
                      final result = _results[index - surahs.length];
                      final text = result.ayah.text;
                      return ListTile(
                        title: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: text.substring(0, result.start)),
                              TextSpan(
                                text: text.substring(result.start, result.end),
                                style: TextStyle(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: text.substring(result.end)),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          'سورة ${result.surahNumber} • آية ${result.ayah.numberInSurah}',
                        ),
                        onTap: () => context.push(
                          '/quran/surah/${result.surahNumber}',
                          extra: {
                            'initialSurahNumber': result.surahNumber,
                            'initialAyahNumber': result.ayah.numberInSurah,
                            'initialPageNumber': result.ayah.page,
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
