import 'prayer_times_provider.dart';

/// Notices, from periodic clock ticks, the moment a prayer time has come
/// while the app is open.
class PrayerArrivalWatcher {
  NextPrayer? _expected;

  /// Returns the prayer that has just begun since the previous tick, if any.
  /// The first tick only records what is next.
  NextPrayer? tick(NextPrayer? next, DateTime now) {
    final previous = _expected;
    _expected = next;
    if (previous == null) return null;
    final arrived = !previous.at.isAfter(now);
    final moved = next == null || next.at != previous.at;
    return arrived && moved ? previous : null;
  }
}
