import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/audio/recitation_audio_engine.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_controller.dart';
import 'package:sakina_app/features/recitation/presentation/screens/recitation_listen_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late FakeEngine engine;
  late FakeRepository repository;

  Future<RecitationController> controller([
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
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

  test('each ayah is heard the chosen number of times', () async {
    final c = await controller();
    await c.setAyahRepeat(3);
    await c.playSurah(1);
    engine.calls.clear();

    // Crossing into ayah 2 goes back to ayah 1 twice, then moves on.
    engine.emitPosition(const Duration(seconds: 11));
    engine.emitPosition(const Duration(seconds: 11));
    expect(engine.calls.where((x) => x == 'seek 0'), hasLength(2));
    expect(c.currentAyah, 1);
    engine.emitPosition(const Duration(seconds: 11));
    expect(c.currentAyah, 2);
  });

  test('the choice is remembered', () async {
    final c = await controller();
    await c.setAyahRepeat(5);
    await c.setAutoNext(true);
    final again = await controller({
      'recitation_ayah_repeat': 5,
      'recitation_auto_next': true,
    });
    expect(again.ayahRepeat, 5);
    expect(again.autoNext, isTrue);
    expect(c.ayahRepeat, 5);
  });

  test('auto-next plays the following surah when one ends', () async {
    final c = await controller();
    await c.setAutoNext(true);
    await c.playSurah(1);
    engine.status.add(EngineStatus.completed);
    await Future<void>.delayed(Duration.zero);
    expect(c.surah, 2);
  });

  test('"end of surah" stops there even with auto-next', () async {
    final c = await controller();
    await c.setAutoNext(true);
    await c.playSurah(1);
    c.sleepAtEndOfSurah();
    engine.status.add(EngineStatus.completed);
    await Future<void>.delayed(Duration.zero);
    expect(c.surah, 1);
    expect(c.status, RecitationStatus.paused);
    expect(c.sleepAtSurahEnd, isFalse);
  });

  testWidgets('the sleep timer pauses playback and can be cancelled', (
    tester,
  ) async {
    final c = (await tester.runAsync(controller))!;
    await tester.runAsync(() => c.playSurah(1));
    c.setSleepTimer(15);
    expect(c.sleepAt, isNotNull);
    await tester.pump(const Duration(minutes: 14));
    expect(engine.calls, isNot(contains('pause')));
    await tester.pump(const Duration(minutes: 2));
    expect(engine.calls, contains('pause'));
    expect(c.sleepAt, isNull);

    engine.calls.clear();
    c.setSleepTimer(5);
    c.setSleepTimer(null);
    await tester.pump(const Duration(minutes: 10));
    expect(engine.calls, isNot(contains('pause')));
  });

  testWidgets('listening mode: big buttons and adjust gestures move ayahs', (
    tester,
  ) async {
    final c = (await tester.runAsync(controller))!;
    await tester.runAsync(() => c.playSurah(1));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: c,
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RecitationListenScreen(),
        ),
      ),
    );
    expect(find.text('سورة 1، الآية 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('listen-next')));
    await tester.pump();
    expect(c.currentAyah, 2);

    final node = tester.getSemantics(
      find.byKey(const Key('listen-swipe-area')),
    );
    expect(node.value, contains('الآية 2'));
    tester.semantics.decrease(find.semantics.byValue(node.value));
    await tester.pump();
    expect(c.currentAyah, 1);

    await tester.fling(
      find.byKey(const Key('listen-swipe-area')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pump();
    expect(c.currentAyah, 2);
    semantics.dispose();
  });
}
