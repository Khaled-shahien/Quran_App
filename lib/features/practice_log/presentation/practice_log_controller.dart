import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/hijri_calendar_data.dart';
import '../../prayers/domain/entities/adhan_settings.dart';
import '../data/practice_log_repository.dart';

/// Make-up fasts still owed: the days the user said they owed before
/// ([base]), plus Ramadan days logged as not fasted, minus make-up fasts
/// logged. Never below zero.
int qadaRemaining({
  required int base,
  required Map<String, FastLogStatus> fasts,
  required HijriConverter hijri,
}) {
  int owed = base;
  for (final MapEntry(key: day, value: status) in fasts.entries) {
    final date = parseLogDay(day);
    if (date == null) continue;
    switch (status) {
      case FastLogStatus.excused || FastLogStatus.missed:
        if (hijri.of(date)?.month == 9) owed++;
      case FastLogStatus.qada:
        owed--;
      case FastLogStatus.fasted:
        break;
    }
  }
  return owed < 0 ? 0 : owed;
}

/// One week of the log, ending at the selected day.
class PracticeLogController extends ChangeNotifier {
  PracticeLogController(
    this._repository,
    this._prefs, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _day = DateTime(now.year, now.month, now.day);
  }

  static const String excusedKey = 'practice_excused_mode';
  static const String qadaBaseKey = 'fasting_qada_base';

  final PracticeLogRepository _repository;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  bool _disposed = false;

  late DateTime _day;
  bool _loaded = false;
  Map<String, Map<DailyPrayer, PrayerLogStatus>> _prayers = const {};
  Map<String, FastLogStatus> _fasts = const {};
  int _qada = 0;

  bool get loaded => _loaded;
  DateTime get day => _day;

  DateTime get today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  bool get isToday => _day == today;

  /// The seven days ending at [day], oldest first.
  List<DateTime> get week => [
    for (var i = 6; i >= 0; i--) DateTime(_day.year, _day.month, _day.day - i),
  ];

  Map<DailyPrayer, PrayerLogStatus> prayersOn(DateTime date) =>
      _prayers[logDay(date)] ?? const {};

  FastLogStatus? fastOn(DateTime date) => _fasts[logDay(date)];

  bool get excusedMode => _prefs.getBool(excusedKey) ?? false;
  int get qadaBase => _prefs.getInt(qadaBaseKey) ?? 0;
  int get qadaLeft => _qada;

  int _hijriOffset() => _prefs.getInt('hijri_offset_days') ?? 0;

  /// Counts of each status over [week].
  Map<PrayerLogStatus, int> get weekCounts {
    final counts = {for (final s in PrayerLogStatus.values) s: 0};
    for (final d in week) {
      for (final s in prayersOn(d).values) {
        counts[s] = counts[s]! + 1;
      }
    }
    return counts;
  }

  Future<void> load() async {
    final days = week;
    _prayers = await _repository.prayers(days.first, days.last);
    final all = await _repository.allFasts();
    _fasts = all;
    _qada = qadaRemaining(
      base: qadaBase,
      fasts: all,
      hijri: HijriConverter(offsetDays: _hijriOffset()),
    );
    _loaded = true;
    _notify();
  }

  Future<void> showDay(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    if (d.isAfter(today)) return;
    _day = d;
    await load();
  }

  Future<void> previousDay() =>
      showDay(DateTime(_day.year, _day.month, _day.day - 1));

  Future<void> nextDay() =>
      showDay(DateTime(_day.year, _day.month, _day.day + 1));

  Future<void> setPrayer(DailyPrayer prayer, PrayerLogStatus? status) async {
    await _repository.setPrayer(_day, prayer, status);
    await load();
  }

  /// Marks every prayer of the selected day not yet logged as excused.
  Future<void> markDayExcused() async {
    final logged = prayersOn(_day);
    for (final p in DailyPrayer.values) {
      if (!logged.containsKey(p)) {
        await _repository.setPrayer(_day, p, PrayerLogStatus.excused);
      }
    }
    await load();
  }

  Future<void> setFast(FastLogStatus? status) async {
    await _repository.setFast(_day, status);
    await load();
  }

  Future<void> setExcusedMode(bool on) async {
    await _prefs.setBool(excusedKey, on);
    _notify();
  }

  Future<void> changeQadaBase(int delta) async {
    final next = qadaBase + delta;
    if (next < 0 || next > 3650) return;
    await _prefs.setInt(qadaBaseKey, next);
    await load();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
