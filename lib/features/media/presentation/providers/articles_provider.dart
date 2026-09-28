import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/media/domain/entities/article.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/usecases/get_articles.dart';

class ArticlesProvider extends ChangeNotifier {
  ArticlesProvider({required GetArticles getArticles})
    : _getArticles = getArticles;

  final GetArticles _getArticles;

  List<Article> _allArticles = <Article>[];
  List<Article> _articles = <Article>[];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedSource;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedSource => _selectedSource;
  bool get hasError => _errorMessage != null;

  List<String> get sourceNames {
    return _allArticles
        .map((article) => article.sourceName)
        .toSet()
        .toList(growable: false);
  }

  Future<void> loadArticles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allArticles = await _getArticles();
      _applySourceFilter(_selectedSource);
    } catch (error) {
      _articles = <Article>[];
      _errorMessage = _messageFrom(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterBySource(String? sourceName) {
    _selectedSource = sourceName;
    _applySourceFilter(sourceName);
    notifyListeners();
  }

  void _applySourceFilter(String? sourceName) {
    if (sourceName == null) {
      _articles = List<Article>.unmodifiable(_allArticles);
      return;
    }

    _articles = _allArticles
        .where((article) => article.sourceName == sourceName)
        .toList(growable: false);
  }

  String _messageFrom(Object error) {
    if (error is MediaException) return error.message;
    return appL10n.articlesProviderMessage1;
  }
}
