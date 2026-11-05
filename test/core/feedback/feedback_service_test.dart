import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:sakina_app/features/quran/presentation/screens/tasbeeh_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingPlatform implements FeedbackPlatform {
  final haptics = <HapticKind>[];
  int clicks = 0;

  @override
  Future<void> haptic(HapticKind kind) async => haptics.add(kind);

  @override
  Future<void> click() async => clicks++;
}

void main() {
  late SharedPreferences prefs;
  late RecordingPlatform platform;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    platform = RecordingPlatform();
  });

  test('haptics on and sounds off by default', () async {
    final service = FeedbackService(preferences: prefs, platform: platform);
    expect(service.hapticsEnabled, isTrue);
    expect(service.soundsEnabled, isFalse);

    service.play(FeedbackEvent.tasbihCount);
    await Future<void>.delayed(Duration.zero);
    expect(platform.haptics, [HapticKind.selection]);
    expect(platform.clicks, 0);
  });

  test('a completed set feels different from a single count', () {
    expect(
      feedbackMap[FeedbackEvent.tasbihSetComplete]!.haptic,
      isNot(feedbackMap[FeedbackEvent.tasbihCount]!.haptic),
    );
  });

  test('every event has a mapping', () {
    expect(feedbackMap.keys.toSet(), FeedbackEvent.values.toSet());
  });

  test('sounds play only when enabled; choices are remembered', () async {
    final service = FeedbackService(preferences: prefs, platform: platform);
    await service.setSoundsEnabled(true);
    await service.setHapticsEnabled(false);
    service.play(FeedbackEvent.adhkarCount);
    service.play(FeedbackEvent.qiblaAligned); // never clicks
    await Future<void>.delayed(Duration.zero);
    expect(platform.haptics, isEmpty);
    expect(platform.clicks, 1);

    final reloaded = FeedbackService(preferences: prefs, platform: platform);
    expect(reloaded.soundsEnabled, isTrue);
    expect(reloaded.hapticsEnabled, isFalse);
  });

  test('a failing device never breaks the action', () async {
    final service = FeedbackService(
      preferences: prefs,
      platform: _ThrowingPlatform(),
    );
    expect(() => service.play(FeedbackEvent.reset), returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });

  testWidgets('tapping the tasbih vibrates once per count', (tester) async {
    final service = FeedbackService(preferences: prefs, platform: platform);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          ChangeNotifierProvider(
            create: (_) => TasbihController(
              repository: SharedPreferencesTasbihRepository(prefs),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TasbeehScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('tasbih-tap-area')));
    await tester.tap(find.byKey(const Key('tasbih-tap-area')));
    await tester.pump();
    expect(platform.haptics, [HapticKind.selection, HapticKind.selection]);
  });
}

class _ThrowingPlatform implements FeedbackPlatform {
  @override
  Future<void> haptic(HapticKind kind) async => throw StateError('no motor');

  @override
  Future<void> click() async => throw StateError('no speaker');
}
