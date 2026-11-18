import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/prayers/presentation/widgets/prayer_calculation_sheets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository implements PrayerTimesRepository {
  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
    PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none,
  }) async => Success(
    PrayerTimesEntity(
      fajr: '05:00',
      sunrise: '06:20',
      dhuhr: '12:00',
      asr: '15:00',
      maghrib: '18:00',
      isha: '19:30',
      timezone: timeZone ?? 'Africa/Cairo',
    ),
  );
}

void main() {
  late PrayerTimesProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = PrayerTimesProvider(
      repository: _Repository(),
      preferences: await SharedPreferences.getInstance(),
    );
    await provider.selectLocation(
      21.4225,
      39.8262,
      'مكة',
      PrayerCalculationPolicy.ummAlQura,
      timeZone: 'Asia/Riyadh',
    );
  });

  Future<void> open(
    WidgetTester tester,
    Future<void> Function(BuildContext) show,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the explanation shows the method and its Isha rule', (
    tester,
  ) async {
    await open(
      tester,
      (context) => showPrayerCalculationExplanation(context, provider),
    );
    expect(find.text('طريقة حساب المواقيت'), findsOneWidget);
    expect(find.text('أم القرى'), findsOneWidget);
    // Umm al-Qura: Fajr by angle, Isha a fixed time after Maghrib.
    expect(find.textContaining('18.5°'), findsOneWidget);
    expect(find.textContaining('بعد المغرب بـ'), findsOneWidget);
    expect(find.text('Asia/Riyadh'), findsOneWidget);
    expect(find.text('بلا تعديل'), findsOneWidget);
  });

  testWidgets('steppers change and reset the adjustments', (tester) async {
    await open(
      tester,
      (context) => showPrayerAdjustmentsSheet(context, provider),
    );
    await tester.tap(find.byTooltip('بعد الفجر بدقيقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('بعد الفجر بدقيقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('قبل العشاء بدقيقة'));
    await tester.pumpAndSettle();

    expect(provider.adjustments.of(PrayerTimeKind.fajr), 2);
    expect(provider.adjustments.of(PrayerTimeKind.isha), -1);
    expect(find.text('+2 د'), findsOneWidget);

    await tester.tap(find.text('إلغاء كل التعديلات'));
    await tester.pumpAndSettle();
    expect(provider.adjustments.isEmpty, isTrue);
  });
}
