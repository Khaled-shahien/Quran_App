import 'dart:async';

import 'package:sakina_app/core/audio/recitation_audio_engine.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/recitation/domain/entities/recitation.dart';
import 'package:sakina_app/features/recitation/domain/repositories/recitation_repository.dart';

class FakeEngine implements RecitationAudioEngine {
  final positions = StreamController<Duration>.broadcast(sync: true);
  final status = StreamController<EngineStatus>.broadcast(sync: true);
  final playingCtrl = StreamController<bool>.broadcast(sync: true);
  final errors = StreamController<Object>.broadcast(sync: true);
  final remote = StreamController<RemoteCommand>.broadcast(sync: true);
  final calls = <String>[];
  String? loadedSource;
  Duration? loadedStart;
  NowPlayingInfo? info;
  double? speed;
  bool _playing = false;
  Duration _position = Duration.zero;
  Object? failLoadWith;

  void emitPosition(Duration p) {
    _position = p;
    positions.add(p);
  }

  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Stream<EngineStatus> get statusStream => status.stream;
  @override
  Stream<bool> get playingStream => playingCtrl.stream;
  @override
  Stream<Object> get errorStream => errors.stream;
  @override
  Stream<RemoteCommand> get remoteCommands => remote.stream;
  @override
  Duration get position => _position;
  @override
  bool get playing => _playing;

  @override
  Future<void> load(
    String source, {
    required NowPlayingInfo info,
    Duration start = Duration.zero,
  }) async {
    if (failLoadWith != null) throw failLoadWith!;
    calls.add('load');
    loadedSource = source;
    loadedStart = start;
    this.info = info;
    _position = start;
    status.add(EngineStatus.ready);
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _playing = true;
    playingCtrl.add(true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _playing = false;
    playingCtrl.add(false);
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    _playing = false;
  }

  @override
  Future<void> seek(Duration p) async {
    calls.add('seek ${p.inSeconds}');
    _position = p;
  }

  @override
  Future<void> setSpeed(double s) async => speed = s;

  @override
  Future<void> dispose() async {
    await positions.close();
    await status.close();
    await playingCtrl.close();
    await errors.close();
    await remote.close();
  }
}

ChapterRecitation chapter(int surah, int ayahs) => ChapterRecitation(
  reciterId: 7,
  surah: surah,
  audioUrl: 'https://example.org/$surah.mp3',
  timings: [
    for (var a = 1; a <= ayahs; a++)
      AyahTiming(
        ayah: a,
        from: Duration(seconds: (a - 1) * 10),
        to: Duration(seconds: a * 10),
      ),
  ],
);

class FakeRepository implements RecitationRepository {
  bool offline = false;
  final downloaded = <int>{};

  @override
  Future<Result<List<RecitationReciter>>> reciters() async => const Success([
    RecitationReciter(id: 7, name: 'العفاسي', style: RecitationStyle.murattal),
    RecitationReciter(
      id: 2,
      name: 'عبد الباسط',
      style: RecitationStyle.murattal,
    ),
  ]);

  @override
  Future<Result<ChapterRecitation>> chapter(int reciterId, int surah) async =>
      offline && !downloaded.contains(surah)
      ? const Err(NetworkFailure())
      : Success(_chapter(surah));

  ChapterRecitation _chapter(int surah) => chapterFor(surah);

  @override
  Future<Result<String>> playableSource(int reciterId, int surah) async =>
      downloaded.contains(surah)
      ? Success('/data/$reciterId/$surah.mp3')
      : offline
      ? const Err(NetworkFailure())
      : Success('https://example.org/$surah.mp3');

  @override
  Future<Result<int>> downloadSize(int r, int s) async => const Success(1);
  @override
  Stream<DownloadProgress> download(int r, int s) => const Stream.empty();
  @override
  Future<Result<List<DownloadedSurah>>> downloads() async => const Success([]);
  @override
  Future<bool> isDownloaded(int r, int s) async => downloaded.contains(s);
  @override
  Future<Result<void>> deleteDownload(int r, int s) async =>
      const Success(null);
}

ChapterRecitation chapterFor(int surah) => chapter(surah, surah == 1 ? 7 : 5);
