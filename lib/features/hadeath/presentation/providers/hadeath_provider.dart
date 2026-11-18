import 'package:sakina_app/features/quran/domain/services/quran_search.dart';
import 'package:flutter/foundation.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:sakina_app/core/result/failure_messages.dart';
import 'package:sakina_app/core/result/result.dart';
import '../../domain/entities/hadeath_entity.dart';
import '../../domain/repositories/hadeath_repository.dart';

class HadeathProvider extends ChangeNotifier {
  final HadeathRepository repository;

  List<HadeathEntity> _ahadethList = [];
  bool _isLoading = false;
  String? _errorMessage;

  HadeathProvider({required this.repository});

  List<HadeathEntity> get ahadethList => _ahadethList;

  String _query = '';
  String get query => _query;

  /// The hadith matching [query] (title, text or explanation; marks and
  /// hamza forms ignored), in order, with their number in the collection.
  List<({int number, HadeathEntity hadeath})> get visible {
    final needle = normalizeArabicSearch(_query).trim();
    return [
      for (final (i, h) in _ahadethList.indexed)
        if (needle.isEmpty ||
            normalizeArabicSearch(
              '${h.title} ${h.content.join(' ')} ${h.study?.explanation ?? ''}',
            ).contains(needle))
          (number: i + 1, hadeath: h),
    ];
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Loads all Ahadeth from the repository
  Future<void> loadAhadeth() async {
    // Prevent multiple concurrent loads
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    switch (await repository.getAllAhadeth()) {
      case Success(:final value):
        _ahadethList = value;
      case Err(:final failure):
        // Friendly copy only; the technical cause is never shown.
        _errorMessage = appL10n.hadeathProviderMessage1(
          failureMessage(failure),
        );
    }
    _isLoading = false;
    notifyListeners();
  }
}
