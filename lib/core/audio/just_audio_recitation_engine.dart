import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'recitation_audio_engine.dart';

/// [RecitationAudioEngine] on just_audio, published to the lock screen and
/// notification through audio_service so recitation keeps playing in the
/// background and with the screen locked.
///
/// Audio focus: the session is configured for spoken audio, so phone calls
/// and other apps pause recitation and it resumes when they finish.
class JustAudioRecitationEngine implements RecitationAudioEngine {
  JustAudioRecitationEngine({required this.notificationChannelName});

  final String notificationChannelName;

  /// Created on first use, so merely registering the engine costs nothing.
  late final AudioPlayer _player = AudioPlayer();
  final _remote = StreamController<RemoteCommand>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  _Handler? _handler;
  Future<void>? _init;

  Future<void> _ensureInitialized() => _init ??= () async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _handler = await AudioService.init(
      builder: () => _Handler(_player, _remote),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'sakina_recitation_playback',
        androidNotificationChannelName: notificationChannelName,
        androidNotificationIcon: 'drawable/ic_notification',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace _) => _errors.add(error),
    );
  }();

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Stream<RemoteCommand> get remoteCommands => _remote.stream;

  @override
  Stream<Object> get errorStream => _errors.stream;

  @override
  Stream<EngineStatus> get statusStream => _player.processingStateStream.map(
    (s) => switch (s) {
      ProcessingState.idle => EngineStatus.idle,
      ProcessingState.loading => EngineStatus.loading,
      ProcessingState.buffering => EngineStatus.buffering,
      ProcessingState.ready => EngineStatus.ready,
      ProcessingState.completed => EngineStatus.completed,
    },
  );

  @override
  Duration get position => _player.position;

  @override
  bool get playing => _player.playing;

  @override
  Future<void> load(
    String source, {
    required NowPlayingInfo info,
    Duration start = Duration.zero,
  }) async {
    await _ensureInitialized();
    final item = MediaItem(
      id: info.id,
      title: info.title,
      artist: info.subtitle,
      album: info.subtitle,
    );
    _handler?.mediaItem.add(item);
    final uri = source.startsWith('https://')
        ? Uri.parse(source)
        : Uri.file(source);
    try {
      await _player.setAudioSource(
        AudioSource.uri(uri, tag: item),
        initialPosition: start,
      );
    } catch (error) {
      _errors.add(error);
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _remote.close();
    await _errors.close();
  }
}

/// Mirrors the player into the system media controls.
class _Handler extends BaseAudioHandler with SeekHandler {
  _Handler(this._player, this._remote) {
    _player.playbackEventStream.listen(_broadcast, onError: (_) {});
    _player.playingStream.listen((_) => _broadcast(_player.playbackEvent));
  }

  final AudioPlayer _player;
  final StreamController<RemoteCommand> _remote;

  void _broadcast(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async => _remote.add(RemoteCommand.skipToNext);

  @override
  Future<void> skipToPrevious() async =>
      _remote.add(RemoteCommand.skipToPrevious);
}
