import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/features/khatma/data/repositories/khatma_repository.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';
import 'package:sakina_app/features/khatma/domain/services/khatma_reminder_service.dart';
import 'package:sakina_app/features/khatma/presentation/providers/khatma_provider.dart';

class FakeKhatmaReminderService implements KhatmaReminderService {
  int scheduleCount = 0;
  int cancelCount = 0;
  int? lastCancelId;
  int? lastScheduleId;

  @override
  Future<void> cancelReminder(int notificationId) async {
    cancelCount++;
    lastCancelId = notificationId;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int notificationId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    Map<String, dynamic>? payloadData,
  }) async {
    scheduleCount++;
    lastScheduleId = notificationId;
  }
}

KhatmaModel _baseKhatma({double completedUnits = 0, bool isCompleted = false}) {
  return KhatmaModel(
    id: 'k1',
    startMode: 'بداية المصحف',
    startJuz: 1,
    startDate: DateTime(2026, 3, 1),
    trackingUnit: KhatmaTrackingUnit.juz,
    goalType: KhatmaGoalType.byDailyAmount,
    plannedDurationDays: 30,
    dailyTargetUnits: 1,
    completedUnits: completedUnits,
    reminderHour: 8,
    reminderMinute: 0,
    isCompleted: isCompleted,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startNewKhatma schedules daily reminder', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = KhatmaRepository(prefs: prefs);
    final reminders = FakeKhatmaReminderService();

    final provider = KhatmaProvider(
      repository: repository,
      reminderService: reminders,
    );

    await provider.startNewKhatma(_baseKhatma());

    expect(provider.hasActiveKhatma, isTrue);
    expect(reminders.scheduleCount, 1);
    expect(reminders.lastScheduleId, 1205);
  });

  test('markCurrentWirdAsFinished updates progress and logs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = KhatmaRepository(prefs: prefs);
    final reminders = FakeKhatmaReminderService();

    final provider = KhatmaProvider(
      repository: repository,
      reminderService: reminders,
    );

    await provider.startNewKhatma(_baseKhatma());
    await provider.markCurrentWirdAsFinished();

    final active = provider.activeKhatma;
    expect(active, isNotNull);
    expect(active!.completedUnits, 1);
    expect(active.dailyLogs.length, 1);
    expect(active.completedWirds.length, 1);
    expect(active.isCompleted, isFalse);
  });

  test(
    'saved wird position is cleared when current wird is finished',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = KhatmaRepository(prefs: prefs);
      final reminders = FakeKhatmaReminderService();

      final provider = KhatmaProvider(
        repository: repository,
        reminderService: reminders,
      );

      await provider.startNewKhatma(_baseKhatma());
      final bool saved = await provider.saveWirdPosition(
        trackingUnitValue: 'juz',
        fromUnit: 1,
        toUnit: 1,
        surahNumber: 2,
        ayahNumber: 20,
        pageNumber: 4,
        pageIndex: 1,
      );

      expect(saved, isTrue);
      expect(provider.savedWirdPosition, isNotNull);
      expect(repository.getSavedWirdPosition(), isNotNull);

      await provider.markCurrentWirdAsFinished();

      expect(provider.savedWirdPosition, isNull);
      expect(repository.getSavedWirdPosition(), isNull);
    },
  );

  test('saved wird position ignores a different current range', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = KhatmaRepository(prefs: prefs);
    final reminders = FakeKhatmaReminderService();

    final provider = KhatmaProvider(
      repository: repository,
      reminderService: reminders,
    );

    await provider.startNewKhatma(_baseKhatma());
    final bool saved = await provider.saveWirdPosition(
      trackingUnitValue: 'juz',
      fromUnit: 2,
      toUnit: 2,
      surahNumber: 2,
      ayahNumber: 142,
      pageNumber: 22,
      pageIndex: 0,
    );

    expect(saved, isFalse);
    expect(provider.savedWirdPosition, isNull);
    expect(repository.getSavedWirdPosition(), isNull);
  });

  test('markCurrentWirdAsFinished cancels reminder on completion', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = KhatmaRepository(prefs: prefs);
    final reminders = FakeKhatmaReminderService();

    final provider = KhatmaProvider(
      repository: repository,
      reminderService: reminders,
    );

    await provider.startNewKhatma(_baseKhatma(completedUnits: 29));
    await provider.markCurrentWirdAsFinished();

    final active = provider.activeKhatma;
    expect(active, isNotNull);
    expect(active!.isCompleted, isTrue);
    expect(reminders.cancelCount, 1);
    expect(reminders.lastCancelId, 1205);
  });
}
