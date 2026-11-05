import 'dart:async';

/// Playback state as the recitation player sees it.
enum EngineStatus { idle, loading, buffering, ready, completed }

/// What the lock screen and notification show for the current audio.
class NowPlayingInfo {
  const NowPlayingInfo({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

/// Commands that arrive from outside the app (lock screen, notification,
/// headset buttons).
enum RemoteCommand { skipToNext, skipToPrevious }

/// Audio playback used by the Quran recitation player.
///
/// The interface keeps platform audio out of presentation code and makes the
/// player testable without a device.
abstract interface class RecitationAudioEngine {
  Stream<Duration> get positionStream;
  Stream<EngineStatus> get statusStream;
  Stream<bool> get playingStream;
  Stream<RemoteCommand> get remoteCommands;

  /// Errors while loading or playing (network loss, unsupported file).
  Stream<Object> get errorStream;

  Duration get position;
  bool get playing;

  /// [source] is an https URL or an absolute local file path.
  Future<void> load(
    String source, {
    required NowPlayingInfo info,
    Duration start = Duration.zero,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}
