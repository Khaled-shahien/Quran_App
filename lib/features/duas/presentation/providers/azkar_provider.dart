import 'package:flutter/foundation.dart';
import 'package:sakina_app/core/result/failure_messages.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/domain/repositories/azkar_repository.dart';

class AzkarProvider extends ChangeNotifier {
  final AzkarRepository _repository;

  List<AzkarCategoryModel> _categories = [];
  bool _isLoading = false;
  Failure? _failure;
  bool _disposed = false;

  AzkarProvider({required AzkarRepository repository})
    : _repository = repository;

  List<AzkarCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  /// Localized, user-facing message; null when there is no failure.
  String? get errorMessage =>
      _failure == null ? null : failureMessage(_failure!);

  Future<void> loadAzkar() async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final result = await _repository.getAllAzkar();
    if (_disposed) return;
    switch (result) {
      case Success(:final value):
        _categories = value;
      case Err(:final failure):
        _failure = failure;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Get a specific category by its name (exact match)
  AzkarCategoryModel? getCategoryByName(String name) {
    for (final category in _categories) {
      if (category.category == name) return category;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
