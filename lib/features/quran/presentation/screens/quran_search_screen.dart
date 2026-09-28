import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_ar.dart';
import 'package:flutter/material.dart';
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
  String _query = '';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
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
                hintText: l10n.searchHint,
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
                : _results.isEmpty
                ? Center(child: Text(l10n.searchEmpty))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
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
