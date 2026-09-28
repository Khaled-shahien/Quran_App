import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/models/khatma_model.dart';
import '../../domain/models/wird_reading_position.dart';
import '../../data/repositories/khatma_repository.dart';
import '../../domain/services/khatma_reminder_service.dart';
import '../../data/services/local_khatma_reminder_service.dart';
import '../../domain/services/khatma_quran_locator.dart';

class KhatmaProvider extends ChangeNotifier {
  static const int _khatmaReminderNotificationId = 1205;

  final KhatmaRepository repository;
  final KhatmaReminderService _reminderService;
  final KhatmaQuranLocator _quranLocator;
  KhatmaModel? _activeKhatma;
  WirdReadingPosition? _savedWirdPosition;

  KhatmaProvider({
    required this.repository,
    KhatmaReminderService? reminderService,
    KhatmaQuranLocator? quranLocator,
  }) : _reminderService = reminderService ?? LocalKhatmaReminderService(),
       _quranLocator = quranLocator ?? KhatmaQuranLocator() {
    _loadActiveKhatma();
  }

  KhatmaModel? get activeKhatma => _activeKhatma;
  bool get hasActiveKhatma => _activeKhatma != null;

  double get progressValue => _activeKhatma?.progress ?? 0;

  WirdReadingPosition? get savedWirdPosition {
    final KhatmaModel? khatma = _activeKhatma;
    if (khatma == null) return null;
    return savedWirdPositionFor(khatma);
  }

  KhatmaReportSummary? get weeklySummary => _activeKhatma?.summaryForDays(7);

  KhatmaReportSummary? get monthlySummary => _activeKhatma?.summaryForDays(30);

  void _loadActiveKhatma() {
    _activeKhatma = repository.getActiveKhatma();
    _savedWirdPosition = repository.getSavedWirdPosition();
    notifyListeners();
  }

  WirdReadingPosition? savedWirdPositionFor(KhatmaModel khatma) {
    final WirdReadingPosition? position = _savedWirdPosition;
    if (position == null || !position.matchesCurrentWird(khatma)) {
      return null;
    }
    return position;
  }

  Future<void> startNewKhatma(KhatmaModel khatma) async {
    final KhatmaAyahPosition startPosition = await _quranLocator
        .resolveStartPosition(
          trackingUnit: khatma.trackingUnit,
          unitIndex: khatma.todayFromUnit,
        );

    final KhatmaModel enriched = khatma.copyWith(
      nextSurahNumber: startPosition.surahNumber,
      nextAyahNumber: startPosition.ayahNumber,
      nextPageNumber: startPosition.pageNumber,
    );

    await repository.clearWirdPosition();
    _savedWirdPosition = null;
    await repository.saveKhatma(enriched);
    _activeKhatma = enriched;
    await _scheduleKhatmaReminder(enriched);
    notifyListeners();
  }

  Future<bool> saveWirdPosition({
    required String trackingUnitValue,
    required int fromUnit,
    required int toUnit,
    required int surahNumber,
    required int ayahNumber,
    required int pageNumber,
    required int pageIndex,
  }) async {
    final KhatmaModel? khatma = _activeKhatma;
    if (khatma == null || khatma.isCompleted) return false;

    final WirdReadingPosition position = WirdReadingPosition(
      khatmaId: khatma.id,
      trackingUnit: KhatmaTrackingUnitX.fromStorage(trackingUnitValue),
      fromUnit: fromUnit,
      toUnit: toUnit,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber,
      pageIndex: pageIndex,
      savedAt: DateTime.now(),
    );

    if (!position.matchesCurrentWird(khatma)) {
      return false;
    }

    await repository.saveWirdPosition(position);
    _savedWirdPosition = position;
    notifyListeners();
    return true;
  }

  Future<void> markCurrentWirdAsFinished() async {
    final KhatmaModel? current = _activeKhatma;
    if (current == null) return;

    final double readUnits = math.max(
      1,
      current.recommendedDailyTarget.ceilToDouble(),
    );
    final int completedFrom = current.todayFromUnit;
    final int completedTo = current.todayToUnit;

    final double nextCompleted = (current.completedUnits + readUnits).clamp(
      0,
      current.plannedUnits.toDouble(),
    );

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<KhatmaDailyLog> nextLogs = List<KhatmaDailyLog>.from(
      current.dailyLogs,
    );

    final int existingIndex = nextLogs.indexWhere(
      (log) =>
          log.date.year == today.year &&
          log.date.month == today.month &&
          log.date.day == today.day,
    );

    if (existingIndex >= 0) {
      final KhatmaDailyLog existing = nextLogs[existingIndex];
      nextLogs[existingIndex] = KhatmaDailyLog(
        date: existing.date,
        unitsRead: existing.unitsRead + readUnits,
      );
    } else {
      nextLogs.add(KhatmaDailyLog(date: now, unitsRead: readUnits));
    }

    final List<KhatmaCompletedWird> nextCompletedWirds =
        List<KhatmaCompletedWird>.from(current.completedWirds)..add(
          KhatmaCompletedWird(
            fromUnit: completedFrom,
            toUnit: completedTo,
            completedAt: now,
          ),
        );

    final bool completed = nextCompleted >= current.plannedUnits;
    KhatmaAyahPosition nextPosition;
    if (completed) {
      nextPosition = await _quranLocator.resolveLastAyah();
    } else {
      final int nextUnit = (completedTo + 1).clamp(1, current.totalUnits);
      nextPosition = await _quranLocator.resolveStartPosition(
        trackingUnit: current.trackingUnit,
        unitIndex: nextUnit,
      );
    }

    final KhatmaModel updatedKhatma = current.copyWith(
      completedUnits: nextCompleted,
      isCompleted: completed,
      nextSurahNumber: nextPosition.surahNumber,
      nextAyahNumber: nextPosition.ayahNumber,
      nextPageNumber: nextPosition.pageNumber,
      dailyLogs: nextLogs,
      completedWirds: nextCompletedWirds,
    );

    await repository.saveKhatma(updatedKhatma);
    await repository.clearWirdPosition();
    _activeKhatma = updatedKhatma;
    _savedWirdPosition = null;

    if (completed) {
      await _reminderService.cancelReminder(_khatmaReminderNotificationId);
    }

    notifyListeners();
  }

  Future<void> completeKhatma() async {
    final KhatmaModel? current = _activeKhatma;
    if (current == null) return;

    final updatedKhatma = current.copyWith(
      isCompleted: true,
      completedUnits: current.plannedUnits.toDouble(),
    );
    await repository.saveKhatma(updatedKhatma);
    await repository.clearWirdPosition();
    await _reminderService.cancelReminder(_khatmaReminderNotificationId);
    _activeKhatma = updatedKhatma;
    _savedWirdPosition = null;
    notifyListeners();
  }

  Future<void> updateDailyTarget(double targetUnits) async {
    final KhatmaModel? current = _activeKhatma;
    if (current == null) return;

    final KhatmaModel updatedKhatma = current.copyWith(
      dailyTargetUnits: targetUnits.clamp(1, 2000),
      goalType: KhatmaGoalType.byDailyAmount,
    );
    await repository.saveKhatma(updatedKhatma);
    _activeKhatma = updatedKhatma;
    await _scheduleKhatmaReminder(updatedKhatma);
    notifyListeners();
  }

  Future<void> updatePlan({
    required KhatmaGoalType goalType,
    double? dailyTargetUnits,
    int? durationDays,
    TimeOfDay? reminder,
  }) async {
    final KhatmaModel? current = _activeKhatma;
    if (current == null) return;

    final DateTime today = DateTime.now();
    final DateTime normalizedStart = DateTime(
      today.year,
      today.month,
      today.day,
    );

    double nextTarget;
    int nextDuration;

    if (goalType == KhatmaGoalType.byDuration) {
      nextDuration = (durationDays ?? current.plannedDurationDays).clamp(
        1,
        3650,
      );
      nextTarget = (current.remainingUnits / nextDuration).clamp(1, 2000);
    } else {
      nextTarget = (dailyTargetUnits ?? current.dailyTargetUnits).clamp(
        1,
        2000,
      );
      nextDuration = math.max(1, (current.remainingUnits / nextTarget).ceil());
    }

    final KhatmaModel updated = current.copyWith(
      goalType: goalType,
      dailyTargetUnits: nextTarget,
      plannedDurationDays: nextDuration,
      reminderHour: reminder?.hour ?? current.reminderHour,
      reminderMinute: reminder?.minute ?? current.reminderMinute,
      startDate: goalType == KhatmaGoalType.byDuration
          ? normalizedStart
          : current.startDate,
    );

    await repository.saveKhatma(updated);
    _activeKhatma = updated;
    await _scheduleKhatmaReminder(updated);
    notifyListeners();
  }

  Future<void> updateReminderTime(TimeOfDay reminder) async {
    final KhatmaModel? current = _activeKhatma;
    if (current == null) return;

    final KhatmaModel updatedKhatma = current.copyWith(
      reminderHour: reminder.hour,
      reminderMinute: reminder.minute,
    );
    await repository.saveKhatma(updatedKhatma);
    _activeKhatma = updatedKhatma;
    await _scheduleKhatmaReminder(updatedKhatma);
    notifyListeners();
  }

  Future<void> resumeAfterGap() async {
    final KhatmaModel? current = _activeKhatma;
    if (current == null) return;

    if (current.goalType != KhatmaGoalType.byDuration || current.isCompleted) {
      return;
    }

    final DateTime now = DateTime.now();
    final int daysPassed =
        DateTime(now.year, now.month, now.day)
            .difference(
              DateTime(
                current.startDate.year,
                current.startDate.month,
                current.startDate.day,
              ),
            )
            .inDays +
        1;

    final int daysLeft = (current.plannedDurationDays - (daysPassed - 1)).clamp(
      1,
      3650,
    );
    final double recalculatedTarget = current.remainingUnits / daysLeft;

    final KhatmaModel updatedKhatma = current.copyWith(
      dailyTargetUnits: recalculatedTarget,
    );
    await repository.saveKhatma(updatedKhatma);
    _activeKhatma = updatedKhatma;
    await _scheduleKhatmaReminder(updatedKhatma);
    notifyListeners();
  }

  Future<void> cancelKhatma() async {
    await _reminderService.cancelReminder(_khatmaReminderNotificationId);
    await repository.deleteActiveKhatma();
    await repository.clearWirdPosition();
    _activeKhatma = null;
    _savedWirdPosition = null;
    notifyListeners();
  }

  Future<void> _scheduleKhatmaReminder(KhatmaModel khatma) async {
    if (khatma.isCompleted) {
      await _reminderService.cancelReminder(_khatmaReminderNotificationId);
      return;
    }

    await _reminderService.scheduleDailyReminder(
      notificationId: _khatmaReminderNotificationId,
      title: appL10n.khatmaProviderMessage1,
      body: appL10n.khatmaProviderMessage2(
        (khatma.amountValue).toString(),
        (khatma.todayFromUnit).toString(),
        (khatma.todayToUnit).toString(),
      ),
      hour: khatma.reminderHour,
      minute: khatma.reminderMinute,
      payload: 'khatma',
      payloadData: <String, dynamic>{
        'feature': 'khatma',
        'khatmaId': khatma.id,
      },
    );
  }
}
