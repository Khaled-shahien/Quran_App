import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/azkar_model.dart';

/// Counts how many times each dhikr in one category has been said today.
///
/// Progress is saved after every tap, survives the app being closed, and
/// starts fresh on a new day.
class AdhkarProgressController extends ChangeNotifier {
  AdhkarProgressController({
    required SharedPreferences preferences,
    required this.category,
    required List<AzkarItemModel> items,
    DateTime Function()? clock,
  }) : _prefs = preferences,
       _items = List.unmodifiable(items),
       _clock = clock ?? DateTime.now {
    _load();
  }

  final SharedPreferences _prefs;
  final String category;
  final List<AzkarItemModel> _items;
  final DateTime Function() _clock;
  Map<int, int> _counts = {};
  bool _disposed = false;

  String get _key => 'adhkar_progress_v1_$category';

  String get _today {
    final d = _clock();
    return '${d.year}-${d.month}-${d.day}';
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (decoded['day'] != _today) return; // yesterday's progress
      final counts = decoded['counts'] as Map<String, dynamic>;
      _counts = {
        for (final e in counts.entries)
          if (int.tryParse(e.key) case final id? when e.value is int)
            id: e.value as int,
      };
    } catch (_) {
      _counts = {};
    }
  }

  int countOf(AzkarItemModel item) =>
      (_counts[item.id] ?? 0).clamp(0, _target(item));

  int _target(AzkarItemModel item) => item.repeat < 1 ? 1 : item.repeat;

  int targetOf(AzkarItemModel item) => _target(item);

  bool isComplete(AzkarItemModel item) => countOf(item) >= _target(item);

  bool get allComplete => _items.isNotEmpty && _items.every(isComplete);

  int get completedItems => _items.where(isComplete).length;

  /// Counts one recitation. Returns true when this tap completed the dhikr.
  /// Extra taps after completion are ignored, so the count never overshoots.
  bool increment(AzkarItemModel item) {
    if (isComplete(item)) return false;
    _counts[item.id] = countOf(item) + 1;
    _save();
    _notify();
    return isComplete(item);
  }

  /// Clears today's progress and returns it, for undo.
  Map<int, int> reset() {
    final before = Map<int, int>.of(_counts);
    _counts = {};
    _save();
    _notify();
    return before;
  }

  void restore(Map<int, int> snapshot) {
    _counts = Map<int, int>.of(snapshot);
    _save();
    _notify();
  }

  void _save() {
    unawaited(
      _prefs.setString(
        _key,
        jsonEncode({
          'day': _today,
          'counts': {for (final e in _counts.entries) '${e.key}': e.value},
        }),
      ),
    );
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
