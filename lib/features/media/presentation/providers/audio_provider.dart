import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/media/domain/entities/reciter.dart';
import 'package:sakina_app/features/media/domain/entities/surah_audio.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/usecases/get_reciters.dart';
import 'package:sakina_app/features/media/domain/usecases/get_surah_audios.dart';

class AudioProvider extends ChangeNotifier {
  AudioProvider({
    required GetReciters getReciters,
    required GetSurahAudios getSurahAudios,
  }) : _getReciters = getReciters,
       _getSurahAudios = getSurahAudios;

  static const List<int> _featuredIds = <int>[1, 5, 3, 137, 6];

  final GetReciters _getReciters;
  final GetSurahAudios _getSurahAudios;

  List<Reciter> _reciters = <Reciter>[];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Reciter> get reciters => _reciters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;

  List<Reciter> get filteredReciters {
    final query = _searchQuery.trim();
    if (query.isEmpty) return _reciters;

    return _reciters
        .where((reciter) => reciter.name.contains(query))
        .toList(growable: false);
  }

  List<Reciter> get featuredReciters {
    final byId = <int, Reciter>{
      for (final reciter in _reciters) reciter.id: reciter,
    };

    return _featuredIds
        .map((id) => byId[id])
        .whereType<Reciter>()
        .toList(growable: false);
  }

  Future<void> loadReciters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reciters = await _getReciters();
    } catch (error) {
      _reciters = <Reciter>[];
      _errorMessage = _messageFrom(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<List<SurahAudio>> getSurahAudios(Reciter reciter) {
    return _getSurahAudios(reciter);
  }

  String _messageFrom(Object error) {
    if (error is MediaException) return error.message;
    return 'حدث خطأ غير متوقع، حاول مرة أخرى';
  }
}
