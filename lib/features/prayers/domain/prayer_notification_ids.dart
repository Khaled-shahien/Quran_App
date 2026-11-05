/// Seven bounded day slots keep adjacent days from replacing each other.
/// The three-day replenishment window never overlaps a slot with itself.
int prayerNotificationId(int legacyId, DateTime date) =>
    legacyId + date.weekday * 10;

/// The "prayer is near" reminder for the same prayer and day.
int prayerReminderNotificationId(int legacyId, DateTime date) =>
    prayerNotificationId(legacyId, date) + 1000;

/// Every prayer alert ID: [prayerOnly] excludes the reminders.
Iterable<int> allPrayerNotificationIds({bool prayerOnly = false}) sync* {
  for (var slot = 0; slot <= 7; slot++) {
    for (var prayer = 2001; prayer <= 2005; prayer++) {
      yield prayer + slot * 10;
      if (!prayerOnly) yield prayer + slot * 10 + 1000;
    }
  }
}
