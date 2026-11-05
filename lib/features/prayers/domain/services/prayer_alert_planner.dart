import '../entities/adhan_settings.dart';
import '../prayer_notification_ids.dart';

enum PlannedAlertKind { prayer, reminder }

/// One notification to schedule.
class PlannedAlert {
  const PlannedAlert({
    required this.id,
    required this.kind,
    required this.prayer,
    required this.prayerName,
    required this.at,
    required this.mode,
  });

  final int id;
  final PlannedAlertKind kind;
  final DailyPrayer prayer;
  final String prayerName;
  final DateTime at;
  final PrayerAlertMode mode;
}

/// Base notification IDs, 2001 (Fajr) .. 2005 (Isha).
int prayerBaseId(DailyPrayer prayer) => 2001 + prayer.index;

/// Decides every alert for one day's prayers.
///
/// [times] maps each prayer to its instant and [names] to its display name.
/// Silent prayers get nothing; reminders are only for prayers that alert
/// and only when the reminder time is still ahead of [now]. IDs are stable
/// per prayer and weekday, so rescheduling replaces instead of duplicating.
List<PlannedAlert> planPrayerAlerts({
  required Map<DailyPrayer, DateTime> times,
  required Map<DailyPrayer, String> names,
  required AdhanSettings settings,
  required DateTime now,
}) {
  final plan = <PlannedAlert>[];
  for (final prayer in DailyPrayer.values) {
    final at = times[prayer];
    if (at == null) continue;
    final mode = settings.modeFor(prayer);
    if (mode == PrayerAlertMode.silent) continue;
    final name = names[prayer] ?? prayer.name;
    if (at.isAfter(now)) {
      plan.add(
        PlannedAlert(
          id: prayerNotificationId(prayerBaseId(prayer), at),
          kind: PlannedAlertKind.prayer,
          prayer: prayer,
          prayerName: name,
          at: at,
          mode: mode,
        ),
      );
    }
    if (settings.hasReminder) {
      final remindAt = at.subtract(Duration(minutes: settings.reminderMinutes));
      if (remindAt.isAfter(now)) {
        plan.add(
          PlannedAlert(
            id: prayerReminderNotificationId(prayerBaseId(prayer), at),
            kind: PlannedAlertKind.reminder,
            prayer: prayer,
            prayerName: name,
            at: remindAt,
            mode: PrayerAlertMode.sound,
          ),
        );
      }
    }
  }
  return plan;
}
