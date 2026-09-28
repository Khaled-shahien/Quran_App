import 'package:sakina_app/l10n/localization.dart';
import 'dart:math' as math;

import 'package:json_annotation/json_annotation.dart';

part 'khatma_model.g.dart';

enum KhatmaTrackingUnit { page, hizb, juz }

extension KhatmaTrackingUnitX on KhatmaTrackingUnit {
  String get storageValue {
    switch (this) {
      case KhatmaTrackingUnit.page:
        return 'page';
      case KhatmaTrackingUnit.hizb:
        return 'hizb';
      case KhatmaTrackingUnit.juz:
        return 'juz';
    }
  }

  String get arabicLabel {
    switch (this) {
      case KhatmaTrackingUnit.page:
        return appL10n.khatmaModelMessage1;
      case KhatmaTrackingUnit.hizb:
        return appL10n.khatmaModelMessage2;
      case KhatmaTrackingUnit.juz:
        return appL10n.khatmaModelMessage3;
    }
  }

  int get totalUnits {
    switch (this) {
      case KhatmaTrackingUnit.page:
        return 604;
      case KhatmaTrackingUnit.hizb:
        return 60;
      case KhatmaTrackingUnit.juz:
        return 30;
    }
  }

  static KhatmaTrackingUnit fromStorage(String? value) {
    switch (value) {
      case 'page':
      case 'صفحة':
        return KhatmaTrackingUnit.page;
      case 'hizb':
      case 'حزب':
      case 'ربع':
        return KhatmaTrackingUnit.hizb;
      case 'juz':
      case 'جزء':
      default:
        return KhatmaTrackingUnit.juz;
    }
  }
}

enum KhatmaGoalType { byDuration, byDailyAmount }

extension KhatmaGoalTypeX on KhatmaGoalType {
  String get storageValue {
    switch (this) {
      case KhatmaGoalType.byDuration:
        return 'byDuration';
      case KhatmaGoalType.byDailyAmount:
        return 'byDailyAmount';
    }
  }

  static KhatmaGoalType fromStorage(String? value) {
    switch (value) {
      case 'byDailyAmount':
        return KhatmaGoalType.byDailyAmount;
      case 'byDuration':
      default:
        return KhatmaGoalType.byDuration;
    }
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KhatmaDailyLog {
  @JsonKey(fromJson: KhatmaModel.parseDateTime, toJson: KhatmaModel.dateToJson)
  final DateTime date;

  @JsonKey(fromJson: KhatmaModel.parseDouble, defaultValue: 0)
  final double unitsRead;

  const KhatmaDailyLog({required this.date, required this.unitsRead});

  factory KhatmaDailyLog.fromJson(Map<String, dynamic> json) =>
      _$KhatmaDailyLogFromJson(json);

  Map<String, dynamic> toJson() => _$KhatmaDailyLogToJson(this);
}

class KhatmaReportSummary {
  final double readUnits;
  final double remainingUnits;
  final double progress;

  const KhatmaReportSummary({
    required this.readUnits,
    required this.remainingUnits,
    required this.progress,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KhatmaCompletedWird {
  @JsonKey(fromJson: KhatmaModel.parseInt, defaultValue: 1)
  final int fromUnit;

  @JsonKey(fromJson: KhatmaModel.parseInt, defaultValue: 1)
  final int toUnit;

  @JsonKey(fromJson: KhatmaModel.parseDateTime, toJson: KhatmaModel.dateToJson)
  final DateTime completedAt;

  @JsonKey(fromJson: KhatmaModel.parseBool, defaultValue: true)
  final bool isCompleted;

  const KhatmaCompletedWird({
    required this.fromUnit,
    required this.toUnit,
    required this.completedAt,
    this.isCompleted = true,
  });

  factory KhatmaCompletedWird.fromJson(Map<String, dynamic> json) =>
      _$KhatmaCompletedWirdFromJson(json);

  Map<String, dynamic> toJson() => _$KhatmaCompletedWirdToJson(this);
}

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class KhatmaModel {
  @JsonKey(defaultValue: '')
  final String id;

  @JsonKey(defaultValue: 'بداية المصحف')
  final String startMode;

  @JsonKey(fromJson: parseInt, defaultValue: 1)
  final int startJuz;

  @JsonKey(fromJson: parseDateTime, toJson: dateToJson)
  final DateTime startDate;

  @JsonKey(defaultValue: KhatmaTrackingUnit.juz)
  final KhatmaTrackingUnit trackingUnit;

  @JsonKey(defaultValue: KhatmaGoalType.byDuration)
  final KhatmaGoalType goalType;

  @JsonKey(fromJson: parseInt, defaultValue: 30)
  final int plannedDurationDays;

  @JsonKey(fromJson: parseDouble, defaultValue: 1)
  final double dailyTargetUnits;

  @JsonKey(fromJson: parseDouble, defaultValue: 0)
  final double completedUnits;

  @JsonKey(fromJson: parseInt, defaultValue: 8)
  final int reminderHour;

  @JsonKey(fromJson: parseInt, defaultValue: 0)
  final int reminderMinute;

  @JsonKey(fromJson: parseBool, defaultValue: false)
  final bool isCompleted;

  @JsonKey(fromJson: parseNullableInt)
  final int? nextSurahNumber;

  @JsonKey(fromJson: parseNullableInt)
  final int? nextAyahNumber;

  @JsonKey(fromJson: parseNullableInt)
  final int? nextPageNumber;

  final List<KhatmaDailyLog> dailyLogs;

  final List<KhatmaCompletedWird> completedWirds;

  KhatmaModel({
    required this.id,
    required this.startMode,
    required this.startJuz,
    required this.startDate,
    required this.trackingUnit,
    required this.goalType,
    required this.plannedDurationDays,
    required this.dailyTargetUnits,
    required this.completedUnits,
    required this.reminderHour,
    required this.reminderMinute,
    this.isCompleted = false,
    this.nextSurahNumber,
    this.nextAyahNumber,
    this.nextPageNumber,
    this.dailyLogs = const <KhatmaDailyLog>[],
    this.completedWirds = const <KhatmaCompletedWird>[],
  });

  factory KhatmaModel.fromJson(Map<String, dynamic> json) =>
      _$KhatmaModelFromJson(_normalizeLegacyJson(json));

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = _$KhatmaModelToJson(this);
    // Legacy compatibility fields for old UI/readers.
    data.addAll(<String, dynamic>{
      'durationDays': durationDays,
      'amountType': amountType,
      'amountValue': amountValue,
      'currentJuz': currentJuz,
      'completedDays': completedDays,
    });
    return data;
  }

  KhatmaModel copyWith({
    String? id,
    String? startMode,
    int? startJuz,
    DateTime? startDate,
    KhatmaTrackingUnit? trackingUnit,
    KhatmaGoalType? goalType,
    int? plannedDurationDays,
    double? dailyTargetUnits,
    double? completedUnits,
    int? reminderHour,
    int? reminderMinute,
    bool? isCompleted,
    int? nextSurahNumber,
    int? nextAyahNumber,
    int? nextPageNumber,
    List<KhatmaDailyLog>? dailyLogs,
    List<KhatmaCompletedWird>? completedWirds,
  }) {
    return KhatmaModel(
      id: id ?? this.id,
      startMode: startMode ?? this.startMode,
      startJuz: startJuz ?? this.startJuz,
      startDate: startDate ?? this.startDate,
      trackingUnit: trackingUnit ?? this.trackingUnit,
      goalType: goalType ?? this.goalType,
      plannedDurationDays: plannedDurationDays ?? this.plannedDurationDays,
      dailyTargetUnits: dailyTargetUnits ?? this.dailyTargetUnits,
      completedUnits: completedUnits ?? this.completedUnits,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isCompleted: isCompleted ?? this.isCompleted,
      nextSurahNumber: nextSurahNumber ?? this.nextSurahNumber,
      nextAyahNumber: nextAyahNumber ?? this.nextAyahNumber,
      nextPageNumber: nextPageNumber ?? this.nextPageNumber,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      completedWirds: completedWirds ?? this.completedWirds,
    );
  }

  int get totalUnits => trackingUnit.totalUnits;

  int get startUnitIndex {
    final int clampedJuz = startJuz.clamp(1, 30);
    switch (trackingUnit) {
      case KhatmaTrackingUnit.page:
        return math.min(604, ((clampedJuz - 1) * 20) + 1);
      case KhatmaTrackingUnit.hizb:
        return math.min(60, ((clampedJuz - 1) * 2) + 1);
      case KhatmaTrackingUnit.juz:
        return clampedJuz;
    }
  }

  int get plannedUnits =>
      (totalUnits - startUnitIndex + 1).clamp(1, totalUnits);

  double get remainingUnits => math.max(0, plannedUnits - completedUnits);

  double get progress {
    if (plannedUnits <= 0) return 0;
    return (completedUnits / plannedUnits).clamp(0, 1);
  }

  int get durationDays {
    if (goalType == KhatmaGoalType.byDuration) {
      return plannedDurationDays;
    }
    return math.max(1, (plannedUnits / dailyTargetUnits).ceil());
  }

  int get completedDays => dailyLogs.length;

  int get currentUnitIndex {
    return (startUnitIndex + completedUnits.floor()).clamp(
      startUnitIndex,
      totalUnits,
    );
  }

  int get currentJuz {
    switch (trackingUnit) {
      case KhatmaTrackingUnit.juz:
        return currentUnitIndex;
      case KhatmaTrackingUnit.hizb:
        return ((currentUnitIndex - 1) ~/ 2) + 1;
      case KhatmaTrackingUnit.page:
        return ((currentUnitIndex - 1) ~/ 20) + 1;
    }
  }

  String get amountType => trackingUnit.arabicLabel;

  String get amountValue =>
      '${_formatUnit(dailyTargetUnits)} ${trackingUnit.arabicLabel}';

  double get recommendedDailyTarget {
    if (isCompleted) return 0;
    if (goalType == KhatmaGoalType.byDailyAmount) {
      return dailyTargetUnits;
    }

    final DateTime now = DateTime.now();
    final int daysPassed =
        DateTime(now.year, now.month, now.day)
            .difference(
              DateTime(startDate.year, startDate.month, startDate.day),
            )
            .inDays +
        1;

    final int daysLeft = math.max(1, plannedDurationDays - (daysPassed - 1));
    return remainingUnits / daysLeft;
  }

  double get expectedCompletedUnitsToday {
    final DateTime now = DateTime.now();
    final int daysPassed =
        DateTime(now.year, now.month, now.day)
            .difference(
              DateTime(startDate.year, startDate.month, startDate.day),
            )
            .inDays +
        1;
    final int elapsed = daysPassed.clamp(0, durationDays);
    return math.min(plannedUnits.toDouble(), elapsed * dailyTargetUnits);
  }

  bool get isBehindSchedule =>
      completedUnits + 0.001 < expectedCompletedUnitsToday;

  int get todayFromUnit => currentUnitIndex;

  int get todayToUnit {
    if (remainingUnits <= 0) return currentUnitIndex;
    final int target = recommendedDailyTarget.ceil();
    return (currentUnitIndex + target - 1).clamp(currentUnitIndex, totalUnits);
  }

  KhatmaReportSummary summaryForDays(int days) {
    final DateTime now = DateTime.now();
    final DateTime startWindow = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    double readInWindow = 0;
    for (final log in dailyLogs) {
      final DateTime dateOnly = DateTime(
        log.date.year,
        log.date.month,
        log.date.day,
      );
      if (!dateOnly.isBefore(startWindow)) {
        readInWindow += log.unitsRead;
      }
    }

    return KhatmaReportSummary(
      readUnits: readInWindow,
      remainingUnits: remainingUnits,
      progress: progress,
    );
  }

  KhatmaCompletedWird? get lastCompletedWird {
    if (completedWirds.isEmpty) return null;
    return completedWirds.last;
  }

  static DateTime parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String dateToJson(DateTime value) => value.toIso8601String();

  static int parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static bool parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final String normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return false;
  }

  static Map<String, dynamic> _normalizeLegacyJson(Map<String, dynamic> json) {
    Object? readValue(String snake, String camel) => json[snake] ?? json[camel];

    final KhatmaTrackingUnit unit = KhatmaTrackingUnitX.fromStorage(
      readValue('tracking_unit', 'trackingUnit')?.toString() ??
          json['amountType']?.toString(),
    );
    final KhatmaGoalType goalType = KhatmaGoalTypeX.fromStorage(
      readValue('goal_type', 'goalType')?.toString(),
    );

    final double legacyCompletedUnits =
        (readValue('completed_units', 'completedUnits') as num?)?.toDouble() ??
        ((json['currentJuz'] as num?)?.toDouble() ?? 1) -
            ((readValue('start_juz', 'startJuz') as num?) ?? 1);

    final double parsedLegacyDailyTarget = _parseLegacyDailyTarget(
      unit: unit,
      amountType: json['amountType']?.toString(),
      amountValue: json['amountValue']?.toString(),
    );

    return <String, dynamic>{
      'id':
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'start_mode':
          readValue('start_mode', 'startMode')?.toString() ??
          appL10n.appRouterMessage4,
      'start_juz': (readValue('start_juz', 'startJuz') as num?)?.toInt() ?? 1,
      'start_date': parseDateTime(
        readValue('start_date', 'startDate'),
      ).toIso8601String(),
      'tracking_unit': unit.name,
      'goal_type': goalType.name,
      'planned_duration_days':
          (readValue('planned_duration_days', 'plannedDurationDays') as num?)
              ?.toInt() ??
          (json['durationDays'] as num?)?.toInt() ??
          30,
      'daily_target_units':
          (readValue('daily_target_units', 'dailyTargetUnits') as num?)
              ?.toDouble() ??
          parsedLegacyDailyTarget,
      'completed_units': math.max(0, legacyCompletedUnits),
      'reminder_hour':
          (readValue('reminder_hour', 'reminderHour') as num?)?.toInt() ?? 8,
      'reminder_minute':
          (readValue('reminder_minute', 'reminderMinute') as num?)?.toInt() ??
          0,
      'is_completed': parseBool(readValue('is_completed', 'isCompleted')),
      'next_surah_number':
          (readValue('next_surah_number', 'nextSurahNumber') as num?)?.toInt(),
      'next_ayah_number':
          (readValue('next_ayah_number', 'nextAyahNumber') as num?)?.toInt(),
      'next_page_number':
          (readValue('next_page_number', 'nextPageNumber') as num?)?.toInt(),
      'daily_logs': _safeJsonList(readValue('daily_logs', 'dailyLogs')),
      'completed_wirds': _safeJsonList(
        readValue('completed_wirds', 'completedWirds'),
      ),
    };
  }

  static List<Map<String, dynamic>> _safeJsonList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static String _formatUnit(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  static double _parseLegacyDailyTarget({
    required KhatmaTrackingUnit unit,
    required String? amountType,
    required String? amountValue,
  }) {
    final String raw = (amountValue ?? '').trim();
    final String normalized = raw
        .replaceAll('جزءان', '2')
        .replaceAll('جزء', '1')
        .replaceAll('ربعان', '2')
        .replaceAll('ربع', '1')
        .replaceAll('أجزاء', '')
        .replaceAll('أرباع', '')
        .trim();

    final double parsed = double.tryParse(normalized.split(' ').first) ?? 1;
    if (amountType == 'ربع') {
      // Legacy quarter-juz option is converted to hizb-like
      // tracking as half hizb per quarter.
      if (unit == KhatmaTrackingUnit.hizb) {
        return math.max(0.5, parsed / 2);
      }
      if (unit == KhatmaTrackingUnit.page) {
        return math.max(1, parsed * 5);
      }
      return math.max(0.25, parsed / 4);
    }
    return math.max(1, parsed);
  }
}
