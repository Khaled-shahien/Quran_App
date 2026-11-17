import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/location_access_service.dart';
import '../../../../core/services/notification_permission_service.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../domain/first_run_state.dart';

enum PermissionIntroStep { notifications, location }

/// Where the location step stands.
enum LocationIntroPhase { idle, locating, located, failed }

/// First-run permission steps shown after the onboarding pages: one for
/// notifications, then one for location. Each explains first and asks the
/// system only when the user taps the enable button; "not now" asks
/// nothing. A step is skipped when it has nothing to ask (already allowed,
/// unsupported, a location already set, or answered before).
///
/// Every status shown comes from the system at that moment, and is read
/// again when the app returns from system settings ([recheck]).
class PermissionOnboardingController extends ChangeNotifier {
  PermissionOnboardingController({
    required SharedPreferences prefs,
    required NotificationPermissionService notifications,
    required LocationAccessService location,
    required PrayerTimesProvider prayer,
  }) : _prefs = prefs,
       _notifications = notifications,
       _location = location,
       _prayer = prayer;

  final SharedPreferences _prefs;
  final NotificationPermissionService _notifications;
  final LocationAccessService _location;
  final PrayerTimesProvider _prayer;

  List<PermissionIntroStep> steps = const [];
  int index = 0;
  bool loaded = false;
  bool finished = false;
  bool busy = false;
  bool _disposed = false;

  NotificationPermissionStatus? notificationStatus;

  /// The user has asked the system on this screen; the result is shown.
  bool notificationAsked = false;

  LocationAccessStatus? locationStatus;
  LocationIntroPhase locationPhase = LocationIntroPhase.idle;

  /// Set when settings were opened from a step, so returning to the app
  /// resumes what the user was trying to do.
  bool _awaitingSettings = false;

  PermissionIntroStep? get step => index < steps.length ? steps[index] : null;

  PrayerTimesProvider get prayer => _prayer;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    final notification = await _notifications.status();
    final location = await _location.status();
    if (_disposed) return;
    notificationStatus = notification;
    locationStatus = location;
    steps = [
      if (_prefs.get(notificationPromptSeenKey) != true &&
          notification != NotificationPermissionStatus.granted &&
          notification != NotificationPermissionStatus.unsupported)
        PermissionIntroStep.notifications,
      if (_prefs.get(locationIntroSeenKey) != true &&
          _prayer.selectedCoordinates == null)
        PermissionIntroStep.location,
    ];
    loaded = true;
    if (steps.isEmpty) await _finish();
    notifyListeners();
  }

  // Notifications ----------------------------------------------------------

  Future<void> enableNotifications() async {
    if (busy || step != PermissionIntroStep.notifications) return;
    final status = notificationStatus;
    if (status == NotificationPermissionStatus.permanentlyDenied) {
      await openNotificationSettings();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final result = await _notifications.request();
      await _prefs.setBool(notificationPromptSeenKey, true);
      notificationStatus = result;
      notificationAsked = true;
    } finally {
      busy = false;
    }
    if (notificationStatus == NotificationPermissionStatus.granted) {
      await next();
    } else {
      notifyListeners();
    }
  }

  Future<void> openNotificationSettings() async {
    _awaitingSettings = true;
    await _prefs.setBool(notificationPromptSeenKey, true);
    await _notifications.openSettings();
  }

  // Location ---------------------------------------------------------------

  /// Asks for foreground location (when the system still can), then reads
  /// and validates a fix and makes it the prayer location.
  Future<void> enableLocation() async {
    if (busy || step != PermissionIntroStep.location) return;
    final current = await _location.status();
    if (current == LocationAccessStatus.permanentlyDenied ||
        current == LocationAccessStatus.servicesDisabled) {
      locationStatus = current;
      await openLocationSettings();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      await _prefs.setBool(locationIntroSeenKey, true);
      final status = await _location.request();
      locationStatus = status;
      if (status == LocationAccessStatus.granted) {
        await _locate();
      } else {
        locationPhase = LocationIntroPhase.failed;
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _locate() async {
    locationPhase = LocationIntroPhase.locating;
    notifyListeners();
    await _prayer.useDeviceLocation();
    if (_disposed) return;
    locationPhase =
        _prayer.lastLocationError == null && _prayer.selectedCoordinates != null
        ? LocationIntroPhase.located
        : LocationIntroPhase.failed;
  }

  Future<void> openLocationSettings() async {
    _awaitingSettings = true;
    await _prefs.setBool(locationIntroSeenKey, true);
    await _location.openSettings(
      locationStatus ?? LocationAccessStatus.permanentlyDenied,
    );
  }

  /// After a city was chosen by hand on this step.
  void manualLocationChosen() {
    if (_prayer.selectedCoordinates == null) return;
    locationPhase = LocationIntroPhase.located;
    _prefs.setBool(locationIntroSeenKey, true);
    notifyListeners();
  }

  // Lifecycle --------------------------------------------------------------

  /// Reads the system state again, e.g. when the user returns from system
  /// settings, and carries on when access was turned on there.
  Future<void> recheck() async {
    if (!loaded || finished || busy) return;
    final resumeAfterSettings = _awaitingSettings;
    _awaitingSettings = false;
    switch (step) {
      case PermissionIntroStep.notifications:
        notificationStatus = await _notifications.status();
        if (_disposed) return;
        if (notificationStatus == NotificationPermissionStatus.granted) {
          await next();
          return;
        }
      case PermissionIntroStep.location:
        if (locationPhase == LocationIntroPhase.locating ||
            locationPhase == LocationIntroPhase.located) {
          return;
        }
        final status = await _location.status();
        if (_disposed) return;
        locationStatus = status;
        if (resumeAfterSettings && status == LocationAccessStatus.granted) {
          busy = true;
          notifyListeners();
          try {
            await _locate();
          } finally {
            busy = false;
          }
        }
      case null:
        return;
    }
    notifyListeners();
  }

  // Navigation -------------------------------------------------------------

  /// "Not now" or "continue": records the answer and moves on.
  Future<void> next() async {
    switch (step) {
      case PermissionIntroStep.notifications:
        await _prefs.setBool(notificationPromptSeenKey, true);
      case PermissionIntroStep.location:
        await _prefs.setBool(locationIntroSeenKey, true);
      case null:
        break;
    }
    if (index < steps.length - 1) {
      index++;
      _awaitingSettings = false;
    } else {
      await _finish();
    }
    notifyListeners();
  }

  Future<void> _finish() async {
    await _prefs.remove(permissionIntroPendingKey);
    finished = true;
  }
}
