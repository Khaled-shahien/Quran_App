import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/services/scheduling_generation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/prayer_calculation_policy.dart';
import '../../domain/prayer_time_zone.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/services/prayer_notification_scheduler.dart';

import '../../domain/prayer_window.dart';
import '../repositories/adhan_settings_store.dart';
import 'local_prayer_notification_scheduler.dart';

/// After the UI isolate schedules today, schedules the following days of the
/// window from the saved settings in the same isolate. A failure is logged,
/// not thrown: today is already scheduled and the periodic background task
/// retries the rest.
Future<void> scheduleRestOfPrayerWindow({
  required SharedPreferences preferences,
  required PrayerTimesRepository repository,
  required PrayerNotificationGateway gateway,
  Future<void> Function(DateTime lastDay)? onWindowScheduled,
}) async {
  try {
    final lastDay = await PrayerReplenishmentService(
      preferences: preferences,
      repository: repository,
      scheduler: LocalPrayerNotificationScheduler(
        prefs: preferences,
        notificationGateway: gateway,
      ),
      firstDay: 1,
      cancelWhenUnconfigured: false,
    ).replenish();
    if (lastDay != null) await onWindowScheduled?.call(lastDay);
  } catch (error) {
    developer.log(
      'Scheduling the following prayer days failed',
      name: 'sakina_app.prayer_notifications',
      level: 900,
      error: error,
    );
  }
}

/// Recalculates the next days' prayer times from the saved settings and
/// schedules them. Runs in the background, and in the UI isolate to fill the
/// days after today; never uses GPS or the network.
class PrayerReplenishmentService {
  PrayerReplenishmentService({
    required this.preferences,
    required this.repository,
    required this.scheduler,
    DateTime Function()? now,
    int? days,
    this.firstDay = 0,
    this.cancelWhenUnconfigured = true,
    this.expectedGeneration,
  }) : _now = now ?? DateTime.now,
       _days = days;

  final SharedPreferences preferences;
  final PrayerTimesRepository repository;
  final PrayerNotificationScheduler scheduler;
  final DateTime Function() _now;

  /// The schedule window: days `0 .. days - 1`, where day 0 is today.
  /// By default it depends on the platform and alert settings
  /// ([prayerWindowDays]).
  int get days =>
      _days ??
      prayerWindowDays(
        AdhanSettingsStore(preferences).read(),
        ios: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
      );
  final int? _days;

  /// The first day of the window to schedule. The UI isolate schedules
  /// today itself and then passes 1 to fill the rest of the window.
  final int firstDay;

  /// Whether disabled reminders or a missing/invalid location cancel all
  /// prayer notifications. The UI isolate's follow-up passes false: its own
  /// schedule call already handled those cases from the provider's state.
  final bool cancelWhenUnconfigured;

  /// The [SchedulingGeneration] this run started from (background runs).
  /// Once the UI isolate advances it, this run stops before writing again.
  final int? expectedGeneration;

  bool get _superseded =>
      expectedGeneration != null &&
      SchedulingGeneration.read(preferences) != expectedGeneration;

  /// Returns the last day it scheduled, or null when it scheduled nothing
  /// (disabled, unconfigured, superseded or settings changed meanwhile).
  Future<DateTime?> replenish() async {
    await preferences.reload();
    if (_superseded) return null;
    if (!(preferences.getBool('prayer_notifications_enabled') ?? true)) {
      if (cancelWhenUnconfigured) await scheduler.cancelPrayerNotifications();
      return null;
    }
    final latitude = preferences.getDouble('prayer_latitude');
    final longitude = preferences.getDouble('prayer_longitude');
    final method =
        preferences.getInt('prayer_method') ??
        PrayerCalculationPolicy.defaultMethod;
    final storedZone = preferences.getString(prayerTimeZonePreferenceKey);
    final madhab = AsrMadhab.fromStorage(
      preferences.get(AsrMadhab.preferenceKey),
    );
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        !PrayerCalculationPolicy.methods.containsKey(method)) {
      if (cancelWhenUnconfigured) await scheduler.cancelPrayerNotifications();
      return null;
    }

    // "Today" is the calendar day at the prayer location, which can differ
    // from the device's day after travel or a manually chosen city.
    final wall = prayerWallTime(_now(), storedZone);
    final today = DateTime(wall.year, wall.month, wall.day);
    DateTime? lastDay;
    final int windowDays = days;
    for (var offset = firstDay; offset < windowDays; offset++) {
      final target = DateTime(today.year, today.month, today.day + offset);
      final result = await repository.getPrayerTimes(
        target,
        latitude,
        longitude,
        calculationMethod: method,
        madhab: madhab,
        timeZone: storedZone,
      );
      final timings = switch (result) {
        Success(:final value) => value,
        Err(:final failure) => throw StateError(
          'Prayer times could not be calculated: ${failure.cause}',
        ),
      };
      if (LocalPrayerNotificationScheduler.buildPrayerSchedule(
            prayerTimes: timings,
            date: target,
          ).length !=
          5) {
        throw StateError('Incomplete daily prayer timings');
      }
      await preferences.reload();
      if (_superseded ||
          !(preferences.getBool('prayer_notifications_enabled') ?? true) ||
          preferences.getDouble('prayer_latitude') != latitude ||
          preferences.getDouble('prayer_longitude') != longitude ||
          (preferences.getInt('prayer_method') ??
                  PrayerCalculationPolicy.defaultMethod) !=
              method ||
          preferences.getString(prayerTimeZonePreferenceKey) != storedZone ||
          AsrMadhab.fromStorage(preferences.get(AsrMadhab.preferenceKey)) !=
              madhab) {
        // The foreground selection owns cancellation/replacement of old alarms.
        return null;
      }
      await scheduler.schedulePrayerNotifications(
        prayerTimes: timings,
        date: target,
      );
      lastDay = target;
    }
    return lastDay;
  }
}
