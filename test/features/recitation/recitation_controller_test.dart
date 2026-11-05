import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/audio/recitation_audio_engine.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late FakeEngine engine;
  late FakeRepository repository;
  late SharedPreferences prefs;

  Future<RecitationController> controller([
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    final c = RecitationController(
      repository: repository,
      engine: engine,
      preferences: prefs,
      surahName: (s) => 'سورة $s',
    );
    await c.initialize();
    return c;
  }

  setUp(() {
    engine = FakeEngine();
    repository = FakeRepository();
  });

  test('plays a surah inside the app from the chosen ayah', () async {
    final c = await controller();
    await c.playSurah(1, fromAyah: 3);

    expect(engine.loadedSource, 'https://example.org/1.mp3');
    expect(engine.loadedStart, const Duration(seconds: 20));
    expect(engine.info!.title, 'سورة 1');
    expect(engine.info!.subtitle, 'العفاسي');
    expect(c.status, RecitationStatus.playing);
    expect(c.currentAyah, 3);
  });

  test('current ayah follows the audio position', () async {
    final c = await controller();
    await c.playSurah(1);
    engine.emitPosition(const Duration(seconds: 25));
    expect(c.currentAyah, 3);
  });

  test(
    'repeats an ayah the requested number of times, then continues',
    () async {
      final c = await controller();
      await c.playSurah(1);
      await c.setRepeat(2, 2, 3);

      engine.emitPosition(const Duration(seconds: 20)); // end of ayah 2
      engine.emitPosition(const Duration(seconds: 20));
      expect(c.repeat, isNotNull, reason: 'two of three passes done');
      expect(engine.calls.where((c) => c == 'seek 10'), hasLength(3));

      engine.emitPosition(const Duration(seconds: 20)); // third pass done
      expect(c.repeat, isNull);
      engine.emitPosition(const Duration(seconds: 21));
      expect(c.currentAyah, 3);
    },
  );

  test('a range repeat ending at the last ayah loops on completion', () async {
    final c = await controller();
    await c.playSurah(1);
    await c.setRepeat(6, 7, 2);
    engine.status.add(EngineStatus.completed);
    expect(engine.calls.last, isIn(['seek 50', 'play']));
    expect(c.repeat, isNotNull);
  });

  test('speed is applied and remembered', () async {
    final c = await controller();
    await c.setSpeed(0.75);
    await c.playSurah(1);
    expect(engine.speed, 0.75);
    final restarted = RecitationController(
      repository: repository,
      engine: FakeEngine(),
      preferences: prefs,
      surahName: (s) => '$s',
    );
    expect(restarted.speed, 0.75);
  });

  test('unsupported speeds are ignored', () async {
    final c = await controller();
    await c.setSpeed(3);
    expect(c.speed, 1.0);
  });

  test('reciter choice is remembered across restarts', () async {
    final c = await controller();
    await c.selectReciter(c.reciters.last);
    expect((await controller({'recitation_reciter_id': 2})).reciter!.id, 2);
  });

  test('changing reciter while playing keeps the place', () async {
    final c = await controller();
    await c.playSurah(1);
    engine.emitPosition(const Duration(seconds: 35)); // ayah 4
    await c.selectReciter(c.reciters.last);
    expect(engine.loadedStart, const Duration(seconds: 30));
    expect(engine.info!.subtitle, 'عبد الباسط');
  });

  test('offline without a download shows a network error', () async {
    repository.offline = true;
    final c = await controller();
    await c.playSurah(1);
    expect(c.status, RecitationStatus.error);
    expect(c.failure, isA<NetworkFailure>());
  });

  test('offline with a download plays the local file', () async {
    repository
      ..offline = true
      ..downloaded.add(1);
    final c = await controller();
    await c.playSurah(1);
    expect(engine.loadedSource, '/data/7/1.mp3');
    expect(c.status, RecitationStatus.playing);
  });

  test('the listening position survives a restart', () async {
    final c = await controller();
    await c.playSurah(1);
    engine.emitPosition(const Duration(seconds: 45)); // ayah 5
    final restarted = RecitationController(
      repository: repository,
      engine: FakeEngine(),
      preferences: prefs,
      surahName: (s) => '$s',
    );
    expect(restarted.resumePoint, (surah: 1, ayah: 5));
  });

  test('pausing for the adhan and resuming afterwards', () async {
    final c = await controller();
    await c.playSurah(1);
    expect(await c.pauseForInterruption(), isTrue);
    expect(engine.playing, isFalse);
    await c.resumeAfterInterruption();
    expect(engine.playing, isTrue);
  });

  test('nothing resumes after the adhan if recitation was paused', () async {
    final c = await controller();
    await c.playSurah(1);
    await c.pause();
    expect(await c.pauseForInterruption(), isFalse);
    await c.resumeAfterInterruption();
    expect(engine.playing, isFalse);
  });

  test('lock-screen next/previous move between surahs', () async {
    final c = await controller();
    await c.playSurah(2);
    engine.remote.add(RemoteCommand.skipToNext);
    await Future<void>.delayed(Duration.zero);
    expect(c.surah, 3);
    engine.remote.add(RemoteCommand.skipToPrevious);
    await Future<void>.delayed(Duration.zero);
    expect(c.surah, 2);
  });

  test('next ayah at the end of a surah moves to the next surah', () async {
    final c = await controller();
    await c.playSurah(2, fromAyah: 5);
    await c.nextAyah();
    expect(c.surah, 3);
    expect(c.currentAyah, 1);
  });

  test('a playback error is reported, and retry reloads', () async {
    final c = await controller();
    await c.playSurah(1);
    engine.errors.add(Exception('SocketException: host lookup failed'));
    expect(c.status, RecitationStatus.error);
    expect(c.failure, isA<NetworkFailure>());
    await c.togglePlay();
    expect(engine.calls.where((x) => x == 'load'), hasLength(2));
  });

  test('stop clears the active surah', () async {
    final c = await controller();
    await c.playSurah(1);
    await c.stop();
    expect(c.isActive, isFalse);
    expect(c.surah, isNull);
  });
}
