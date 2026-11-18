import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/utils/hijri_calendar_data.dart';
import 'package:sakina_app/features/calendar/presentation/hijri_calendar_screen.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/ramadan_card.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';

void main() {
  late List<IslamicOccasion> occasions;

  setUpAll(() {
    occasions = IslamicOccasions.parse(
      File(IslamicOccasions.path).readAsStringSync(),
    );
  });

  group('Hijri conversion', () {
    const converter = HijriConverter();

    test('known Umm al-Qura dates', () {
      // 1 Ramadan 1447 = 18 Feb 2026; 10 Dhu al-Hijjah 1447 = 27 May 2026.
      expect(converter.of(DateTime(2026, 2, 18)), (
        year: 1447,
        month: 9,
        day: 1,
      ));
      expect(converter.civilOf(1447, 12, 10), DateTime(2026, 5, 27));
      expect(converter.daysIn(1447, 9), anyOf(29, 30));
    });

    test('the offset moves the shown Hijri date, both ways', () {
      const ahead = HijriConverter(offsetDays: 1);
      expect(ahead.of(DateTime(2026, 2, 17)), (year: 1447, month: 9, day: 1));
      expect(ahead.civilOf(1447, 9, 1), DateTime(2026, 2, 17));
    });

    test('a month lists every day once, in order', () {
      final days = converter.month(1447, 9);
      expect(days.first.civil, DateTime(2026, 2, 18));
      for (var i = 1; i < days.length; i++) {
        expect(daysBetween(days[i - 1].civil, days[i].civil), 1);
      }
    });
  });

  group('occasions', () {
    test('the bundled list parses and holds no contested dates', () {
      final ids = occasions.map((o) => o.id).toSet();
      expect(
        ids,
        containsAll(['arafah', 'eid_al_fitr', 'eid_al_adha', 'ramadan']),
      );
      expect(ids.any((id) => id.contains('mawlid')), isFalse);
      expect(occasions.firstWhere((o) => o.id == 'white_days').month, isNull);
    });

    test('upcoming occasions count whole days', () {
      final list = IslamicOccasions.upcoming(
        occasions,
        DateTime(2026, 5, 20),
        const HijriConverter(),
      );
      final arafah = list.firstWhere((u) => u.occasion.id == 'arafah');
      expect(arafah.start, DateTime(2026, 5, 26));
      expect(arafah.days, 6);
      expect(
        list.first.start.isBefore(list.last.start) ||
            list.first.start == list.last.start,
        isTrue,
      );
    });

    test('an occasion under way reads as now', () {
      final list = IslamicOccasions.upcoming(
        occasions,
        DateTime(2026, 3, 1),
        const HijriConverter(),
      );
      expect(list.first.occasion.id, 'ramadan');
      expect(list.first.days, 0);
    });
  });

  group('Ramadan card', () {
    final today = {
      DailyPrayer.fajr: DateTime(2026, 3, 1, 4, 30),
      DailyPrayer.maghrib: DateTime(2026, 3, 1, 17, 50),
    };

    test('Imsak ten minutes before Fajr; the next event follows the time', () {
      final early = ramadanState(
        hijri: (year: 1447, month: 9, day: 12),
        today: today,
        now: DateTime(2026, 3, 1, 3, 0),
      )!;
      expect(early.day, 12);
      expect(early.imsak, DateTime(2026, 3, 1, 4, 20));
      expect(early.nextIsIftar, isFalse);

      final noon = ramadanState(
        hijri: (year: 1447, month: 9, day: 12),
        today: today,
        now: DateTime(2026, 3, 1, 12, 0),
      )!;
      expect(noon.nextIsIftar, isTrue);
    });

    test('hidden outside Ramadan', () {
      expect(
        ramadanState(
          hijri: (year: 1447, month: 10, day: 1),
          today: today,
          now: DateTime(2026, 3, 1, 12),
        ),
        isNull,
      );
    });
  });

  testWidgets('the calendar shows the month, today and its occasions', (
    tester,
  ) async {
    final source = IslamicOccasions(
      load: () async => File(IslamicOccasions.path).readAsStringSync(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HijriCalendarScreen(
          today: DateTime(2026, 5, 26),
          occasions: source,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ذو الحجة 1447هـ'), findsOneWidget);
    expect(find.text('يوم عرفة'), findsWidgets);
    await tester.tap(find.byTooltip('الشهر التالي'));
    await tester.pumpAndSettle();
    expect(find.text('محرم 1448هـ'), findsOneWidget);
    expect(find.text('العودة إلى الشهر الحالي'), findsOneWidget);
  });
}
