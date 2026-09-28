import '../../domain/prayer_calculation_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/prayers/domain/Entities/'
    'prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/repositories/'
    'prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/'
    'prayer_notification_scheduler.dart';
import 'package:sakina_app/core/utils/value_notifier_mixin.dart';

import 'prayer_times_provider.dart';

/// High-performance Prayer Times Provider
///
/// Uses granular state management and selective notifications
/// to minimize unnecessary widget rebuilds.
class PrayerTimesPerformanceProvider extends ChangeNotifier
    with SelectiveNotifyMixin {
  final PrayerTimesRepository _repository;
  final PrayerTimesClock _clock;
  final PrayerNotificationScheduler _notificationScheduler;

  // Use separate ValueNotifiers for granular updates
  final _prayerTimesNotifier = ValueNotifier<PrayerTimesEntity?>(null);
  final _isLoadingNotifier = PerformanceValueNotifier<bool>(false);
  final _errorMessageNotifier = ValueNotifier<String?>(null);

  PrayerTimesPerformanceProvider({
    required PrayerTimesRepository repository,
    PrayerTimesClock? clock,
    PrayerNotificationScheduler? notificationScheduler,
  }) : _repository = repository,
       _clock = clock ?? SystemPrayerTimesClock(),
       _notificationScheduler =
           notificationScheduler ?? const NoopPrayerNotificationScheduler();

  // Getters with direct notifier access for better performance
  PrayerTimesEntity? get prayerTimes => _prayerTimesNotifier.value;
  bool get isLoading => _isLoadingNotifier.value;
  String? get errorMessage => _errorMessageNotifier.value;
  bool get hasData => _prayerTimesNotifier.value != null;
  bool get hasError => _errorMessageNotifier.value != null;

  /// Fetch prayer times with optimized state updates
  Future<void> fetchPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
  }) async {
    // Set loading state first
    _isLoadingNotifier.value = true;
    notifyForField('isLoading');

    // Clear previous error
    if (_errorMessageNotifier.value != null) {
      _errorMessageNotifier.value = null;
      notifyForField('errorMessage');
    }

    PrayerTimesEntity? loadedPrayerTimes;

    try {
      final prayerTimes = await _repository.getPrayerTimes(
        date,
        latitude,
        longitude,
        calculationMethod: calculationMethod,
      );

      // Update data
      _prayerTimesNotifier.value = prayerTimes;
      loadedPrayerTimes = prayerTimes;
      notifyForField('prayerTimes');
    } catch (e) {
      _errorMessageNotifier.value = e.toString();
      notifyForField('errorMessage');
    } finally {
      // Always update loading state last
      _isLoadingNotifier.value = false;
      notifyForField('isLoading');
    }

    if (loadedPrayerTimes != null) {
      await _schedulePrayerNotifications(loadedPrayerTimes, date);
    }
  }

  Future<void> _schedulePrayerNotifications(
    PrayerTimesEntity prayerTimes,
    DateTime date,
  ) async {
    try {
      await _notificationScheduler.schedulePrayerNotifications(
        prayerTimes: prayerTimes,
        date: date,
      );
    } catch (e) {
      debugPrint('Prayer notification scheduling failed: $e');
    }
  }

  /// Refresh with optimized field updates
  Future<void> refresh() async {
    if (_prayerTimesNotifier.value != null) {
      await fetchPrayerTimes(
        _clock.now(),
        _prayerTimesNotifier.value!.latitude ?? 0.0,
        _prayerTimesNotifier.value!.longitude ?? 0.0,
        calculationMethod:
            _prayerTimesNotifier.value!.calculationMethod ??
            PrayerCalculationPolicy.defaultMethod,
      );
    }
  }

  /// Clear data with selective notifications
  void clearData() {
    _prayerTimesNotifier.value = null;
    _errorMessageNotifier.value = null;

    notifyForFields({'prayerTimes', 'errorMessage'});
  }

  /// Get formatted prayer times
  Map<String, String> getFormattedPrayerTimes() {
    return _prayerTimesNotifier.value?.getFormattedPrayerTimes() ?? {};
  }

  /// Get main prayer times with optimized access
  Map<String, String> getMainPrayerTimes() {
    if (_prayerTimesNotifier.value != null) {
      final times = _prayerTimesNotifier.value!.getMainPrayerTimes();
      return {
        'Fajr': times['Fajr'] ?? 'N/A',
        'Sunrise': times['Sunrise'] ?? 'N/A',
        'Dhuhr': times['Dhuhr'] ?? 'N/A',
        'Asr': times['Asr'] ?? 'N/A',
        'Maghrib': times['Maghrib'] ?? 'N/A',
        'Isha': times['Isha'] ?? 'N/A',
      };
    }
    return {};
  }

  /// Helper to parse time string "HH:MM" into a DateTime for today
  DateTime _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final now = _clock.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return _clock.now(); // fallback
    }
  }

  /// Format 24h time to 12h Arabic format (e.g., 15:30 -> 3:30 م)
  String _formatArabicTime(String time24) {
    if (time24 == 'N/A' || time24 == '--:--') return time24;
    try {
      final parsed = _parseTime(time24);
      int hour = parsed.hour;
      int min = parsed.minute;
      String period = hour >= 12 ? 'م' : 'ص';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      String mStr = min.toString().padLeft(2, '0');
      return '$hour:$mStr $period';
    } catch (e) {
      return time24;
    }
  }

  /// Computes the current and next prayer along with their formatted times.
  Map<String, String> getCurrentAndNextPrayer() {
    final times = getMainPrayerTimes();
    if (times.isEmpty) {
      return {
        'currentName': '---',
        'currentTime': '--:--',
        'nextName': '---',
        'nextTime': '--:--',
      };
    }

    final arabicNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    final now = _clock.now();

    // Sort prayers chronologically
    final prayers = [
      {'key': 'Fajr', 'time': times['Fajr']},
      {'key': 'Sunrise', 'time': times['Sunrise']},
      {'key': 'Dhuhr', 'time': times['Dhuhr']},
      {'key': 'Asr', 'time': times['Asr']},
      {'key': 'Maghrib', 'time': times['Maghrib']},
      {'key': 'Isha', 'time': times['Isha']},
    ];

    String currentName = 'العشاء';
    String currentTime = times['Isha'] ?? '--:--';
    String nextName = 'الفجر';
    String nextTime = times['Fajr'] ?? '--:--';

    for (int i = 0; i < prayers.length; i++) {
      final pt = prayers[i];
      if (pt['time'] == null || pt['time'] == 'N/A') continue;

      final prayerTime = _parseTime(pt['time']!);
      if (now.isBefore(prayerTime)) {
        if (i == 0) {
          // Before Fajr -> Current is Isha of previous day, Next is Fajr
          currentName = 'العشاء';
          currentTime = times['Isha']!;
          nextName = arabicNames[pt['key']]!;
          nextTime = pt['time']!;
        } else {
          final prev = prayers[i - 1];
          currentName = arabicNames[prev['key']] ?? prev['key']!;
          currentTime = prev['time']!;
          nextName = arabicNames[pt['key']] ?? pt['key']!;
          nextTime = pt['time']!;
        }
        break;
      }

      // If we reached the end and now > Isha time
      if (i == prayers.length - 1 && now.isAfter(prayerTime)) {
        currentName = 'العشاء';
        currentTime = times['Isha']!;
        nextName = 'الفجر';
        nextTime = times['Fajr']!;
      }
    }

    return {
      'currentName': currentName,
      'currentTime': _formatArabicTime(currentTime),
      'nextName': nextName,
      'nextTime': _formatArabicTime(nextTime),
    };
  }

  /// Dispose of all notifiers to prevent memory leaks
  @override
  void dispose() {
    _prayerTimesNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorMessageNotifier.dispose();
    super.dispose();
  }
}
