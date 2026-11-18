import 'dart:async';
import 'package:sakina_app/features/prayers/domain/prayer_time_adjustments.dart';
import 'package:sakina_app/l10n/localization.dart';
import '../../domain/entities/adhan_settings.dart';
import '../../domain/prayer_time_zone.dart';
import '../prayer_labels.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/services/location_access_service.dart';
import 'package:sakina_app/core/services/location_fix.dart';
import 'package:sakina_app/features/prayers/data/prayer_city_catalog.dart';
import 'package:sakina_app/features/prayers/domain/prayer_city.dart';
import 'package:sakina_app/features/prayers/domain/prayer_location_source.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:sakina_app/features/prayers/domain/entities/'
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
  const PrayerLocationException(this.message, {this.access});
  final String message;

  /// The access problem behind it, when there was one; screens use it to
  /// offer the right settings page.
  final LocationAccessStatus? access;

  /// Whether only a settings page can fix it (permission refused for good,
  /// or location services switched off).
  bool get needsSettings =>
      access == LocationAccessStatus.permanentlyDenied ||
      access == LocationAccessStatus.servicesDisabled;
}

/// A device location service that reports how good its fix is.
abstract class DeviceFixLocationService implements PrayerLocationService {
  /// With [requestAccess] false no system dialog is ever shown: the lookup
  /// fails unless access is already granted.
  Future<DeviceLocationFix> currentFix({bool requestAccess = true});
}

class DevicePrayerLocationService implements DeviceFixLocationService {
  DevicePrayerLocationService({LocationAccessService? access})
    : _access = access ?? LocationAccessService();

  final LocationAccessService _access;

  @override
  Future<Coordinates> getCurrentCoordinates() async {
    final fix = await currentFix();
    return (latitude: fix.latitude, longitude: fix.longitude);
  }

  @override
  Future<DeviceLocationFix> currentFix({bool requestAccess = true}) async {
    try {
      return await _access.currentFix(requestAccess: requestAccess);
    } on LocationAccessException catch (error) {
      throw PrayerLocationException(switch (error.status) {
        LocationAccessStatus.servicesDisabled =>
          appL10n.prayerTimesProviderMessage1,
        LocationAccessStatus.permanentlyDenied =>
          appL10n.prayerTimesProviderMessage2,
        LocationAccessStatus.unsupported => appL10n.prayerTimesProviderMessage9,
        _ => appL10n.prayerTimesProviderMessage3,
      }, access: error.status);
    } on LocationFixException catch (error) {
      throw PrayerLocationException(
        error.problem == LocationFixProblem.tooInaccurate
            ? appL10n.locationTooInaccurateMessage
            : appL10n.prayerTimesProviderMessage9,
      );
    }
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

/// No prayer location has been chosen yet. This is a normal first-run state,
/// not an error.
class PrayerLocationNotConfiguredException implements Exception {
  const PrayerLocationNotConfiguredException();
}

class UnconfiguredPrayerLocationService implements PrayerLocationService {
  const UnconfiguredPrayerLocationService();
  @override
  Future<Coordinates> getCurrentCoordinates() async =>
      throw const PrayerLocationNotConfiguredException();
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
  final Future<CityMatch?> Function(double latitude, double longitude)
  _nearestCity;

  final SharedPreferences? _preferences;
  Coordinates? _selectedCoordinates;
  String locationLabel = appL10n.prayerTimesProviderMessage4;
  int selectedMethod = PrayerCalculationPolicy.defaultMethod;
  AsrMadhab asrMadhab = AsrMadhab.standard;

  /// The user's per-time minute shifts (see [setAdjustments]).
  PrayerTimeAdjustments adjustments = PrayerTimeAdjustments.none;

  /// Which kind of location is active; see [PrayerLocationSource].
  PrayerLocationSource locationSource = PrayerLocationSource.manual;

  /// For a device location: when its fix was measured and how precise the
  /// platform said it was (metres, null when unknown).
  DateTime? locationFixedAt;
  double? locationAccuracyMeters;

  /// The last device lookup could not get a new fix and used the phone's
  /// last known position instead. Screens say so; it is never persisted.
  bool lastFixWasStale = false;

  /// Why the last device lookup failed, while earlier prayer times stay on
  /// screen. Cleared by the next successful lookup or selection.
  PrayerLocationException? lastLocationError;

  /// IANA zone of the chosen place; null means "use the device zone"
  /// (device location or manually typed coordinates).
  String? selectedTimeZone;
  DateTime? loadedDate;
  Coordinates? get selectedCoordinates => _selectedCoordinates;
  DateTime get locationNow =>
      prayerWallTime(_clock.now(), _prayerTimes?.timezone ?? selectedTimeZone);
  PrayerTimesEntity? _prayerTimes;

  /// Tomorrow's times, so the next prayer after Isha (Fajr) is known.
  PrayerTimesEntity? _tomorrowPrayerTimes;
  int _requestId = 0;
  bool _disposed = false;
  bool _isLoading = false;
  bool _needsLocation = false;

  /// True until the user picks a location; screens show a friendly prompt
  /// instead of an error.
  bool get needsLocation => _needsLocation && _selectedCoordinates == null;

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
    Future<CityMatch?> Function(double latitude, double longitude)? nearestCity,
  }) : _preferences = preferences,
       _repository = repository,
       _clock = clock ?? SystemPrayerTimesClock(),
       _locationService =
           locationService ?? const UnconfiguredPrayerLocationService(),
       _deviceLocationService =
           deviceLocationService ??
           DevicePrayerLocationService(
             access: LocationAccessService(prefs: preferences),
           ),
       _notificationScheduler =
           notificationScheduler ?? const NoopPrayerNotificationScheduler(),
       _nearestCity = nearestCity ?? PrayerCityCatalog.bundled.nearest {
    // This runs while the root widget builds, so wrongly typed stored values
    // must read as "not configured" rather than throw.
    final lat = preferences?.get('prayer_latitude');
    final lon = preferences?.get('prayer_longitude');
    if (lat is double &&
        lon is double &&
        lat.isFinite &&
        lon.isFinite &&
        lat.abs() <= 90 &&
        lon.abs() <= 180) {
      _selectedCoordinates = (latitude: lat, longitude: lon);
      final label = preferences?.get('prayer_location_label');
      locationLabel = label is String
          ? label
          : appL10n.prayerTimesProviderMessage5;
      locationSource = PrayerLocationSource.fromStorage(
        preferences?.get(PrayerLocationSource.preferenceKey),
        legacyDeviceLabel: label == appL10n.prayerTimesProviderMessage8,
      );
      final fixedAt = preferences?.get(PrayerLocationSource.fixedAtKey);
      if (locationSource == PrayerLocationSource.device && fixedAt is int) {
        locationFixedAt = DateTime.fromMillisecondsSinceEpoch(fixedAt);
      }
      final accuracy = preferences?.get(PrayerLocationSource.accuracyKey);
      if (locationSource == PrayerLocationSource.device &&
          accuracy is double &&
          accuracy.isFinite &&
          accuracy > 0) {
        locationAccuracyMeters = accuracy;
      }
    }
    final method = preferences?.get('prayer_method');
    if (method is int && PrayerCalculationPolicy.methods.containsKey(method)) {
      selectedMethod = method;
    }
    final zone = preferences?.get(timeZonePreferenceKey);
    selectedTimeZone = zone is String && zone.isNotEmpty ? zone : null;
    asrMadhab = AsrMadhab.fromStorage(
      preferences?.get(AsrMadhab.preferenceKey),
    );
    if (preferences != null) {
      adjustments = PrayerTimeAdjustments.read(preferences);
    }
  }

  static const String timeZonePreferenceKey = prayerTimeZonePreferenceKey;

  /// Changes how Asr is calculated, then recalculates and reschedules.
  Future<void> setAsrMadhab(AsrMadhab madhab) async {
    if (_disposed || madhab == asrMadhab) return;
    asrMadhab = madhab;
    await _preferences?.setString(AsrMadhab.preferenceKey, madhab.name);
    notifyListeners();
    if (_selectedCoordinates != null) await refresh();
  }

  /// Shifts calculated times by whole minutes, then recalculates and
  /// reschedules.
  Future<void> setAdjustments(PrayerTimeAdjustments next) async {
    if (_disposed || next == adjustments) return;
    adjustments = next;
    final SharedPreferences? prefs = _preferences;
    if (prefs != null) await next.write(prefs);
    notifyListeners();
    if (_selectedCoordinates != null) await refresh();
  }

  /// Country (ISO code) of the active place, from the nearest listed city
  /// within [NearestCity.nearCityMeters]; null elsewhere or until known.
  String? locationCountryCode;

  /// Arabic name of the country of [locationCountryCode].
  String? locationCountryName;

  static const String methodSuggestionDismissedKey =
      'prayer_method_suggestion_dismissed';

  /// The method usually used in [locationCountryCode], when it differs
  /// from the selected one and the user has not declined it for that
  /// country. Only a suggestion: nothing changes until they accept.
  int? get suggestedMethod {
    final String? country = locationCountryCode;
    final int? recommended = PrayerCalculationPolicy.recommendedFor(country);
    if (country == null ||
        recommended == null ||
        recommended == selectedMethod ||
        _selectedCoordinates == null) {
      return null;
    }
    final Object? dismissed = _preferences?.get(methodSuggestionDismissedKey);
    return dismissed == '$country:$recommended' ? null : recommended;
  }

  Future<void> acceptMethodSuggestion() async {
    final int? method = suggestedMethod;
    if (method != null) await setCalculationMethod(method);
  }

  Future<void> dismissMethodSuggestion() async {
    final int? method = suggestedMethod;
    if (method == null) return;
    await _preferences?.setString(
      methodSuggestionDismissedKey,
      '$locationCountryCode:$method',
    );
    notifyListeners();
  }

  /// Looks up the country of the active place offline (also started
  /// after each successful fetch).
  Future<void> updateLocationCountry() async {
    final coordinates = _selectedCoordinates;
    if (coordinates == null) return;
    CityMatch? match;
    try {
      match = await _nearestCity(coordinates.latitude, coordinates.longitude);
    } catch (_) {
      match = null;
    }
    if (_disposed || _selectedCoordinates != coordinates) return;
    final String? code = match?.city.countryCode;
    if (code == locationCountryCode) return;
    locationCountryCode = code;
    locationCountryName = match?.city.country;
    notifyListeners();
  }

  /// Changes the calculation method for the current place, then
  /// recalculates and reschedules.
  Future<void> setCalculationMethod(int method) async {
    if (_disposed ||
        method == selectedMethod ||
        !PrayerCalculationPolicy.methods.containsKey(method)) {
      return;
    }
    selectedMethod = method;
    await _preferences?.setInt('prayer_method', method);
    notifyListeners();
    if (_selectedCoordinates != null) await refresh();
  }

  /// Makes this the active prayer location, then recalculates and
  /// reschedules through the single scheduling boundary (cancel, save,
  /// schedule). [source] records whether it is the device's position or a
  /// place chosen by hand; [fix] describes a device position.
  Future<void> selectLocation(
    double latitude,
    double longitude,
    String label,
    int method, {
    String? timeZone,
    PrayerLocationSource source = PrayerLocationSource.manual,
    DeviceLocationFix? fix,
  }) async {
    if (!isValidCoordinate(latitude, longitude) ||
        !PrayerCalculationPolicy.methods.containsKey(method)) {
      throw ArgumentError('Invalid prayer configuration');
    }
    if (_disposed) return;
    _selectionsInFlight++;
    try {
      await _applyLocation(
        latitude,
        longitude,
        label,
        method,
        timeZone: timeZone,
        source: source,
        fix: fix,
      );
    } finally {
      _selectionsInFlight--;
    }
  }

  /// Selections not yet saved; an automatic refresh never races them.
  int _selectionsInFlight = 0;

  Future<void> _applyLocation(
    double latitude,
    double longitude,
    String label,
    int method, {
    required String? timeZone,
    required PrayerLocationSource source,
    required DeviceLocationFix? fix,
  }) async {
    final requestId = ++_requestId;
    final nextLabel = label.trim().isEmpty
        ? appL10n.prayerTimesProviderMessage6
        : label.trim();
    final DateTime? fixedAt = source == PrayerLocationSource.device
        ? (fix?.timestamp ?? _clock.now())
        : null;
    final double? accuracy = source == PrayerLocationSource.device
        ? fix?.accuracyMeters
        : null;
    final previousValues = <String, Object?>{};
    _isLoading = true;
    _errorMessage = null;
    lastLocationError = null;
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
          timeZonePreferenceKey,
          PrayerLocationSource.preferenceKey,
          PrayerLocationSource.fixedAtKey,
          PrayerLocationSource.accuracyKey,
        ]) {
          previousValues[key] = preferences.get(key);
        }
        final writes = <Future<bool> Function()>[
          () => preferences.setDouble('prayer_latitude', latitude),
          () => preferences.setDouble('prayer_longitude', longitude),
          () => preferences.setString('prayer_location_label', nextLabel),
          () => preferences.setInt('prayer_method', method),
          () => timeZone == null
              ? preferences.remove(timeZonePreferenceKey)
              : preferences.setString(timeZonePreferenceKey, timeZone),
          () => preferences.setString(
            PrayerLocationSource.preferenceKey,
            source.name,
          ),
          () => fixedAt == null
              ? preferences.remove(PrayerLocationSource.fixedAtKey)
              : preferences.setInt(
                  PrayerLocationSource.fixedAtKey,
                  fixedAt.millisecondsSinceEpoch,
                ),
          () => accuracy == null
              ? preferences.remove(PrayerLocationSource.accuracyKey)
              : preferences.setDouble(
                  PrayerLocationSource.accuracyKey,
                  accuracy,
                ),
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
    selectedTimeZone = timeZone;
    locationSource = source;
    locationFixedAt = fixedAt;
    locationAccuracyMeters = accuracy;
    locationCountryCode = null;
    locationCountryName = null;
    await fetchTodayForCurrentLocation(calculationMethod: method);
  }

  /// Name for a device position from the bundled city list (offline):
  /// "Cairo, Egypt" inside a listed city, "near Cairo" close to one, and a
  /// neutral "device location" elsewhere, so a neighbouring city is never
  /// named as the user's own.
  Future<String> _deviceLabel(DeviceLocationFix fix) async {
    CityMatch? match;
    try {
      match = await _nearestCity(fix.latitude, fix.longitude);
    } catch (_) {
      match = null;
    }
    if (match == null) return appL10n.prayerTimesProviderMessage8;
    return match.proximity == CityProximity.inCity
        ? appL10n.prayerLocationDialogMessage2(
            match.city.name,
            match.city.country,
          )
        : appL10n.nearCityLabel(match.city.name);
  }

  Future<DeviceLocationFix> _deviceFix({required bool requestAccess}) async {
    final service = _deviceLocationService;
    if (service is DeviceFixLocationService) {
      return service.currentFix(requestAccess: requestAccess);
    }
    // Plain services (tests, fixed locations) report coordinates only.
    final coordinates = await service.getCurrentCoordinates();
    return DeviceLocationFix(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      timestamp: _clock.now(),
      source: LocationFixSource.fresh,
    );
  }

  /// The location permission dialog pauses and resumes the app. Resume
  /// refreshes check this so they do not supersede the lookup that the dialog
  /// belongs to, which would make the first tap after granting access fail.
  Future<void>? _deviceLocationRequest;

  Future<void> useDeviceLocation() => _deviceLocationRequest ??=
      _useDeviceLocation().whenComplete(() => _deviceLocationRequest = null);

  Future<void> _useDeviceLocation() async {
    if (_disposed) return;
    final requestId = ++_requestId;
    _isLoading = true;
    _errorMessage = null;
    lastLocationError = null;
    notifyListeners();
    try {
      final fix = await _deviceFix(requestAccess: true);
      if (_disposed || requestId != _requestId) return;
      if (!isValidCoordinate(fix.latitude, fix.longitude)) {
        throw PrayerLocationException(appL10n.prayerTimesProviderMessage9);
      }
      final label = await _deviceLabel(fix);
      if (_disposed || requestId != _requestId) return;
      lastFixWasStale = fix.isStale;
      await selectLocation(
        fix.latitude,
        fix.longitude,
        label,
        selectedMethod,
        source: PrayerLocationSource.device,
        fix: fix,
      );
    } catch (error) {
      if (_disposed || requestId != _requestId) return;
      final failure = error is PrayerLocationException
          ? error
          : PrayerLocationException(appL10n.prayerTimesProviderMessage9);
      _isLoading = false;
      lastLocationError = failure;
      // A failed lookup must not hide the times of the location already
      // saved, which stays active and unchanged.
      _errorMessage = _prayerTimes == null ? failure.message : null;
      notifyListeners();
    }
  }

  Future<bool>? _automaticRefresh;

  /// For a device location: when its fix is older than
  /// [LocationQuality.deviceLocationRefreshAge], takes a new fix without
  /// any dialog (access must already be granted) and, only if the phone
  /// moved at least [LocationQuality.significantMoveMeters], makes it the
  /// active location, which recalculates and reschedules once.
  ///
  /// Returns true when the location changed. Failures keep the saved
  /// location. A manual location is never touched.
  Future<bool> refreshDeviceLocationIfStale() =>
      _automaticRefresh ??= _refreshDeviceLocationIfStale().whenComplete(
        () => _automaticRefresh = null,
      );

  Future<bool> _refreshDeviceLocationIfStale() async {
    final saved = _selectedCoordinates;
    if (_disposed ||
        saved == null ||
        locationSource != PrayerLocationSource.device ||
        _deviceLocationRequest != null ||
        _selectionsInFlight > 0) {
      return false;
    }
    final fixedAt = locationFixedAt;
    if (fixedAt != null &&
        _clock.now().difference(fixedAt) <
            LocationQuality.deviceLocationRefreshAge) {
      return false;
    }
    final DeviceLocationFix fix;
    try {
      fix = await _deviceFix(requestAccess: false);
    } catch (_) {
      return false;
    }
    // A last-known position is no better than the saved one.
    if (fix.isStale || !isValidCoordinate(fix.latitude, fix.longitude)) {
      return false;
    }
    // The user chose something else meanwhile.
    if (_userChoseMeanwhile(saved)) {
      return false;
    }
    final moved = NearestCity.distanceMeters(
      saved.latitude,
      saved.longitude,
      fix.latitude,
      fix.longitude,
    );
    if (moved < LocationQuality.significantMoveMeters) {
      // Same place: remember the check, without recalculating.
      locationFixedAt = fix.timestamp;
      await _preferences?.setInt(
        PrayerLocationSource.fixedAtKey,
        fix.timestamp.millisecondsSinceEpoch,
      );
      return false;
    }
    final label = await _deviceLabel(fix);
    if (_userChoseMeanwhile(saved)) return false;
    lastFixWasStale = false;
    await selectLocation(
      fix.latitude,
      fix.longitude,
      label,
      selectedMethod,
      // A device location follows the device's own timezone.
      source: PrayerLocationSource.device,
      fix: fix,
    );
    return true;
  }

  /// A selection or device lookup started (or finished) while an automatic
  /// refresh was waiting for its fix; the user's choice wins.
  bool _userChoseMeanwhile(Coordinates saved) =>
      _disposed ||
      _selectionsInFlight > 0 ||
      _deviceLocationRequest != null ||
      locationSource != PrayerLocationSource.device ||
      _selectedCoordinates != saved;

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

    final result = await _repository.getPrayerTimes(
      date,
      latitude,
      longitude,
      calculationMethod: calculationMethod,
      madhab: asrMadhab,
      timeZone: selectedTimeZone,
      adjustments: adjustments,
    );
    if (_disposed || requestId != _requestId) return;
    _tomorrowPrayerTimes = null;
    if (result.isSuccess) {
      final tomorrowResult = await _repository.getPrayerTimes(
        DateTime(date.year, date.month, date.day + 1),
        latitude,
        longitude,
        calculationMethod: calculationMethod,
        madhab: asrMadhab,
        timeZone: selectedTimeZone,
        adjustments: adjustments,
      );
      if (_disposed || requestId != _requestId) return;
      _tomorrowPrayerTimes = tomorrowResult.valueOrNull;
    }
    switch (result) {
      case Success(:final value):
        loadedDate = date;
        _prayerTimes = value;
        loadedPrayerTimes = value;
      case Err(:final failure):
        debugPrint('Prayer time calculation failed: ${failure.cause}');
        _errorMessage = appL10n.prayerTimesProviderMessage10;
    }
    _isLoading = false;
    notifyListeners();

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
      // The country (for the method suggestion) once the place is known.
      // Not awaited: the times are ready without it, and the city list
      // must not hold up the first screen.
      if (locationCountryCode == null) unawaited(updateLocationCountry());
    } on PrayerLocationNotConfiguredException {
      if (_disposed || requestId != _requestId) return;
      _isLoading = false;
      _needsLocation = true;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      if (_disposed || requestId != _requestId) return;
      _isLoading = false;
      _errorMessage = appL10n.prayerTimesProviderMessage10;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchTodayForCurrentLocation();

  /// Resume path: fresh timings for the current day need no network call,
  /// rescheduling or loading state.
  Future<void> refreshIfNeeded() async {
    if (_deviceLocationRequest != null) return;
    final prayerTimes = _prayerTimes;
    if (prayerTimes == null || prayerTimes.isStale) {
      await refresh();
    } else {
      updateClock();
    }
  }

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
    final tomorrowFajr = _tomorrowPrayerTimes
        ?.getFormattedPrayerTimes()['Fajr'];
    if (tomorrowFajr != null && tomorrowFajr != 'N/A') {
      result['nextTime'] = tomorrowFajr;
    }
    return result;
  }

  /// The next of the five prayers from now, including tomorrow's Fajr after
  /// Isha. [wallTime] is in the prayer location's timezone, for display.
  NextPrayer? get nextPrayer {
    final today = _prayerTimes;
    final date = loadedDate;
    if (today == null || date == null) return null;
    final instantNow = _clock.now();
    const keys = <DailyPrayer, String>{
      DailyPrayer.fajr: 'Fajr',
      DailyPrayer.dhuhr: 'Dhuhr',
      DailyPrayer.asr: 'Asr',
      DailyPrayer.maghrib: 'Maghrib',
      DailyPrayer.isha: 'Isha',
    };
    final raw = today.getMainPrayerTimes();
    for (final entry in keys.entries) {
      final at = _instantFor(date, raw[entry.value], today.timezone);
      if (at != null && at.isAfter(instantNow)) {
        return NextPrayer(
          prayer: entry.key,
          name: appL10n.prayerName(entry.key),
          at: at,
          wallTime: prayerWallTime(at, today.timezone),
          isTomorrow: false,
          remaining: at.difference(instantNow),
        );
      }
    }
    final tomorrow = _tomorrowPrayerTimes;
    final next = DateTime(date.year, date.month, date.day + 1);
    final at = _instantFor(next, tomorrow?.fajr, tomorrow?.timezone);
    if (tomorrow == null || at == null) return null;
    return NextPrayer(
      prayer: DailyPrayer.fajr,
      name: appL10n.prayerTimesWidgetMessage13,
      at: at,
      wallTime: prayerWallTime(at, tomorrow.timezone),
      isTomorrow: true,
      remaining: at.difference(instantNow),
    );
  }

  static DateTime? _instantFor(DateTime date, String? hhmm, String? zone) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(hhmm ?? '');
    if (match == null) return null;
    return prayerInstant(
      date,
      int.parse(match[1]!),
      int.parse(match[2]!),
      zone,
    );
  }
}

/// The upcoming prayer, computed in one place for every screen.
class NextPrayer {
  const NextPrayer({
    required this.prayer,
    required this.name,
    required this.at,
    required this.wallTime,
    required this.isTomorrow,
    required this.remaining,
  });

  /// Which prayer; use this, not [name], to look up settings.
  final DailyPrayer prayer;

  /// Display name only, e.g. "الفجر غداً" for tomorrow's Fajr.
  final String name;

  /// The instant the prayer begins.
  final DateTime at;

  /// The same moment as wall-clock time at the prayer location.
  final DateTime wallTime;
  final bool isTomorrow;
  final Duration remaining;
}
