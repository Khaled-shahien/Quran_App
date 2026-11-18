import '../../../prayers/domain/entities/adhan_settings.dart';
import '../../../quran/domain/services/quran_divisions.dart';
import '../models/khatma_model.dart';

/// One prayer's share of the day's reading, in mushaf pages.
typedef WirdPortion = ({DailyPrayer prayer, int fromPage, int toPage});

/// The pages of today's portion of [khatma], whatever unit it is tracked
/// in. Null once the khatma is done.
({int fromPage, int toPage})? todayPageRange(
  KhatmaModel khatma,
  QuranDivisions divisions,
) {
  if (khatma.isCompleted || khatma.remainingUnits <= 0) return null;
  final int from = khatma.todayFromUnit;
  final int to = khatma.todayToUnit;
  switch (khatma.trackingUnit) {
    case KhatmaTrackingUnit.page:
      return (fromPage: from, toPage: to);
    case KhatmaTrackingUnit.juz:
      return _range(divisions.juz, from, to);
    case KhatmaTrackingUnit.hizb:
      return _range(divisions.hizb, from, to);
  }
}

({int fromPage, int toPage}) _range(
  List<QuranDivisionStart> starts,
  int from,
  int to,
) {
  final int fromPage = starts[from - 1].page;
  final int toPage = to < starts.length
      ? starts[to].page - 1
      : QuranDivisions.pageCount;
  return (fromPage: fromPage, toPage: toPage < fromPage ? fromPage : toPage);
}

/// Splits pages [fromPage]..[toPage] over the five prayers as evenly as
/// possible, earlier prayers taking any remainder. With fewer than five
/// pages the later prayers get none.
List<WirdPortion> splitAcrossPrayers(int fromPage, int toPage) {
  final int count = toPage - fromPage + 1;
  if (count <= 0) return const [];
  final int base = count ~/ DailyPrayer.values.length;
  final int extra = count % DailyPrayer.values.length;
  final portions = <WirdPortion>[];
  int next = fromPage;
  for (final prayer in DailyPrayer.values) {
    final int size = base + (prayer.index < extra ? 1 : 0);
    if (size == 0) continue;
    portions.add((prayer: prayer, fromPage: next, toPage: next + size - 1));
    next += size;
  }
  return portions;
}

/// Reminder ids: 6001 + weekday * 10 + prayer (6011–6075).
int wirdPortionNotificationId(DateTime day, DailyPrayer prayer) =>
    6001 + day.weekday * 10 + prayer.index;

Iterable<int> allWirdPortionNotificationIds() sync* {
  for (var weekday = 1; weekday <= 7; weekday++) {
    for (final p in DailyPrayer.values) {
      yield 6001 + weekday * 10 + p.index;
    }
  }
}

/// How long after the prayer time its portion is suggested.
const Duration wirdPortionDelay = Duration(minutes: 20);

/// Preference: spread the day's wird over the prayers.
const String wirdAfterPrayersKey = 'wird_after_prayers';
