/// Seven bounded day slots keep adjacent days from replacing each other.
/// The three-day replenishment window never overlaps a slot with itself.
int prayerNotificationId(int legacyId, DateTime date) =>
    legacyId + date.weekday * 10;

Iterable<int> allPrayerNotificationIds() sync* {
  for (var slot = 0; slot <= 7; slot++) {
    for (var prayer = 2001; prayer <= 2005; prayer++) {
      yield prayer + slot * 10;
    }
  }
}
