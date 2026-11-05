import 'package:flutter/foundation.dart';

import '../../domain/entities/guide_entities.dart';
import '../../domain/repositories/islamic_guide_repository.dart';

class IslamicGuideProvider extends ChangeNotifier {
  IslamicGuideProvider({required IslamicGuideRepository repository})
    : _repository = repository;

  final IslamicGuideRepository _repository;
  final Map<QuranRef, Future<List<GuideVerse>>> _verseCache =
      <QuranRef, Future<List<GuideVerse>>>{};

  List<GuideSection> _sections = const <GuideSection>[];
  bool _isLoading = false;
  bool _hasError = false;
  bool _disposed = false;

  List<GuideSection> get sections => _sections;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _notify();
    try {
      _sections = await _repository.getSections();
    } catch (error, stack) {
      _hasError = true;
      debugPrint('Islamic guide failed to load: $error\n$stack');
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Memoised so rebuilding a card does not reload the Quran asset; a failed
  /// lookup is evicted so the user can retry.
  Future<List<GuideVerse>> versesFor(QuranRef ref) {
    return _verseCache.putIfAbsent(ref, () {
      final Future<List<GuideVerse>> future = _repository.resolveQuran(ref);
      future.catchError((Object _) {
        _verseCache.remove(ref);
        return const <GuideVerse>[];
      });
      return future;
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
