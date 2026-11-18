import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';
import 'package:sakina_app/features/khatma/domain/services/wird_portions.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/quran/data/data_sources/quran_master_asset.dart';
import 'package:sakina_app/features/quran/domain/services/quran_divisions.dart';

KhatmaModel _plan(KhatmaTrackingUnit unit, double daily, {double done = 0}) =>
    KhatmaModel(
      id: 'k',
      startMode: 'juz',
      startJuz: 1,
      startDate: DateTime.now(),
      trackingUnit: unit,
      goalType: KhatmaGoalType.byDailyAmount,
      plannedDurationDays: 30,
      dailyTargetUnits: daily,
      completedUnits: done,
      reminderHour: 20,
      reminderMinute: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuranDivisions divisions;

  setUpAll(() async {
    divisions = QuranDivisions.fromSurahs(await QuranMasterAsset.load());
  });

  test('twenty pages become four after each prayer', () {
    final portions = splitAcrossPrayers(1, 20);
    expect(
      [for (final p in portions) (p.fromPage, p.toPage)],
      [(1, 4), (5, 8), (9, 12), (13, 16), (17, 20)],
    );
    expect(portions.map((p) => p.prayer), DailyPrayer.values);
  });

  test(
    'a remainder goes to the earlier prayers; few pages skip later ones',
    () {
      expect(
        [for (final p in splitAcrossPrayers(10, 21)) p.toPage - p.fromPage + 1],
        [3, 3, 2, 2, 2],
      );
      final two = splitAcrossPrayers(7, 8);
      expect(two.map((p) => p.prayer), [DailyPrayer.fajr, DailyPrayer.dhuhr]);
      expect(splitAcrossPrayers(5, 4), isEmpty);
    },
  );

  test('a juz a day is the pages of that juz', () {
    final range = todayPageRange(_plan(KhatmaTrackingUnit.juz, 1), divisions);
    expect(range, (fromPage: 1, toPage: divisions.juz[1].page - 1));
    final last = todayPageRange(
      _plan(KhatmaTrackingUnit.juz, 1, done: 29),
      divisions,
    );
    expect(last!.toPage, QuranDivisions.pageCount);
  });

  test('a page plan uses its own pages; a finished plan has none', () {
    expect(
      todayPageRange(_plan(KhatmaTrackingUnit.page, 10, done: 20), divisions),
      (fromPage: 21, toPage: 30),
    );
    expect(
      todayPageRange(_plan(KhatmaTrackingUnit.page, 10, done: 604), divisions),
      isNull,
    );
  });

  test('reminder ids stay clear of every other alert range', () {
    final ids = allWirdPortionNotificationIds().toSet();
    expect(ids, hasLength(35));
    expect(ids.every((id) => id >= 6011 && id <= 6075), isTrue);
    expect(
      wirdPortionNotificationId(DateTime(2026, 11, 18), DailyPrayer.isha),
      6001 + 3 * 10 + 4,
    );
  });
}
