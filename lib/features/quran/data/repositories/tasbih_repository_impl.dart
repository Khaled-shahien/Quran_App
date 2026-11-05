import 'dart:convert';

import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/quran/domain/entities/tasbih_phrase.dart';
import 'package:sakina_app/features/quran/domain/repositories/tasbih_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesTasbihRepository implements TasbihRepository {
  SharedPreferencesTasbihRepository(this._prefs);

  static const String storageKey = 'tasbih_state_v1';

  final SharedPreferences _prefs;

  @override
  Result<TasbihSnapshot?> load() {
    final Object? raw = _prefs.get(storageKey);
    if (raw == null) return const Success(null);
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      final phrases = <TasbihPhrase>[
        for (final entry in decoded['phrases'] as List<dynamic>)
          ?TasbihPhrase.fromJson(entry),
      ];
      final selected = decoded['selected'];
      return Success(
        TasbihSnapshot(
          phrases: phrases,
          selectedIndex: selected is int ? selected : 0,
        ),
      );
    } catch (error) {
      return Err(StorageFailure(cause: error));
    }
  }

  @override
  Future<Result<void>> save(TasbihSnapshot snapshot) => Result.guard(() async {
    final saved = await _prefs.setString(
      storageKey,
      jsonEncode(<String, Object?>{
        'selected': snapshot.selectedIndex,
        'phrases': [for (final phrase in snapshot.phrases) phrase.toJson()],
      }),
    );
    if (!saved) throw StateError('Tasbih state was not saved');
  }, onError: (error, _) => StorageFailure(cause: error));
}
