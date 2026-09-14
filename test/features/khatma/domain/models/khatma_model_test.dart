import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';

void main() {
  group('KhatmaModel', () {
    test('computes planning fields from start juz and tracking unit', () {
      final model = KhatmaModel(
        id: '1',
        startMode: 'بداية المصحف',
        startJuz: 2,
        startDate: DateTime(2026, 3, 1),
        trackingUnit: KhatmaTrackingUnit.page,
        goalType: KhatmaGoalType.byDailyAmount,
        plannedDurationDays: 30,
        dailyTargetUnits: 10,
        completedUnits: 0,
        reminderHour: 8,
        reminderMinute: 0,
      );

      expect(model.startUnitIndex, 21);
      expect(model.plannedUnits, 584);
      expect(model.progress, 0);
      expect(model.todayFromUnit, 21);
      expect(model.todayToUnit, 30);
    });

    test('parses legacy fields and keeps backward compatibility values', () {
      final json = <String, dynamic>{
        'id': 'legacy',
        'startMode': 'جزء مخصص',
        'startJuz': 1,
        'durationDays': 20,
        'amountType': 'ربع',
        'amountValue': 'ربعان',
        'startDate': DateTime(2026, 3, 1).toIso8601String(),
        'currentJuz': 3,
      };

      final model = KhatmaModel.fromJson(json);

      expect(model.trackingUnit, KhatmaTrackingUnit.hizb);
      expect(model.plannedDurationDays, 20);
      expect(model.dailyTargetUnits, 1);
      expect(model.completedUnits, 2);
      expect(model.amountType, 'حزب');
    });

    test('summaryForDays returns read amount in time window', () {
      final now = DateTime.now();
      final model = KhatmaModel(
        id: '2',
        startMode: 'بداية المصحف',
        startJuz: 1,
        startDate: DateTime(2026, 3, 1),
        trackingUnit: KhatmaTrackingUnit.juz,
        goalType: KhatmaGoalType.byDailyAmount,
        plannedDurationDays: 30,
        dailyTargetUnits: 1,
        completedUnits: 4,
        reminderHour: 8,
        reminderMinute: 0,
        dailyLogs: <KhatmaDailyLog>[
          KhatmaDailyLog(
            date: now.subtract(const Duration(days: 1)),
            unitsRead: 1,
          ),
          KhatmaDailyLog(
            date: now.subtract(const Duration(days: 3)),
            unitsRead: 2,
          ),
          KhatmaDailyLog(
            date: now.subtract(const Duration(days: 10)),
            unitsRead: 5,
          ),
        ],
      );

      final summary = model.summaryForDays(7);

      expect(summary.readUnits, 3);
      expect(summary.remainingUnits, 26);
      expect(summary.progress, closeTo(4 / 30, 0.0001));
    });

    test('serializes core fields as snake_case keys', () {
      final model = KhatmaModel(
        id: 'snake',
        startMode: 'بداية المصحف',
        startJuz: 1,
        startDate: DateTime(2026, 3, 1),
        trackingUnit: KhatmaTrackingUnit.juz,
        goalType: KhatmaGoalType.byDuration,
        plannedDurationDays: 30,
        dailyTargetUnits: 1,
        completedUnits: 2,
        reminderHour: 7,
        reminderMinute: 30,
        isCompleted: false,
      );

      final json = model.toJson();

      expect(json.containsKey('start_mode'), isTrue);
      expect(json.containsKey('start_juz'), isTrue);
      expect(json.containsKey('start_date'), isTrue);
      expect(json.containsKey('tracking_unit'), isTrue);
      expect(json.containsKey('planned_duration_days'), isTrue);
      expect(json.containsKey('daily_target_units'), isTrue);
      expect(json.containsKey('completed_units'), isTrue);
      expect(json.containsKey('daily_logs'), isTrue);
      expect(json.containsKey('completed_wirds'), isTrue);
    });

    test('parses snake_case payload with expected values', () {
      final json = <String, dynamic>{
        'id': 'snake-input',
        'start_mode': 'بداية المصحف',
        'start_juz': 2,
        'start_date': DateTime(2026, 3, 1).toIso8601String(),
        'tracking_unit': 'juz',
        'goal_type': 'byDuration',
        'planned_duration_days': 20,
        'daily_target_units': 1.5,
        'completed_units': 3,
        'reminder_hour': 6,
        'reminder_minute': 15,
        'is_completed': true,
        'daily_logs': <Map<String, dynamic>>[
          {'date': DateTime(2026, 3, 2).toIso8601String(), 'units_read': 1},
        ],
        'completed_wirds': <Map<String, dynamic>>[
          {
            'from_unit': 1,
            'to_unit': 2,
            'completed_at': DateTime(2026, 3, 2).toIso8601String(),
            'is_completed': true,
          },
        ],
      };

      final model = KhatmaModel.fromJson(json);

      expect(model.startJuz, 2);
      expect(model.plannedDurationDays, 20);
      expect(model.dailyTargetUnits, 1.5);
      expect(model.completedUnits, 3);
      expect(model.isCompleted, isTrue);
      expect(model.dailyLogs, hasLength(1));
      expect(model.completedWirds, hasLength(1));
      expect(model.dailyLogs.first.unitsRead, 1);
      expect(model.completedWirds.first.fromUnit, 1);
    });
  });
}
