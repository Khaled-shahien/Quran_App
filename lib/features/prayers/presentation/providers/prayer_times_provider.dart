import 'package:sakina_app/l10n/localization.dart';
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

class PrayerLocationException implements Exception {
  const PrayerLocationException(this.message);
  final String message;
}

class DevicePrayerLocationService implements PrayerLocationService {
  const DevicePrayerLocationService();
  @override
  Future<Coordinates> getCurrentCoordinates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw PrayerLocationException(appL10n.prayerTimesProviderMessage1);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw PrayerLocationException(appL10n.prayerTimesProviderMessage2);
    }
    if (permission == LocationPermission.denied) {
      throw PrayerLocationException(appL10n.prayerTimesProviderMessage3);
    }
    final position = await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 20),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  }
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
  final PrayerLocationService _deviceLocationService;
  final PrayerNotificationScheduler _notificationScheduler;

  final SharedPreferences? _preferences;
  Coordinates? _selectedCoordinates;
  String locationLabel = appL10n.prayerTimesProviderMessage4;
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
    PrayerLocationService? deviceLocationService,
    PrayerNotificationScheduler? notificationScheduler,
  }) : _preferences = preferences,
       _repository = repository,
       _clock = clock ?? SystemPrayerTimesClock(),
       _locationService =
           locationService ?? const UnconfiguredPrayerLocationService(),
       _deviceLocationService =
           deviceLocationService ?? const DevicePrayerLocationService(),
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
          preferences?.getString('prayer_location_label') ??
          appL10n.prayerTimesProviderMessage5;
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
    if (_disposed) return;
    final requestId = ++_requestId;
    final nextLabel = label.trim().isEmpty
        ? appL10n.prayerTimesProviderMessage6
        : label.trim();
    final previousValues = <String, Object?>{};
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _notificationScheduler.cancelPrayerNotifications();
      if (_disposed || requestId != _requestId) return;
      final preferences = _preferences;
      if (preferences != null) {
        for (final key in [
          'prayer_latitude',
          'prayer_longitude',
          'prayer_location_label',
          'prayer_method',
        ]) {
          previousValues[key] = preferences.get(key);
        }
        final writes = <Future<bool> Function()>[
          () => preferences.setDouble('prayer_latitude', latitude),
          () => preferences.setDouble('prayer_longitude', longitude),
          () => preferences.setString('prayer_location_label', nextLabel),
          () => preferences.setInt('prayer_method', method),
        ];
        for (final write in writes) {
          final saved = await write();
          if (_disposed || requestId != _requestId) return;
          if (!saved) throw StateError('Prayer configuration was not saved');
        }
      }
    } catch (_) {
      if (_disposed || requestId != _requestId) return;
      // SharedPreferences writes are not transactional. Restore the snapshot
      // where storage permits, without letting recovery errors escape either.
      for (final entry in previousValues.entries) {
        try {
          final value = entry.value;
          if (value is double) {
            await _preferences!.setDouble(entry.key, value);
          } else if (value is int) {
            await _preferences!.setInt(entry.key, value);
          } else if (value is String) {
            await _preferences!.setString(entry.key, value);
          } else {
            await _preferences!.remove(entry.key);
          }
        } catch (_) {
          // The localized retry below remains available during storage failure.
        }
        if (_disposed || requestId != _requestId) return;
      }
      _isLoading = false;
      _errorMessage = appL10n.prayerTimesProviderMessage7;
      notifyListeners();
      return;
    }
    _selectedCoordinates = (latitude: latitude, longitude: longitude);
    locationLabel = nextLabel;
    selectedMethod = method;
    await fetchTodayForCurrentLocation(calculationMethod: method);
  }

  Future<void> useDeviceLocation() async {
    if (_disposed) return;
    final requestId = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final position = await _deviceLocationService.getCurrentCoordinates();
      if (_disposed || requestId != _requestId) return;
      await selectLocation(
        position.latitude,
        position.longitude,
        appL10n.prayerTimesProviderMessage8,
        selectedMethod,
      );
    } catch (error) {
      if (_disposed || requestId != _requestId) return;
      _isLoading = false;
      _errorMessage = error is PrayerLocationException
          ? error.message
          : appL10n.prayerTimesProviderMessage9;
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
    if (_disposed) return;
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
      _errorMessage = appL10n.prayerTimesProviderMessage10;
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
    if (_disposed) return;
    final requestId = ++_requestId;
    try {
      final coordinates =
          _selectedCoordinates ??
          await _locationService.getCurrentCoordinates();
      if (_disposed || requestId != _requestId) return;
      await fetchPrayerTimes(
        locationNow,
        coordinates.latitude,
        coordinates.longitude,
        calculationMethod: _selectedCoordinates == null
            ? calculationMethod
            : selectedMethod,
      );
      // fetchPrayerTimes advances the request once. A further advance means
      // another operation owns the state, including any date correction.
      if (_disposed || _requestId != requestId + 1) return;
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
      if (_disposed || requestId != _requestId) return;
      _isLoading = false;
      _errorMessage = appL10n.prayerTimesProviderMessage10;
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
    final names = {
      'Fajr': appL10n.prayerTimesWidgetMessage8,
      'Dhuhr': appL10n.prayerTimesWidgetMessage9,
      'Asr': appL10n.prayerTimesWidgetMessage10,
      'Maghrib': appL10n.prayerTimesWidgetMessage11,
      'Isha': appL10n.prayerTimesWidgetMessage12,
    };
    final raw = _prayerTimes?.getMainPrayerTimes() ?? {};
    final formatted = getMainPrayerTimes();
    final now = locationNow;
    final result = <String, String>{
      'currentName': locationLabel,
      'currentTime': '--:--',
      'nextName': appL10n.prayerTimesProviderMessage11,
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
      result['nextName'] = appL10n.prayerTimesWidgetMessage13;
    }
    return result;
  }
}
