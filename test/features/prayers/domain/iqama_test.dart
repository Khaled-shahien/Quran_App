import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/anchored_reminders.dart';
import 'package:sakina_app/features/khatma/domain/services/wird_portions.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/domain/iqama.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/iqama_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('iqama is the adhan plus the minutes set; unset prayers have none', () {
    const settings = IqamaSettings(minutes: {DailyPrayer.isha: 15});
    final adhan = DateTime(2026, 11, 18, 18, 18);
    expect(
      settings.iqamaAt(DailyPrayer.isha, adhan),
      DateTime(2026, 11, 18, 18, 33),
    );
    expect(settings.iqamaAt(DailyPrayer.fajr, adhan), isNull);
    expect(settings.isEmpty, isFalse);
    expect(const IqamaSettings().isEmpty, isTrue);
  });

  test('stored per prayer; unknown values are ignored', () async {
    SharedPreferences.setMockInitialValues({
      IqamaStore.minutesKey(DailyPrayer.fajr): 7,
      IqamaStore.alertKey: 99,
    });
    final prefs = await SharedPreferences.getInstance();
    final store = IqamaStore(prefs);
    expect(store.read().isEmpty, isTrue);
    expect(store.read().alertMinutes, 0);
    await store.write(
      const IqamaSettings(
        minutes: {DailyPrayer.dhuhr: 20, DailyPrayer.isha: 10},
        alertMinutes: 5,
      ),
    );
    final read = IqamaStore(prefs).read();
    expect(read.of(DailyPrayer.dhuhr), 20);
    expect(read.of(DailyPrayer.isha), 10);
    expect(read.of(DailyPrayer.fajr), 0);
    expect(read.alertMinutes, 5);
    expect(prefs.containsKey(IqamaStore.minutesKey(DailyPrayer.fajr)), isFalse);
  });

  test('displayed times add minutes across midnight', () {
    expect(addMinutesToClock('18:18', 15), '18:33');
    expect(addMinutesToClock('23:50', 20), '00:10');
    expect(addMinutesToClock('N/A', 5), isNull);
  });

  test('alert ids do not collide with other scheduled reminders', () {
    final iqama = allIqamaNotificationIds().toSet();
    expect(iqama, hasLength(35));
    expect(
      iqama.intersection(allWirdPortionNotificationIds().toSet()),
      isEmpty,
    );
    expect(iqama.intersection(AnchoredReminders.allIds().toSet()), isEmpty);
    expect(iqama.every((id) => id >= 8011 && id <= 8075), isTrue);
  });
}
