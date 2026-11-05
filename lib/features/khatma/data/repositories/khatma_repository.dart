import 'dart:convert';

import 'package:sakina_app/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/khatma_model.dart';
import '../../domain/models/wird_reading_position.dart';
import '../../domain/repositories/khatma_repository.dart';

export '../../domain/repositories/khatma_repository.dart';

class KhatmaRepositoryImpl implements KhatmaRepository {
  KhatmaRepositoryImpl({required this.prefs});

  static const String _activeKhatmaKey = 'active_khatma_plan';
  static const String _savedWirdPositionKey = 'saved_wird_position';
  final SharedPreferences prefs;

  Result<T?> _read<T>(String key, T Function(Map<String, dynamic>) parse) {
    final String? jsonData = prefs.getString(key);
    if (jsonData == null) return const Success(null);
    try {
      return Success(parse(jsonDecode(jsonData) as Map<String, dynamic>));
    } catch (error) {
      return Err(StorageFailure(cause: error));
    }
  }

  Future<Result<void>> _write(Future<bool> Function() write) =>
      Result.guard(() async {
        if (!await write()) throw StateError('Preference write failed');
      }, onError: (error, _) => StorageFailure(cause: error));

  @override
  Result<KhatmaModel?> getActiveKhatma() =>
      _read(_activeKhatmaKey, KhatmaModel.fromJson);

  @override
  Future<Result<void>> saveKhatma(KhatmaModel khatma) => _write(
    () => prefs.setString(_activeKhatmaKey, jsonEncode(khatma.toJson())),
  );

  @override
  Future<Result<void>> deleteActiveKhatma() =>
      _write(() => prefs.remove(_activeKhatmaKey));

  @override
  Result<WirdReadingPosition?> getSavedWirdPosition() =>
      _read(_savedWirdPositionKey, WirdReadingPosition.fromJson);

  @override
  Future<Result<void>> saveWirdPosition(WirdReadingPosition position) => _write(
    () => prefs.setString(_savedWirdPositionKey, jsonEncode(position.toJson())),
  );

  @override
  Future<Result<void>> clearWirdPosition() =>
      _write(() => prefs.remove(_savedWirdPositionKey));
}
