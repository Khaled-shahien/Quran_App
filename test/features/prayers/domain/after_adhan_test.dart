import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_alarms/sakina_alarms.dart';
import 'package:sakina_app/core/services/notification_style.dart';
import 'package:sakina_app/features/prayers/domain/adhan_voices.dart';
import 'package:sakina_app/features/prayers/domain/after_adhan.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_alert_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final times = <DailyPrayer, DateTime>{
    DailyPrayer.fajr: DateTime(2026, 11, 18, 4, 50),
    DailyPrayer.dhuhr: DateTime(2026, 11, 18, 11, 40),
    DailyPrayer.asr: DateTime(2026, 11, 18, 14, 35),
    DailyPrayer.maghrib: DateTime(2026, 11, 18, 16, 58),
    DailyPrayer.isha: DateTime(2026, 11, 18, 18, 18),
  };

  group('quiet windows', () {
    test('none unless the user chose a length', () {
      expect(
        planQuietWindows(
          times: times,
          alerts: const AdhanSettings(),
          after: const AfterAdhanSettings(),
          now: DateTime(2026, 11, 18),
        ),
        isEmpty,
      );
    });

    test('start five minutes after each alerting prayer', () {
      final windows = planQuietWindows(
        times: times,
        alerts: const AdhanSettings(
          modes: {DailyPrayer.asr: PrayerAlertMode.silent},
        ),
        after: const AfterAdhanSettings(quietMinutes: 20),
        now: DateTime(2026, 11, 18, 11, 50),
      );
      // Fajr is over, Dhuhr's window is still running, Asr is silent.
      expect(windows, hasLength(3));
      expect(windows.first.start, DateTime(2026, 11, 18, 11, 45));
      expect(windows.first.end, DateTime(2026, 11, 18, 12, 5));
      expect(windows.last.start, DateTime(2026, 11, 18, 18, 23));
    });
  });

  group('Fajr wake', () {
    const on = AfterAdhanSettings(fajrWake: true);
    final sunrise = DateTime(2026, 11, 18, 6, 15);

    test('replaces the Fajr alert only while Fajr is ahead', () {
      expect(
        wakesForFajr(
          after: on,
          fajr: times[DailyPrayer.fajr],
          sunrise: sunrise,
          now: DateTime(2026, 11, 18, 1),
        ),
        isTrue,
      );
      expect(
        wakesForFajr(
          after: on,
          fajr: times[DailyPrayer.fajr],
          sunrise: sunrise,
          now: DateTime(2026, 11, 18, 5),
        ),
        isFalse,
      );
      expect(
        wakesForFajr(
          after: on,
          fajr: times[DailyPrayer.fajr],
          sunrise: null,
          now: DateTime(2026, 11, 18, 1),
        ),
        isFalse,
      );
      expect(
        wakesForFajr(
          after: const AfterAdhanSettings(),
          fajr: times[DailyPrayer.fajr],
          sunrise: sunrise,
          now: DateTime(2026, 11, 18, 1),
        ),
        isFalse,
      );
    });

    test('the planner leaves out the Fajr alert but keeps its reminder', () {
      final plan = planPrayerAlerts(
        times: times,
        names: {for (final p in DailyPrayer.values) p: p.name},
        settings: const AdhanSettings(reminderMinutes: 10),
        now: DateTime(2026, 11, 18, 1),
        skipFajrAlert: true,
      );
      final fajr = plan.where((a) => a.prayer == DailyPrayer.fajr);
      expect(fajr.map((a) => a.kind), [PlannedAlertKind.reminder]);
      expect(
        plan.where((a) => a.kind == PlannedAlertKind.prayer),
        hasLength(4),
      );
    });

    test('alarm data carries absolute times and the texts', () {
      final map = FajrWakeAlarm(
        at: times[DailyPrayer.fajr]!,
        sunrise: sunrise,
        snoozeMinutes: 5,
        sound: 'adhan_makkah',
        texts: const FajrWakeTexts(
          title: 't',
          body: 'b',
          stop: 's',
          snooze: 'z',
          untilSunrise: '%s',
          sunriseReached: 'r',
          channelName: 'c',
        ),
      ).toMap();
      expect(map['at'], times[DailyPrayer.fajr]!.millisecondsSinceEpoch);
      expect(map['sunrise'], sunrise.millisecondsSinceEpoch);
      expect((map['texts']! as Map)['untilSunrise'], '%s');
      expect(SakinaAlarms.dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('calls are harmless without the native side', () async {
      await SakinaAlarms.setQuietWindows(DateTime(2026, 11, 18), const []);
      await SakinaAlarms.clearAll();
      expect(await SakinaAlarms.hasDndAccess(), isNull);
    });
  });

  test('settings survive a restart and reject unknown values', () async {
    SharedPreferences.setMockInitialValues({
      AfterAdhanSettingsStore.quietKey: 7,
      AfterAdhanSettingsStore.snoozeKey: 3,
    });
    final prefs = await SharedPreferences.getInstance();
    final store = AfterAdhanSettingsStore(prefs);
    expect(store.read().quietMinutes, 0);
    expect(store.read().snoozeMinutes, 5);
    await store.write(
      const AfterAdhanSettings(
        quietMinutes: 30,
        fajrWake: true,
        snoozeMinutes: 10,
      ),
    );
    final read = AfterAdhanSettingsStore(prefs).read();
    expect(read.quietMinutes, 30);
    expect(read.fajrWake, isTrue);
    expect(read.snoozeMinutes, 10);
  });

  test('an adhan alert has a stop button that dismisses it', () {
    final details = buildNotificationDetails(
      SakinaNotificationKind.prayer,
      title: 't',
      body: 'b',
      adhanVoice: AdhanVoices.all.first,
    );
    final AndroidNotificationAction stop = details.android!.actions!.first;
    expect(stop.id, NotificationActionIds.stopAdhan);
    expect(stop.cancelNotification, isTrue);
    expect(stop.showsUserInterface, isFalse);

    final plain = buildNotificationDetails(
      SakinaNotificationKind.prayer,
      title: 't',
      body: 'b',
    );
    expect(
      plain.android!.actions!.map((a) => a.id),
      isNot(contains(NotificationActionIds.stopAdhan)),
    );
  });
}
