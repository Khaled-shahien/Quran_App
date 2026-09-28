import '../../domain/prayer_time_zone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/prayers/domain/Entities/'
    'prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/repositories/'
    'prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/domain/services/'
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
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Future<Coordinates> getCurrentCoordinates() async {
    return (latitude: latitude, longitude: longitude);
  }
}

class UnconfiguredPrayerLocationService implements PrayerLocationService {
  const UnconfiguredPrayerLocationService();
  @override
  Future<Coordinates> getCurrentCoordinates() async =>
      throw StateError('Select a prayer location first');
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

  final SharedPreferences? _preferences;
  Coordinates? _selectedCoordinates;
  String locationLabel = 'لم يتم تحديد الموقع';
  int selectedMethod = PrayerCalculationPolicy.defaultMethod;
  DateTime? loadedDate;
  Coordinates? get selectedCoordinates => _selectedCoordinates;
  DateTime get locationNow =>
      prayerWallTime(_clock.now(), _prayerTimes?.timezone);
  PrayerTimesEntity? _prayerTimes;
  int _requestId = 0;
  bool _disposed = false;
  bool _isLoading = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    super.dispose();
  }

  String? _errorMessage;

  PrayerTimesProvider({
    required PrayerTimesRepository repository,
    SharedPreferences? preferences,
    PrayerTimesClock? clock,
    PrayerLocationService? locationService,
    PrayerNotificationScheduler? notificationScheduler,
  }) : _preferences = preferences,
       _repository = repository,
       _clock = clock ?? SystemPrayerTimesClock(),
       _locationService =
           locationService ?? const UnconfiguredPrayerLocationService(),
       _notificationScheduler =
           notificationScheduler ?? const NoopPrayerNotificationScheduler() {
    final lat = preferences?.getDouble('prayer_latitude');
    final lon = preferences?.getDouble('prayer_longitude');
    if (lat != null &&
        lon != null &&
        lat.isFinite &&
        lon.isFinite &&
        lat.abs() <= 90 &&
        lon.abs() <= 180) {
      _selectedCoordinates = (latitude: lat, longitude: lon);
      locationLabel =
          preferences?.getString('prayer_location_label') ?? 'موقع محفوظ';
    }
    final method = preferences?.getInt('prayer_method');
    if (PrayerCalculationPolicy.methods.containsKey(method)) {
      selectedMethod = method!;
    }
  }

  Future<void> selectLocation(
    double latitude,
    double longitude,
    String label,
    int method,
  ) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        !PrayerCalculationPolicy.methods.containsKey(method)) {
      throw ArgumentError('Invalid prayer configuration');
    }
    _requestId++;
    _prayerTimes = null;
    await _notificationScheduler.cancelPrayerNotifications();
    _selectedCoordinates = (latitude: latitude, longitude: longitude);
    locationLabel = label.trim().isEmpty ? 'موقع يدوي' : label.trim();
    selectedMethod = method;
    await _preferences?.setDouble('prayer_latitude', latitude);
    await _preferences?.setDouble('prayer_longitude', longitude);
    await _preferences?.setString('prayer_location_label', locationLabel);
    await _preferences?.setInt('prayer_method', method);
    await fetchTodayForCurrentLocation(calculationMethod: method);
  }

  Future<void> useDeviceLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('disabled');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('denied');
      }
      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 20),
      );
      await selectLocation(
        position.latitude,
        position.longitude,
        'موقع الجهاز',
        selectedMethod,
      );
    } catch (_) {
      _errorMessage =
          'تعذر تحميل المواقيت. حدد موقعك أو تحقق من الاتصال وأعد المحاولة.';
      notifyListeners();
    }
  }

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
  ///   (default Egyptian General Authority of Survey)
  Future<void> fetchPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
  }) async {
    final requestId = ++_requestId;
    _selectedCoordinates = (latitude: latitude, longitude: longitude);
    selectedMethod = calculationMethod;
    _prayerTimes = null;
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

      if (_disposed || requestId != _requestId) return;
      prayerLocation(prayerTimes.timezone);
      loadedDate = date;
      _prayerTimes = prayerTimes;
      loadedPrayerTimes = prayerTimes;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_disposed || requestId != _requestId) return;
      _isLoading = false;
      _errorMessage =
          'تعذر تحميل المواقيت. حدد موقعك أو تحقق من الاتصال وأعد المحاولة.';
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
  Future<void> fetchTodayForCurrentLocation({
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
  }) async {
    try {
      final coordinates =
          _selectedCoordinates ??
          await _locationService.getCurrentCoordinates();
      await fetchPrayerTimes(
        locationNow,
        coordinates.latitude,
        coordinates.longitude,
        calculationMethod: _selectedCoordinates == null
            ? calculationMethod
            : selectedMethod,
      );
      final localToday = locationNow;
      final date = loadedDate;
      if (date != null &&
          (date.year != localToday.year ||
              date.month != localToday.month ||
              date.day != localToday.day)) {
        await fetchPrayerTimes(
          localToday,
          coordinates.latitude,
          coordinates.longitude,
          calculationMethod: selectedMethod,
        );
      }
    } catch (_) {
      _errorMessage =
          'تعذر تحميل المواقيت. حدد موقعك أو تحقق من الاتصال وأعد المحاولة.';
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchTodayForCurrentLocation();

  void updateClock() {
    if (_prayerTimes == null || _isLoading) return;
    final now = locationNow;
    final date = loadedDate;
    if (date != null &&
        (date.year != now.year ||
            date.month != now.month ||
            date.day != now.day)) {
      refresh();
    } else {
      notifyListeners();
    }
  }

  /// Clear current data
  void clearData() {
    _requestId++;
    _isLoading = false;
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

  Map<String, String> getCurrentAndNextPrayer() {
    const names = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };
    final raw = _prayerTimes?.getMainPrayerTimes() ?? {};
    final formatted = getMainPrayerTimes();
    final now = locationNow;
    final result = <String, String>{
      'currentName': locationLabel,
      'currentTime': '--:--',
      'nextName': 'حدد الموقع',
      'nextTime': '--:--',
    };
    for (final entry in names.entries) {
      final match = RegExp(
        r'^(\d{1,2}):(\d{2})',
      ).firstMatch(raw[entry.key] ?? '');
      if (match == null) continue;
      final time = prayerInstant(
        now,
        int.parse(match[1]!),
        int.parse(match[2]!),
        _prayerTimes?.timezone,
      );
      if (time.isAfter(now)) {
        result['nextName'] = entry.value;
        result['nextTime'] = formatted[entry.key]!;
        return result;
      }
      result['currentName'] = entry.value;
      result['currentTime'] = formatted[entry.key]!;
      result['nextName'] = 'الفجر غداً';
    }
    return result;
  }
}
