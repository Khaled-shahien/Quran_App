import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/services/alarm_reschedule_task_service.dart';
import 'package:sakina_app/core/services/alarm_scheduler.dart';
import 'package:sakina_app/core/services/notification_scheduling_coordinator.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/date_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows weekday, Hijri and Gregorian dates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: DateCardWidget(clock: () => DateTime(2024, 3, 11, 10)),
          ),
        ),
      ),
    );

    expect(find.text('الاثنين'), findsOneWidget);
    expect(find.textContaining('1 رمضان 1445هـ', findRichText: true), findsOne);
    expect(find.textContaining('11 مارس 2024م', findRichText: true), findsOne);

    // The midnight refresh timer must not leak past the widget.
    await tester.pumpWidget(const SizedBox());
  });

  hijriAdjustmentTests();
}

void hijriAdjustmentTests() {
  Future<SettingsProvider> settingsWith(int offset) async {
    SharedPreferences.setMockInitialValues({
      SettingsProvider.hijriOffsetKey: offset,
    });
    return SettingsProvider(
      prefs: await SharedPreferences.getInstance(),
      schedulingCoordinator: NotificationSchedulingCoordinator(
        alarmScheduler: _NoopAlarmScheduler(),
        rescheduleTaskService: _NoopRescheduleTaskService(),
      ),
    );
  }

  Widget card(SettingsProvider settings) =>
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: DateCardWidget(clock: () => DateTime(2024, 3, 11, 10)),
          ),
        ),
      );

  testWidgets('applies the saved Hijri adjustment', (tester) async {
    await tester.pumpWidget(card(await settingsWith(-1)));

    expect(find.textContaining('29 شعبان 1445هـ'), findsOne);
    // The Gregorian date never moves.
    expect(find.textContaining('11 مارس 2024م'), findsOne);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('updates immediately when the setting changes', (tester) async {
    final settings = await settingsWith(0);
    await tester.pumpWidget(card(settings));
    expect(find.textContaining('1 رمضان 1445هـ'), findsOne);

    await tester.runAsync(() => settings.setHijriOffsetDays(1));
    await tester.pump();

    expect(find.textContaining('2 رمضان 1445هـ'), findsOne);
    await tester.pumpWidget(const SizedBox());
  });

  test('rejects adjustments beyond one day', () async {
    final settings = await settingsWith(0);
    expect(() => settings.setHijriOffsetDays(2), throwsArgumentError);
  });

  test('ignores an out-of-range stored value', () async {
    final settings = await settingsWith(5);
    expect(settings.hijriOffsetDays, 0);
  });
}

class _NoopAlarmScheduler implements AlarmScheduler {
  @override
  Future<Map<String, int>> getAlarmTime(String type) async => {};
  @override
  Future<void> initialize({bool requestPermissions = false}) async {}
  @override
  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {}
  @override
  Future<void> saveAlarmTime({
    required String type,
    required int hour,
    required int minute,
  }) async {}
  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {}
}

class _NoopRescheduleTaskService implements AlarmRescheduleTaskService {
  @override
  Future<void> registerImmediateRescheduleTask({String source = ''}) async {}
}
