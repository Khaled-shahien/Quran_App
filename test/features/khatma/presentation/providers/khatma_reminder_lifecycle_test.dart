import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/khatma/data/repositories/khatma_repository.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';
import 'package:sakina_app/features/khatma/domain/services/khatma_reminder_service.dart';
import 'package:sakina_app/features/khatma/presentation/providers/khatma_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingReminders implements KhatmaReminderService {
  _RecordingReminders({this.fail = false});
  final bool fail;
  final bodies = <String>[];
  int cancels = 0;

  @override
  Future<void> cancelReminder(int notificationId) async => cancels++;

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
    if (fail) throw StateError('scheduling refused');
    bodies.add(body);
  }
}

KhatmaModel _khatma() => KhatmaModel(
  id: 'k1',
  startMode: 'بداية المصحف',
  startJuz: 1,
  startDate: DateTime(2026, 3, 1),
  trackingUnit: KhatmaTrackingUnit.juz,
  goalType: KhatmaGoalType.byDailyAmount,
  plannedDurationDays: 30,
  dailyTargetUnits: 1,
  completedUnits: 0,
  reminderHour: 8,
  reminderMinute: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<KhatmaRepository> repository() async {
    SharedPreferences.setMockInitialValues({});
    return KhatmaRepository(prefs: await SharedPreferences.getInstance());
  }

  test('finishing a wird moves the reminder text to the next range', () async {
    final reminders = _RecordingReminders();
    final provider = KhatmaProvider(
      repository: await repository(),
      reminderService: reminders,
    );

    await provider.startNewKhatma(_khatma());
    await provider.markCurrentWirdAsFinished();

    expect(reminders.bodies, hasLength(2));
    expect(reminders.bodies.last, isNot(reminders.bodies.first));
    expect(reminders.cancels, 0);
  });

  test('a plan is kept when its reminder cannot be scheduled', () async {
    final repo = await repository();
    final provider = KhatmaProvider(
      repository: repo,
      reminderService: _RecordingReminders(fail: true),
    );

    await provider.startNewKhatma(_khatma());

    expect(provider.hasActiveKhatma, isTrue);
    expect(repo.getActiveKhatma(), isNotNull);
  });
}
