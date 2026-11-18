import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/anchored_reminders.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/now_card.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _day = DateTime(2026, 11, 20); // a Friday
final Map<DailyPrayer, DateTime> _times = {
  DailyPrayer.fajr: DateTime(2026, 11, 20, 4, 50),
  DailyPrayer.dhuhr: DateTime(2026, 11, 20, 11, 40),
  DailyPrayer.asr: DateTime(2026, 11, 20, 14, 35),
  DailyPrayer.maghrib: DateTime(2026, 11, 20, 16, 58),
  DailyPrayer.isha: DateTime(2026, 11, 20, 18, 18),
};

DateTime _at(int h, int m) => DateTime(_day.year, _day.month, _day.day, h, m);

void main() {
  group('anchored reminders', () {
    test('follow Fajr and Asr by the chosen minutes', () async {
      SharedPreferences.setMockInitialValues({
        AnchoredReminders.morningEnabledKey: true,
        AnchoredReminders.eveningEnabledKey: true,
        AnchoredReminders.morningKey: 20,
        AnchoredReminders.eveningKey: 0,
      });
      final prefs = await SharedPreferences.getInstance();
      final plan = AnchoredReminders.plan(
        prayerTimes: _times,
        prefs: prefs,
        now: _at(0, 0),
      );
      expect(plan.map((r) => r.at), [_at(5, 10), _at(14, 35)]);
      expect(plan.first.id, AnchoredReminders.morningId(_day));
      expect(plan.first.id, 5051, reason: 'Friday slot');
    });

    test(
      'nothing for a disabled or clock-time reminder, or a past time',
      () async {
        SharedPreferences.setMockInitialValues({
          AnchoredReminders.morningEnabledKey: false,
          AnchoredReminders.morningKey: 20,
          AnchoredReminders.eveningEnabledKey: true,
        });
        final prefs = await SharedPreferences.getInstance();
        expect(
          AnchoredReminders.plan(
            prayerTimes: _times,
            prefs: prefs,
            now: _at(0, 0),
          ),
          isEmpty,
        );
        await prefs.setInt(AnchoredReminders.eveningKey, 15);
        expect(
          AnchoredReminders.plan(
            prayerTimes: _times,
            prefs: prefs,
            now: _at(15, 0),
          ),
          isEmpty,
          reason: 'Asr + 15 already passed',
        );
      },
    );

    test('an unknown stored offset reads as clock time', () async {
      SharedPreferences.setMockInitialValues({AnchoredReminders.morningKey: 7});
      expect(
        AnchoredReminders.morning(await SharedPreferences.getInstance()),
        isNull,
      );
    });

    test('ids never collide with other notifications', () {
      final ids = AnchoredReminders.allIds().toSet();
      expect(ids, hasLength(16));
      expect(ids.every((id) => id >= 5001 && id <= 5072), isTrue);
    });
  });

  group('now card', () {
    NowPlan at(int h, int m, {bool friday = false}) =>
        planNow(today: _times, now: _at(h, m), friday: friday);

    test('suggests the adhkar of the time of day', () {
      expect(at(5, 0).main, NowSuggestion.morningAdhkar);
      expect(at(11, 0).main, NowSuggestion.morningAdhkar);
      expect(at(12, 0).main, isNull);
      expect(at(15, 0).main, NowSuggestion.eveningAdhkar);
      expect(at(19, 0).main, NowSuggestion.sleepAdhkar);
      expect(at(3, 0).main, NowSuggestion.sleepAdhkar);
    });

    test('Surat al-Kahf on Friday until Maghrib', () {
      expect(at(12, 0, friday: true).kahf, isTrue);
      expect(at(17, 30, friday: true).kahf, isFalse);
      expect(at(12, 0).kahf, isFalse);
    });

    test('nothing without a full day of times', () {
      final plan = planNow(today: const {}, now: _at(5, 0), friday: true);
      expect(plan.main, isNull);
      expect(plan.kahf, isFalse);
    });
  });
}
