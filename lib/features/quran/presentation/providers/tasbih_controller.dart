import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/quran/domain/entities/tasbih_phrase.dart';
import 'package:sakina_app/features/quran/domain/repositories/tasbih_repository.dart';

/// Built-in phrase ids, in their original order. Text comes from l10n.
const List<String> builtInTasbihIds = <String>[
  'builtin_subhan_allah',
  'builtin_alhamdulillah',
  'builtin_la_ilaha_illallah',
  'builtin_allahu_akbar',
];

/// Restores a removed phrase at its old position.
class RemovedTasbihPhrase {
  const RemovedTasbihPhrase._(this.phrase, this.index, this.wasSelected);
  final TasbihPhrase phrase;
  final int index;
  final bool wasSelected;
}

/// Tasbih state and rules. Every change is persisted, so counts survive the
/// app being killed or updated.
class TasbihController extends ChangeNotifier {
  TasbihController({required TasbihRepository repository})
    : _repository = repository {
    final loaded = repository.load();
    final snapshot = loaded.valueOrNull;
    if (loaded.failureOrNull case final failure?) {
      developer.log(
        'Tasbih state unreadable; starting from defaults',
        name: 'sakina_app.tasbih',
        error: failure.cause,
      );
    }
    if (snapshot != null) {
      _phrases = List<TasbihPhrase>.of(snapshot.phrases);
      _selectedIndex = snapshot.selectedIndex;
    } else {
      _phrases = <TasbihPhrase>[
        for (final id in builtInTasbihIds) TasbihPhrase(id: id),
      ];
    }
    _clampSelection();
  }

  final TasbihRepository _repository;
  late List<TasbihPhrase> _phrases;
  int _selectedIndex = 0;
  Future<void> _pendingSave = Future<void>.value();

  List<TasbihPhrase> get phrases => List<TasbihPhrase>.unmodifiable(_phrases);
  int get selectedIndex => _selectedIndex;
  TasbihPhrase? get selected =>
      _phrases.isEmpty ? null : _phrases[_selectedIndex];

  /// Count of the selected phrase (0 when there are no phrases).
  int get count => selected?.count ?? 0;

  /// Completes once every change so far has been written.
  Future<void> get saved => _pendingSave;

  /// Adds one to the selected phrase. Returns true when this tap completed
  /// the phrase's target, so callers can give distinct feedback.
  bool increment() {
    final current = selected;
    if (current == null) return false;
    final next = current.copyWith(count: current.count + 1);
    _phrases[_selectedIndex] = next;
    _changed();
    return next.target > 0 && next.count == next.target;
  }

  void select(int index) {
    if (index < 0 || index >= _phrases.length || index == _selectedIndex) {
      return;
    }
    _selectedIndex = index;
    _changed();
  }

  /// Adds a user phrase; blank text is ignored. Text is kept as typed apart
  /// from surrounding whitespace.
  void add(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _phrases.add(
      TasbihPhrase(
        id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
        customText: trimmed,
      ),
    );
    _changed();
  }

  RemovedTasbihPhrase? removeAt(int index) {
    if (index < 0 || index >= _phrases.length) return null;
    final removed = RemovedTasbihPhrase._(
      _phrases.removeAt(index),
      index,
      index == _selectedIndex,
    );
    if (_selectedIndex > index || (removed.wasSelected && _selectedIndex > 0)) {
      _selectedIndex--;
    }
    _clampSelection();
    _changed();
    return removed;
  }

  void restore(RemovedTasbihPhrase removed) {
    final index = removed.index.clamp(0, _phrases.length);
    _phrases.insert(index, removed.phrase);
    if (removed.wasSelected) {
      _selectedIndex = index;
    } else if (_selectedIndex >= index && _phrases.length > 1) {
      _selectedIndex++;
    }
    _clampSelection();
    _changed();
  }

  /// Zeroes every count and returns what was there, for undo.
  TasbihSnapshot reset() {
    final before = TasbihSnapshot(
      phrases: List<TasbihPhrase>.of(_phrases),
      selectedIndex: _selectedIndex,
    );
    _phrases = [for (final phrase in _phrases) phrase.copyWith(count: 0)];
    _changed();
    return before;
  }

  void undoReset(TasbihSnapshot before) {
    _phrases = List<TasbihPhrase>.of(before.phrases);
    _selectedIndex = before.selectedIndex;
    _clampSelection();
    _changed();
  }

  void _clampSelection() {
    _selectedIndex = _phrases.isEmpty
        ? 0
        : _selectedIndex.clamp(0, _phrases.length - 1);
  }

  void _changed() {
    notifyListeners();
    final snapshot = TasbihSnapshot(
      phrases: List<TasbihPhrase>.of(_phrases),
      selectedIndex: _selectedIndex,
    );
    // Writes are chained so an older state can never land after a newer one.
    _pendingSave = _pendingSave.then((_) async {
      final result = await _repository.save(snapshot);
      if (result.failureOrNull case final failure?) {
        developer.log(
          'Tasbih state could not be saved',
          name: 'sakina_app.tasbih',
          error: failure.cause,
        );
      }
    });
  }
}
