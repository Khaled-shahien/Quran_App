import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/duas_repository.dart';

class DuasProvider extends ChangeNotifier {
  final DuasRepository _repository;

  List<AzkarCategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  DuasProvider({required DuasRepository repository}) : _repository = repository;

  List<AzkarCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDuas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.getAllDuas();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a specific category by its name (exact match)
  AzkarCategoryModel? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((cat) => cat.category == name);
    } catch (e) {
      return null;
    }
  }
}
