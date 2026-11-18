import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/services/notification_channels.dart';
import 'package:sakina_app/core/services/notification_style.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/domain/adhan_voices.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/presentation/adhan_preview_player.dart';
import 'package:sakina_app/features/prayers/presentation/providers/adhan_settings_controller.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/adhan_preferences.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _rawDir = 'android/app/src/main/res/raw';

class _FakePreview implements AdhanPreviewPlayer {
  _FakePreview({this.fail = false});
  final bool fail;
  final played = <String>[];
  final ValueNotifier<String?> _playing = ValueNotifier(null);

  @override
  ValueListenable<String?> get playing => _playing;

  @override
  Future<void> play(AdhanVoice voice) async {
    if (fail) throw StateError('cannot open ${voice.resource}');
    played.add(voice.id);
    _playing.value = voice.id;
  }

  @override
  Future<void> stop() async => _playing.value = null;

  @override
  void dispose() {}
}

void main() {
  group('bundled recordings', () {
    for (final voice in AdhanVoices.all) {
      test('${voice.id} is the owner-supplied MP3 in res/raw', () {
        final file = File(voice.assetPath);
        expect(file.existsSync(), isTrue, reason: file.path);
        final bytes = file.readAsBytesSync();
        // The catalog describes the file actually bundled.
        expect(bytes.length, voice.sizeBytes);
        // MP3: an ID3v2 tag or an MPEG audio frame sync at the start.
        final id3 = String.fromCharCodes(bytes.sublist(0, 3)) == 'ID3';
        final sync = bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
        expect(id3 || sync, isTrue, reason: 'not an MP3: ${file.path}');
        // A whole adhan, not a stub or a clip.
        expect(voice.duration, greaterThan(const Duration(minutes: 1)));
        expect(voice.originalFilename, endsWith('.mp3'));
      });
    }

    test('ids give valid, unique Android resource and channel names', () {
      final valid = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final v in AdhanVoices.all) {
        expect(v.resource, matches(valid));
      }
      expect(
        AdhanVoices.all.map((v) => v.id).toSet(),
        hasLength(AdhanVoices.all.length),
      );
      expect(
        AdhanVoices.all.map((v) => v.channelId).toSet(),
        hasLength(AdhanVoices.all.length),
      );
    });

    test('no stray recording sits in res/raw without a catalog entry', () {
      final files = Directory(_rawDir)
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.startsWith('adhan_'))
          .toSet();
      expect(files, {
        for (final v in AdhanVoices.all) '${v.resource}.${v.format}',
      });
    });

    test('release shrinking keeps every recording', () {
      final keep = File('$_rawDir/keep.xml').readAsStringSync();
      expect(keep, contains('@raw/adhan_*'));
    });

    test('every recording is documented with its source file', () {
      final doc = File('ADHAN_AUDIO_LIBRARY.md').readAsStringSync();
      for (final v in AdhanVoices.all) {
        expect(doc, contains('${v.resource}.${v.format}'));
        expect(doc, contains(v.originalFilename));
      }
    });

    test('removed recordings are gone and their channels retired', () {
      const removed = [
        'asim_javed',
        'moazzam_mirza',
        'shalqar',
        'nigeria',
        'fajr_gocek',
      ];
      for (final id in removed) {
        expect(AdhanVoices.byId(id), isNull);
        expect(File('$_rawDir/adhan_$id.ogg').existsSync(), isFalse);
        expect(
          AdhanVoices.retiredChannelIds,
          contains('prayer_adhan_${id}_v1'),
        );
      }
      final live = {for (final v in AdhanVoices.all) v.channelId};
      expect(live.intersection(AdhanVoices.retiredChannelIds.toSet()), isEmpty);
    });

    test('preview reads the same raw resource the alert plays', () {
      final v = AdhanVoices.all.first;
      expect(v.previewUri.toString(), 'android.resource:///raw/${v.resource}');
    });
  });

  group('choosing a recording', () {
    test('the four owner-supplied recordings are bundled', () {
      expect(AdhanVoices.all.map((v) => v.id), [
        'ali_mulla',
        'nasser_alqatami',
        'naqshbandi',
        'islam_sobhi',
      ]);
    });

    test('every recording can be chosen for every prayer, Fajr included', () {
      for (final p in DailyPrayer.values) {
        for (final v in AdhanVoices.all) {
          final s = const AdhanSettings().withVoice(p, v.id);
          expect(s.voiceFor(p), v, reason: '${p.name} / ${v.id}');
        }
      }
    });

    test('unknown or removed ids fall back to the first recording', () {
      final first = AdhanVoices.all.first;
      expect(AdhanVoices.resolve(null), first);
      expect(AdhanVoices.resolve('gone'), first);
      // Ids saved for recordings that were removed.
      expect(AdhanVoices.resolve('fajr_gocek'), first);
      expect(AdhanVoices.resolve('nigeria'), first);
    });

    test('each prayer keeps its own recording', () {
      final s = const AdhanSettings()
          .withVoice(DailyPrayer.fajr, 'naqshbandi')
          .withVoice(DailyPrayer.dhuhr, 'islam_sobhi')
          .withVoice(DailyPrayer.asr, 'nasser_alqatami')
          .withVoice(DailyPrayer.maghrib, 'ali_mulla')
          .withVoice(DailyPrayer.isha, 'naqshbandi');
      expect(s.voiceFor(DailyPrayer.fajr).id, 'naqshbandi');
      expect(s.voiceFor(DailyPrayer.dhuhr).id, 'islam_sobhi');
      expect(s.voiceFor(DailyPrayer.asr).id, 'nasser_alqatami');
      expect(s.voiceFor(DailyPrayer.maghrib).id, 'ali_mulla');
      expect(s.voiceFor(DailyPrayer.isha).id, 'naqshbandi');
    });

    test('the test alert asks for notification permission first', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var scheduled = 0;
      AdhanSettingsController controller({required bool granted}) =>
          AdhanSettingsController(
            store: AdhanSettingsStore(prefs),
            platform: AdhanPlatform(
              reschedule: () async {},
              canScheduleExact: () async => true,
              requestExact: () async => true,
              scheduleTest: (_) async => scheduled++,
              requestNotifications: () async => granted,
            ),
          );

      // Refused: nothing is scheduled and the caller is told.
      expect(await controller(granted: false).scheduleTest(), isFalse);
      expect(scheduled, 0);
      expect(await controller(granted: true).scheduleTest(), isTrue);
      expect(scheduled, 1);
    });

    test('controller saves a valid choice and reschedules', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var reschedules = 0;
      final c = AdhanSettingsController(
        store: AdhanSettingsStore(prefs),
        platform: AdhanPlatform(
          reschedule: () async => reschedules++,
          canScheduleExact: () async => true,
          requestExact: () async => true,
          scheduleTest: (_) async {},
        ),
      );

      await c.setVoice(DailyPrayer.maghrib, 'nasser_alqatami');
      await c.setVoice(DailyPrayer.fajr, 'islam_sobhi');
      await c.setVoice(DailyPrayer.asr, 'unknown');
      await c.setVoice(DailyPrayer.isha, 'moazzam_mirza'); // removed

      expect(reschedules, 2);
      final read = AdhanSettingsStore(prefs).read();
      expect(read.voiceFor(DailyPrayer.maghrib).id, 'nasser_alqatami');
      expect(read.voiceFor(DailyPrayer.fajr).id, 'islam_sobhi');
      expect(read.voiceFor(DailyPrayer.isha), AdhanVoices.all.first);
    });
  });

  group('notification', () {
    final voice = AdhanVoices.all.last;

    test('an adhan alert goes to the recording\'s channel with its sound', () {
      final android = buildNotificationDetails(
        SakinaNotificationKind.prayer,
        title: 't',
        body: 'b',
        adhanVoice: voice,
      ).android!;
      expect(android.channelId, voice.channelId);
      expect(android.importance, Importance.max);
      expect(android.playSound, isTrue);
      expect(android.sound, isA<RawResourceAndroidNotificationSound>());
      expect(android.sound!.sound, voice.resource);
    });

    test('only a sounding prayer alert can carry the adhan', () {
      for (final kind in [
        SakinaNotificationKind.prayerSilent,
        SakinaNotificationKind.prayerReminder,
        SakinaNotificationKind.adhkar,
      ]) {
        final android = buildNotificationDetails(
          kind,
          adhanVoice: voice,
        ).android!;
        expect(android.channelId, isNot(voice.channelId));
        expect(android.sound, isNull);
      }
      final plain = buildNotificationDetails(
        SakinaNotificationKind.prayer,
      ).android!;
      expect(plain.channelId, NotificationChannels.prayerId);
    });

    test('every recording has a channel whose sound is that recording', () {
      final channels = {for (final c in NotificationChannels.all()) c.id: c};
      for (final v in AdhanVoices.all) {
        final channel = channels[v.channelId];
        expect(channel, isNotNull, reason: v.id);
        expect(channel!.playSound, isTrue);
        expect(channel.sound?.sound, v.resource);
        expect(channel.importance, Importance.max);
      }
      // The existing prayer channels are untouched.
      expect(channels[NotificationChannels.prayerId]?.sound, isNull);
    });

    test('iOS keeps the alert sound (full adhan exceeds 30 s)', () {
      final ios = buildNotificationDetails(
        SakinaNotificationKind.prayer,
        adhanVoice: voice,
      ).iOS!;
      expect(ios.sound, isNull);
      expect(ios.presentSound, isTrue);
    });
  });

  group('settings', () {
    Future<(AdhanSettingsController, _FakePreview)> pump(
      WidgetTester tester, {
      required Map<String, Object> prefs,
      bool failPreview = false,
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final store = AdhanSettingsStore(await SharedPreferences.getInstance());
      final c = AdhanSettingsController(
        store: store,
        platform: AdhanPlatform(
          reschedule: () async {},
          canScheduleExact: () async => null,
          requestExact: () async => true,
          scheduleTest: (_) async {},
        ),
      );
      final preview = _FakePreview(fail: failPreview);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChangeNotifierProvider<AdhanSettingsController>.value(
              value: c,
              child: SingleChildScrollView(
                child: AdhanPreferences(previewPlayer: preview),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (c, preview);
    }

    testWidgets('the "not added yet" message is gone', (tester) async {
      await pump(tester, prefs: {'adhan_mode_isha': 'adhan'});
      expect(find.textContaining('لم تُضف بعد'), findsNothing);
      expect(
        find.text(
          'لإيقاف الأذان اضغط «إيقاف الأذان» في الإشعار، أو اسحب الإشعار.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a voice row appears only for prayers set to the adhan', (
      tester,
    ) async {
      await pump(
        tester,
        prefs: {'adhan_mode_isha': 'adhan', 'adhan_mode_fajr': 'adhan'},
      );
      expect(find.byKey(const Key('adhan-voice-isha')), findsOneWidget);
      expect(find.byKey(const Key('adhan-voice-fajr')), findsOneWidget);
      expect(find.byKey(const Key('adhan-voice-dhuhr')), findsNothing);
      // Fajr offers the same four recordings as the other prayers.
      await tester.tap(find.byKey(const Key('adhan-voice-fajr')));
      await tester.pumpAndSettle();
      for (final name in const [
        'علي أحمد ملا',
        'ناصر القطامي',
        'النقشبندي',
        'إسلام صبحي',
      ]) {
        expect(find.text(name), findsWidgets, reason: name);
      }
    });

    testWidgets('choosing a voice saves it for that prayer only', (
      tester,
    ) async {
      final (c, _) = await pump(
        tester,
        prefs: {'adhan_mode_isha': 'adhan', 'adhan_mode_asr': 'adhan'},
      );
      await tester.tap(find.byKey(const Key('adhan-voice-isha')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('النقشبندي').last);
      await tester.pumpAndSettle();
      expect(c.settings.voiceFor(DailyPrayer.isha).id, 'naqshbandi');
      expect(c.settings.voiceFor(DailyPrayer.asr).id, isNot('naqshbandi'));
    });

    testWidgets('listen plays the selected recording, then stops', (
      tester,
    ) async {
      final (c, preview) = await pump(
        tester,
        prefs: {'adhan_mode_isha': 'adhan', 'adhan_voice_isha': 'islam_sobhi'},
      );
      await tester.tap(find.byKey(const Key('adhan-preview-isha')));
      await tester.pumpAndSettle();
      expect(preview.played, ['islam_sobhi']);
      expect(find.byTooltip('إيقاف الاستماع'), findsOneWidget);

      await tester.tap(find.byKey(const Key('adhan-preview-isha')));
      await tester.pumpAndSettle();
      expect(preview.playing.value, isNull);
      expect(c.settings.voiceFor(DailyPrayer.isha).id, 'islam_sobhi');
    });

    testWidgets('a recording that cannot play says so', (tester) async {
      await pump(
        tester,
        prefs: {'adhan_mode_isha': 'adhan'},
        failPreview: true,
      );
      await tester.tap(find.byKey(const Key('adhan-preview-isha')));
      await tester.pumpAndSettle();
      expect(find.text('تعذّر تشغيل التسجيل.'), findsOneWidget);
    });

    testWidgets('on iOS the adhan option says it uses the alert sound', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await pump(tester, prefs: {'adhan_mode_isha': 'adhan'});
        expect(find.byKey(const Key('adhan-voice-isha')), findsNothing);
        expect(
          find.text(
            'الأذان الكامل غير متاح في إشعارات هذا الجهاز، وسيُستخدم صوت التنبيه.',
          ),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
