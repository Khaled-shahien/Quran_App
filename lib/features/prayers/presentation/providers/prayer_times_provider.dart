import 'package:flutter/foundation.dart';
import 'package:quran_app/features/prayers/domain/Entities/'
    'prayer_times_entity.dart';
import 'package:quran_app/features/prayers/domain/repositories/'
    'prayer_times_repository.dart';
import 'package:quran_app/features/prayers/domain/services/'
    'prayer_notification_scheduler.dart';

typedef Coordinates = ({double latitude, double longitude});

abstract class PrayerTimesClock {
  DateTime now();
}

class SystemPrayerTimesClock implements PrayerTimesClock {
  @override
  DateTime now() => DateTime.now();
}

abstract class PrayerLocationService {
  Future<Coordinates> getCurrentCoordinates();
}

class FixedPrayerLocationService implements PrayerLocationService {
  const FixedPrayerLocationService({
    this.latitude = 30.0444,
    this.longitude = 31.2357,
  });

  final double latitude;
  final double longitude;

  @override
  Future<Coordinates> getCurrentCoordinates() async {
    return (latitude: latitude, longitude: longitude);
  }
}

/// Prayer Times Provider
///
/// State management provider for Prayer Times functionality.
/// Manages loading states, error handling, and data fetching.
class PrayerTimesProvider extends ChangeNotifier {
  final PrayerTimesRepository _repository;
  final PrayerTimesClock _clock;
  final PrayerLocationService _locationService;
  final PrayerNotificationScheduler _notificationScheduler;

  PrayerTimesEntity? _prayerTimes;
  bool _isLoading = false;
  String? _errorMessage;

  PrayerTimesProvider({
    required PrayerTimesRepository repository,
    PrayerTimesClock? clock,
    PrayerLocationService? locationService,
    PrayerNotificationScheduler? notificationScheduler,
  }) : _repository = repository,
       _clock = clock ?? SystemPrayerTimesClock(),
       _locationService = locationService ?? const FixedPrayerLocationService(),
       _notificationScheduler =
           notificationScheduler ?? const NoopPrayerNotificationScheduler();

  /// Get current prayer times
  PrayerTimesEntity? get prayerTimes => _prayerTimes;

  /// Get loading state
  bool get isLoading => _isLoading;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Check if data is loaded
  bool get hasData => _prayerTimes != null;

  /// Check if there's an error
  bool get hasError => _errorMessage != null;

  /// Fetch prayer times for given date and location
  ///
  /// Parameters:
  /// - date: Date to fetch prayer times for
  /// - latitude: User's latitude
  /// - longitude: User's longitude
  /// - calculationMethod: Calculation method
  ///   (default 3 for Muslim World League)
  Future<void> fetchPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 5,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    PrayerTimesEntity? loadedPrayerTimes;

    try {
      final prayerTimes = await _repository.getPrayerTimes(
        date,
        latitude,
        longitude,
        calculationMethod: calculationMethod,
      );

      _prayerTimes = prayerTimes;
      loadedPrayerTimes = prayerTimes;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
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

  /// Fetch prayer times for today using current location service.
  Future<void> fetchTodayForCurrentLocation({int calculationMethod = 5}) async {
    final coordinates = await _locationService.getCurrentCoordinates();
    await fetchPrayerTimes(
      _clock.now(),
      coordinates.latitude,
      coordinates.longitude,
      calculationMethod: calculationMethod,
    );
  }

  /// Refresh prayer times with current parameters
  Future<void> refresh() async {
    if (_prayerTimes != null) {
      // For simplicity, we'll refetch today's prayer times
      // In a real app, you'd want to store the last parameters used
      await fetchPrayerTimes(
        _clock.now(),
        _prayerTimes!.latitude ?? 0.0,
        _prayerTimes!.longitude ?? 0.0,
        calculationMethod: _prayerTimes!.calculationMethod ?? 5,
      );
    }
  }

  /// Clear current data
  void clearData() {
    _prayerTimes = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Get formatted prayer times for display
  Map<String, String> getFormattedPrayerTimes() {
    if (_prayerTimes != null) {
      return _prayerTimes!.getFormattedPrayerTimes();
    }
    return {};
  }

  /// Get main prayer times (excluding optional ones)
  Map<String, String> getMainPrayerTimes() {
    if (_prayerTimes != null) {
      final formattedTimes = _prayerTimes!.getFormattedPrayerTimes();
      return {
        'Fajr': formattedTimes['Fajr'] ?? 'N/A',
        'Sunrise': formattedTimes['Sunrise'] ?? 'N/A',
        'Dhuhr': formattedTimes['Dhuhr'] ?? 'N/A',
        'Asr': formattedTimes['Asr'] ?? 'N/A',
        'Maghrib': formattedTimes['Maghrib'] ?? 'N/A',
        'Isha': formattedTimes['Isha'] ?? 'N/A',
      };
    }
    return {};
  }
}
