import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sakina_app/core/result/result.dart';

import '../../domain/entities/recitation.dart';
import '../../domain/repositories/recitation_repository.dart';

/// App-wide download state, so a download keeps going while the user moves
/// between screens and every screen shows the same progress.
class RecitationDownloadsController extends ChangeNotifier {
  RecitationDownloadsController({required RecitationRepository repository})
    : _repository = repository;

  final RecitationRepository _repository;
  final Map<(int, int), DownloadProgress> _active = {};
  final Map<(int, int), StreamSubscription<DownloadProgress>> _subs = {};
  List<DownloadedSurah> _downloads = const [];
  final Set<(int, int)> _pendingDelete = {};
  bool _loaded = false;
  bool _disposed = false;

  /// Downloads on the device, minus any waiting for undo to expire.
  List<DownloadedSurah> get downloads => [
    for (final d in _downloads)
      if (!_pendingDelete.contains((d.reciterId, d.surah))) d,
  ];

  bool get loaded => _loaded;

  DownloadProgress? progressOf(int reciterId, int surah) =>
      _active[(reciterId, surah)];

  bool isDownloaded(int reciterId, int surah) =>
      !_pendingDelete.contains((reciterId, surah)) &&
      _downloads.any((d) => d.reciterId == reciterId && d.surah == surah);

  Future<void> refresh() async {
    final result = await _repository.downloads();
    if (_disposed) return;
    _downloads = result.valueOrNull ?? const [];
    _loaded = true;
    _notify();
  }

  /// Size in bytes, to show before the user confirms a download.
  Future<Result<int>> sizeOf(int reciterId, int surah) =>
      _repository.downloadSize(reciterId, surah);

  /// Starts a download; completes with true when the file is saved.
  Future<bool> start(int reciterId, int surah) {
    final key = (reciterId, surah);
    if (_subs.containsKey(key)) return Future.value(false);
    final done = Completer<bool>();
    _active[key] = const DownloadProgress(received: 0);
    _notify();
    _subs[key] = _repository
        .download(reciterId, surah)
        .listen(
          (progress) {
            _active[key] = progress;
            _notify();
          },
          onError: (Object _) {
            _finish(key);
            if (!done.isCompleted) done.complete(false);
          },
          onDone: () async {
            _finish(key);
            await refresh();
            if (!done.isCompleted) done.complete(true);
          },
          cancelOnError: true,
        );
    return done.future;
  }

  Future<void> cancel(int reciterId, int surah) async {
    final key = (reciterId, surah);
    await _subs[key]?.cancel();
    _finish(key);
  }

  /// Hides the download now and deletes it unless [undo] is called before
  /// [delay] passes, so a mistaken tap never loses a large file.
  void deleteWithUndo(
    int reciterId,
    int surah, {
    Duration delay = const Duration(seconds: 5),
  }) {
    final key = (reciterId, surah);
    _pendingDelete.add(key);
    _notify();
    Timer(delay, () async {
      if (!_pendingDelete.remove(key)) return;
      await _repository.deleteDownload(reciterId, surah);
      await refresh();
    });
  }

  void undoDelete(int reciterId, int surah) {
    if (_pendingDelete.remove((reciterId, surah))) _notify();
  }

  void _finish((int, int) key) {
    _active.remove(key);
    _subs.remove(key);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs.values) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
