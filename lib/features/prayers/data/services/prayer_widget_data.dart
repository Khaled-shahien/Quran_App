import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/adhan_settings.dart';

/// What the Android home-screen widget shows, written by the app.
///
/// Stored in the app's own SharedPreferences (key [key]), which the native
/// widget reads directly: today's and tomorrow's five prayers with their
/// instants and display times, the place and the Hijri date. The widget
/// highlights the next prayer itself, so it stays right between updates.
/// Nothing is sent anywhere.
abstract final class PrayerWidgetData {
  static const String key = 'prayer_widget_v1';
  static const MethodChannel _channel = MethodChannel('sakina/widget');

  static Map<String, Object?> encode({
    required String place,
    required String? hijri,
    required List<
      ({DailyPrayer prayer, String name, DateTime at, String label})
    >
    prayers,
  }) => {
    'version': 1,
    'place': place,
    'hijri': ?hijri,
    'prayers': [
      for (final p in prayers)
        {
          'id': p.prayer.name,
          'name': p.name,
          'at': p.at.millisecondsSinceEpoch,
          'label': p.label,
        },
    ],
  };

  /// Saves the data and asks the widget to redraw. Safe to call from a
  /// background isolate: the redraw request is skipped there.
  static Future<void> write(
    SharedPreferences prefs,
    Map<String, Object?> data,
  ) async {
    await prefs.setString(key, jsonEncode(data));
    await refresh();
  }

  static Future<void> refresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('update');
    } on MissingPluginException {
      // Background isolate: the widget updates on its own schedule.
    } on PlatformException {
      // No widget placed, or the launcher refused; nothing to do.
    }
  }
}
