import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../data/repositories/verse_library_repository.dart';

typedef VerseRef = ({int surah, int ayah});

/// Saved verses and notes for the UI, loaded on first use and kept in
/// memory. Writes go to the database first; a failed write leaves the
/// shown state unchanged and reports false.
class VerseLibraryController extends ChangeNotifier {
  VerseLibraryController(this._repository);

  final VerseLibraryRepository _repository;

  Map<VerseRef, SavedVerse> _saved = {};
  Map<VerseRef, VerseNote> _notes = {};
  bool _loaded = false;
  bool _failed = false;
  Future<void>? _loading;
  bool _disposed = false;

  bool get loaded => _loaded;
  bool get failed => _failed;

  /// Newest first.
  List<SavedVerse> get savedVerses =>
      _saved.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  List<VerseNote> get notes =>
      _notes.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  SavedVerse? savedAt(int surah, int ayah) =>
      _saved[(surah: surah, ayah: ayah)];
  VerseNote? noteAt(int surah, int ayah) => _notes[(surah: surah, ayah: ayah)];

  Future<void> ensureLoaded() => _loaded ? Future.value() : reload();

  Future<void> reload() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    try {
      final saved = await _repository.savedVerses();
      final notes = await _repository.notes();
      _saved = {for (final v in saved) (surah: v.surah, ayah: v.ayah): v};
      _notes = {for (final n in notes) (surah: n.surah, ayah: n.ayah): n};
      _loaded = true;
      _failed = false;
    } catch (error) {
      developer.log(
        'Verse library load failed',
        name: 'sakina_app.library',
        error: error,
      );
      _failed = true;
    }
    if (!_disposed) notifyListeners();
  }

  Future<bool> _write(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      developer.log(
        'Verse library write failed',
        name: 'sakina_app.library',
        error: error,
      );
      return false;
    }
    await _load();
    return true;
  }

  Future<bool> saveVerse(
    int surah,
    int ayah, {
    required int color,
    String? label,
  }) => _write(
    () => _repository.saveVerse(surah, ayah, color: color, label: label),
  );

  Future<bool> removeVerse(int surah, int ayah) =>
      _write(() => _repository.removeVerse(surah, ayah));

  Future<bool> saveNote(int surah, int ayah, String body) =>
      _write(() => _repository.saveNote(surah, ayah, body));

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
