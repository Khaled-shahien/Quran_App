import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/domain/prayer_notification_ids.dart';
import 'package:sakina_app/features/prayers/domain/services/prayer_alert_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final day = DateTime(2026, 11, 5);
  final times = {
    DailyPrayer.fajr: DateTime(2026, 11, 5, 4, 43),
    DailyPrayer.dhuhr: DateTime(2026, 11, 5, 11, 39),
    DailyPrayer.asr: DateTime(2026, 11, 5, 14, 43),
    DailyPrayer.maghrib: DateTime(2026, 11, 5, 17, 5),
    DailyPrayer.isha: DateTime(2026, 11, 5, 18, 24),
  };
  final names = {for (final p in DailyPrayer.values) p: p.name};
  final earlyMorning = DateTime(2026, 11, 5, 1);

  List<PlannedAlert> plan(AdhanSettings settings, {DateTime? now}) =>
      planPrayerAlerts(
        times: times,
        names: names,
        settings: settings,
        now: now ?? earlyMorning,
      );

  test('defaults keep today\'s behaviour: five alerts with sound', () {
    final alerts = plan(const AdhanSettings());
    expect(alerts, hasLength(5));
    expect(alerts.every((a) => a.mode == PrayerAlertMode.sound), isTrue);
    expect(alerts.every((a) => a.kind == PlannedAlertKind.prayer), isTrue);
  });

  test('a silent prayer gets no alert and no reminder', () {
    final alerts = plan(
      const AdhanSettings(
        reminderMinutes: 10,
      ).withMode(DailyPrayer.dhuhr, PrayerAlertMode.silent),
    );
    expect(alerts.where((a) => a.prayer == DailyPrayer.dhuhr), isEmpty);
    expect(alerts, hasLength(8)); // 4 prayers + 4 reminders
  });

  test('each prayer uses its own mode', () {
    final alerts = plan(
      const AdhanSettings()
          .withMode(DailyPrayer.fajr, PrayerAlertMode.adhan)
          .withMode(DailyPrayer.isha, PrayerAlertMode.notificationOnly),
    );
    expect(alerts.first.mode, PrayerAlertMode.adhan);
    expect(alerts.last.mode, PrayerAlertMode.notificationOnly);
  });

  test('reminders come X minutes before, with their own IDs', () {
    final alerts = plan(const AdhanSettings(reminderMinutes: 15));
    final reminder = alerts.firstWhere(
      (a) => a.kind == PlannedAlertKind.reminder,
    );
    expect(reminder.at, DateTime(2026, 11, 5, 4, 28));
    final ids = alerts.map((a) => a.id).toSet();
    expect(ids, hasLength(alerts.length), reason: 'no ID collisions');
    expect(
      allPrayerNotificationIds().toSet(),
      containsAll(ids),
      reason: 'cancel-all must reach every alert, reminders included',
    );
  });

  test('past prayers and past reminders are skipped', () {
    final alerts = plan(
      const AdhanSettings(reminderMinutes: 30),
      now: DateTime(2026, 11, 5, 14, 30), // Asr reminder already passed
    );
    expect(alerts.where((a) => a.prayer == DailyPrayer.fajr), isEmpty);
    expect(
      alerts.where(
        (a) =>
            a.prayer == DailyPrayer.asr && a.kind == PlannedAlertKind.reminder,
      ),
      isEmpty,
    );
    expect(
      alerts.where(
        (a) => a.prayer == DailyPrayer.asr && a.kind == PlannedAlertKind.prayer,
      ),
      hasLength(1),
    );
  });

  test('IDs are stable per prayer and weekday', () {
    final a = plan(const AdhanSettings());
    final b = plan(const AdhanSettings());
    expect(a.map((x) => x.id), b.map((x) => x.id));
    expect(a.first.id, prayerNotificationId(2001, day));
  });

  group('AdhanSettingsStore', () {
    test('round-trips every choice', () async {
      SharedPreferences.setMockInitialValues({});
      final store = AdhanSettingsStore(await SharedPreferences.getInstance());
      await store.write(
        const AdhanSettings(reminderMinutes: 10, muezzinId: 'madinah')
            .withMode(DailyPrayer.fajr, PrayerAlertMode.adhan)
            .withMode(DailyPrayer.asr, PrayerAlertMode.silent),
      );
      final read = store.read();
      expect(read.modeFor(DailyPrayer.fajr), PrayerAlertMode.adhan);
      expect(read.modeFor(DailyPrayer.asr), PrayerAlertMode.silent);
      expect(read.modeFor(DailyPrayer.isha), PrayerAlertMode.sound);
      expect(read.reminderMinutes, 10);
      expect(read.muezzinId, 'madinah');
    });

    test('invalid stored values fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'adhan_mode_fajr': 'loud',
        'adhan_reminder_minutes': 7,
        'adhan_muezzin': 3,
      });
      final read = AdhanSettingsStore(
        await SharedPreferences.getInstance(),
      ).read();
      expect(read.modeFor(DailyPrayer.fajr), AdhanSettings.defaultMode);
      expect(read.reminderMinutes, 0);
      expect(read.muezzinId, AdhanSettings.defaultMuezzin);
    });
  });
}
