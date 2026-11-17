import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/adhan_voices.dart';

/// Plays a bundled adhan in settings so the user can hear it before
/// choosing it. Only one recording plays at a time.
abstract class AdhanPreviewPlayer {
  /// Id of the recording playing now, or null.
  ValueListenable<String?> get playing;

  /// Starts [voice] from the beginning. Throws when it cannot be played.
  Future<void> play(AdhanVoice voice);

  Future<void> stop();

  void dispose();
}

/// [AdhanPreviewPlayer] on just_audio, reading the same Android raw
/// resource the notification channel plays, so the preview is exactly what
/// the alert will sound like.
class JustAudioAdhanPreviewPlayer implements AdhanPreviewPlayer {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _state;
  final ValueNotifier<String?> _playing = ValueNotifier<String?>(null);

  @override
  ValueListenable<String?> get playing => _playing;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _state = player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _playing.value = null;
      }
    }, onError: (Object _) => _playing.value = null);
    return _player = player;
  }

  @override
  Future<void> play(AdhanVoice voice) async {
    final player = _ensurePlayer();
    await player.stop();
    try {
      await player.setAudioSource(AudioSource.uri(voice.previewUri));
    } catch (_) {
      _playing.value = null;
      rethrow;
    }
    _playing.value = voice.id;
    // play() completes when playback ends; do not hold the caller.
    unawaited(
      player.play().catchError((Object _) {
        _playing.value = null;
      }),
    );
  }

  @override
  Future<void> stop() async {
    _playing.value = null;
    await _player?.stop();
  }

  @override
  void dispose() {
    unawaited(_state?.cancel());
    unawaited(_player?.dispose());
    _playing.dispose();
  }
}
