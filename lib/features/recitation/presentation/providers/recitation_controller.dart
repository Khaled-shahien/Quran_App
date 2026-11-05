import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sakina_app/core/audio/recitation_audio_engine.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/recitation.dart';
import '../../domain/repositories/recitation_repository.dart';

enum RecitationStatus { idle, loading, buffering, playing, paused, error }

/// Repeat ayahs [from]..[to] of the current surah [times] times in total.
class RepeatRange {
  const RepeatRange({required this.from, required this.to, required this.times})
    : assert(from <= to),
      assert(times >= 1);

  final int from;
  final int to;
  final int times;
}

/// The single Quran recitation player for the whole app.
class RecitationController extends ChangeNotifier {
  RecitationController({
    required RecitationRepository repository,
    required RecitationAudioEngine engine,
    required SharedPreferences preferences,
    required String Function(int surah) surahName,
  }) : _repository = repository,
       _engine = engine,
       _prefs = preferences,
       _surahName = surahName {
    _subscriptions.addAll([
      _engine.positionStream.listen(_onPosition),
      _engine.statusStream.listen(_onStatus),
      _engine.playingStream.listen(_onPlaying),
      _engine.errorStream.listen(_onError),
      _engine.remoteCommands.listen(_onRemote),
    ]);
    final speed = _prefs.getDouble(_speedKey);
    if (speed != null && speeds.contains(speed)) _speed = speed;
    final surah = _prefs.getInt(_surahKey);
    final ayah = _prefs.getInt(_ayahKey);
    if (surah != null && surah >= 1 && surah <= 114) {
      _resumeSurah = surah;
      _resumeAyah = ayah != null && ayah >= 1 ? ayah : 1;
    }
  }

  static const List<double> speeds = [0.5, 0.75, 1.0, 1.25, 1.5];
  static const int defaultReciterId = 7;
  static const String _reciterKey = 'recitation_reciter_id';
  static const String _speedKey = 'recitation_speed';
  static const String _surahKey = 'recitation_last_surah';
  static const String _ayahKey = 'recitation_last_ayah';

  final RecitationRepository _repository;
  final RecitationAudioEngine _engine;
  final SharedPreferences _prefs;
  final String Function(int surah) _surahName;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  List<RecitationReciter> _reciters = const [];
  RecitationReciter? _reciter;
  ChapterRecitation? _chapter;
  int? _currentAyah;
  RecitationStatus _status = RecitationStatus.idle;
  Failure? _failure;
  double _speed = 1.0;
  RepeatRange? _repeat;
  int _repeatsDone = 0;
  int? _resumeSurah;
  int _resumeAyah = 1;
  bool _wasPlayingBeforeInterruption = false;
  int _loadToken = 0;
  bool _disposed = false;

  List<RecitationReciter> get reciters => _reciters;
  RecitationReciter? get reciter => _reciter;
  int? get surah => _chapter?.surah;
  int? get currentAyah => _currentAyah;
  RecitationStatus get status => _status;
  Failure? get failure => _failure;
  double get speed => _speed;
  RepeatRange? get repeat => _repeat;
  bool get isActive => _chapter != null && _status != RecitationStatus.idle;
  bool get isPlaying => _status == RecitationStatus.playing;

  /// Number of ayahs in the playing surah (0 when nothing is loaded).
  int get ayahCount => _chapter?.timings.length ?? 0;

  /// Where the listener stopped last time (survives restarts).
  ({int surah, int ayah})? get resumePoint {
    final s = _resumeSurah;
    return s == null ? null : (surah: s, ayah: _resumeAyah);
  }

  /// Loads the reciter list and restores the last chosen reciter.
  Future<void> initialize() async {
    final result = await _repository.reciters();
    if (_disposed) return;
    switch (result) {
      case Success(:final value):
        _reciters = value;
        final saved = _prefs.getInt(_reciterKey) ?? defaultReciterId;
        _reciter = value.firstWhere(
          (r) => r.id == saved,
          orElse: () => value.first,
        );
      case Err(:final failure):
        _failure = failure;
    }
    _notify();
  }

  /// Plays [surah] from [fromAyah] with the selected reciter.
  Future<void> playSurah(int surah, {int fromAyah = 1}) async {
    if (_reciter == null) await initialize();
    final reciter = _reciter;
    if (reciter == null || _disposed) return;
    final token = ++_loadToken;
    _status = RecitationStatus.loading;
    _failure = null;
    _repeat = null;
    _notify();

    final chapterResult = await _repository.chapter(reciter.id, surah);
    final sourceResult = await _repository.playableSource(reciter.id, surah);
    if (_disposed || token != _loadToken) return;
    final ChapterRecitation chapter;
    final String source;
    switch ((chapterResult, sourceResult)) {
      case (Success(value: final c), Success(value: final s)):
        chapter = c;
        source = s;
      case (Err(:final failure), _) || (_, Err(:final failure)):
        _fail(failure);
        return;
    }

    _chapter = chapter;
    final ayah = chapter.timingOf(fromAyah) == null ? 1 : fromAyah;
    _currentAyah = ayah;
    try {
      await _engine.load(
        source,
        info: NowPlayingInfo(
          id: '${reciter.id}/$surah',
          title: _surahName(surah),
          subtitle: reciter.name,
        ),
        start: chapter.timingOf(ayah)?.from ?? Duration.zero,
      );
      if (_disposed || token != _loadToken) return;
      await _engine.setSpeed(_speed);
      await _engine.play();
    } catch (error) {
      if (token == _loadToken) _fail(_failureFrom(error));
      return;
    }
    _remember(surah, ayah);
  }

  Future<void> togglePlay() async {
    if (_chapter == null) {
      final resume = resumePoint;
      if (resume != null) {
        await playSurah(resume.surah, fromAyah: resume.ayah);
      }
      return;
    }
    // After an error the engine may still report "playing"; retry first.
    if (_status == RecitationStatus.error) {
      await playSurah(_chapter!.surah, fromAyah: _currentAyah ?? 1);
    } else if (_engine.playing) {
      await _engine.pause();
    } else {
      await _engine.play();
    }
  }

  Future<void> pause() => _engine.pause();

  Future<void> stop() async {
    _loadToken++;
    _repeat = null;
    await _engine.stop();
    _chapter = null;
    _currentAyah = null;
    _status = RecitationStatus.idle;
    _notify();
  }

  Future<void> seekToAyah(int ayah) async {
    final timing = _chapter?.timingOf(ayah);
    if (timing == null) return;
    _currentAyah = ayah;
    _notify();
    await _engine.seek(timing.from);
  }

  Future<void> nextAyah() async {
    final current = _currentAyah;
    final chapter = _chapter;
    if (current == null || chapter == null) return;
    if (chapter.timingOf(current + 1) != null) {
      await seekToAyah(current + 1);
    } else if (chapter.surah < 114) {
      await playSurah(chapter.surah + 1);
    }
  }

  Future<void> previousAyah() async {
    final current = _currentAyah;
    if (current == null) return;
    await seekToAyah(current > 1 ? current - 1 : 1);
  }

  Future<void> setSpeed(double speed) async {
    if (!speeds.contains(speed)) return;
    _speed = speed;
    await _prefs.setDouble(_speedKey, speed);
    _notify();
    if (_chapter != null) await _engine.setSpeed(speed);
  }

  /// Repeats ayahs [from]..[to] [times] times in total, starting now.
  Future<void> setRepeat(int from, int to, int times) async {
    final chapter = _chapter;
    if (chapter == null ||
        times < 1 ||
        from > to ||
        chapter.timingOf(from) == null ||
        chapter.timingOf(to) == null) {
      return;
    }
    _repeat = RepeatRange(from: from, to: to, times: times);
    _repeatsDone = 0;
    _notify();
    await seekToAyah(from);
    if (!_engine.playing) await _engine.play();
  }

  void clearRepeat() {
    _repeat = null;
    _notify();
  }

  Future<void> selectReciter(RecitationReciter reciter) async {
    if (reciter == _reciter) return;
    _reciter = reciter;
    await _prefs.setInt(_reciterKey, reciter.id);
    _notify();
    final chapter = _chapter;
    if (chapter != null) {
      await playSurah(chapter.surah, fromAyah: _currentAyah ?? 1);
    }
  }

  /// Pauses for something more important (e.g. the adhan). Returns whether
  /// recitation was playing, so the caller can offer to resume.
  Future<bool> pauseForInterruption() async {
    _wasPlayingBeforeInterruption = _engine.playing;
    if (_wasPlayingBeforeInterruption) await _engine.pause();
    return _wasPlayingBeforeInterruption;
  }

  Future<void> resumeAfterInterruption() async {
    if (_wasPlayingBeforeInterruption && _chapter != null) {
      _wasPlayingBeforeInterruption = false;
      await _engine.play();
    }
  }

  void _onPosition(Duration position) {
    final chapter = _chapter;
    if (chapter == null) return;
    final repeat = _repeat;
    if (repeat != null) {
      final end = chapter.timingOf(repeat.to)!.to;
      if (position >= end) {
        _completeRepeatPass();
        return;
      }
    }
    final ayah = chapter.ayahAt(position);
    if (ayah != null && ayah != _currentAyah) {
      _currentAyah = ayah;
      _remember(chapter.surah, ayah);
      _notify();
    }
  }

  void _completeRepeatPass() {
    final repeat = _repeat;
    final chapter = _chapter;
    if (repeat == null || chapter == null) return;
    _repeatsDone++;
    if (_repeatsDone < repeat.times) {
      _currentAyah = repeat.from;
      unawaited(_engine.seek(chapter.timingOf(repeat.from)!.from));
      if (!_engine.playing) unawaited(_engine.play());
    } else {
      // Done repeating: carry on with the rest of the surah.
      _repeat = null;
    }
    _notify();
  }

  void _onStatus(EngineStatus status) {
    switch (status) {
      case EngineStatus.loading:
        if (_status != RecitationStatus.loading) {
          _status = RecitationStatus.loading;
          _notify();
        }
      case EngineStatus.buffering:
        _status = RecitationStatus.buffering;
        _notify();
      case EngineStatus.ready:
        _status = _engine.playing
            ? RecitationStatus.playing
            : RecitationStatus.paused;
        _notify();
      case EngineStatus.completed:
        if (_repeat != null) {
          _completeRepeatPass();
        } else {
          _status = RecitationStatus.paused;
          _notify();
        }
      case EngineStatus.idle:
        break;
    }
  }

  void _onPlaying(bool playing) {
    if (_chapter == null ||
        _status == RecitationStatus.loading ||
        _status == RecitationStatus.buffering ||
        _status == RecitationStatus.error) {
      return;
    }
    _status = playing ? RecitationStatus.playing : RecitationStatus.paused;
    _notify();
  }

  void _onError(Object error) => _fail(_failureFrom(error));

  void _onRemote(RemoteCommand command) {
    final chapter = _chapter;
    if (chapter == null) return;
    switch (command) {
      case RemoteCommand.skipToNext when chapter.surah < 114:
        unawaited(playSurah(chapter.surah + 1));
      case RemoteCommand.skipToPrevious when chapter.surah > 1:
        unawaited(playSurah(chapter.surah - 1));
      default:
        break;
    }
  }

  static Failure _failureFrom(Object error) {
    final text = error.toString().toLowerCase();
    final network =
        text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('host');
    return network
        ? NetworkFailure(cause: error)
        : UnexpectedFailure(cause: error);
  }

  void _fail(Failure failure) {
    _failure = failure;
    _status = RecitationStatus.error;
    _notify();
  }

  void _remember(int surah, int ayah) {
    _resumeSurah = surah;
    _resumeAyah = ayah;
    unawaited(_prefs.setInt(_surahKey, surah));
    unawaited(_prefs.setInt(_ayahKey, ayah));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
