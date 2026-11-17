import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One recorded problem. Holds only the error's type, never its message,
/// which can contain URLs, coordinates or user input.
@immutable
class DiagnosticEntry {
  const DiagnosticEntry({
    required this.at,
    required this.source,
    required this.type,
  });

  final DateTime at;

  /// Where it happened: `flutter`, `platform`, `background`.
  final String source;

  /// The error's runtime type, e.g. `StateError`.
  final String type;

  Map<String, Object> toJson() => {
    't': at.toUtc().toIso8601String(),
    's': source,
    'e': type,
  };

  static DiagnosticEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['t']}');
    final source = json['s'];
    final type = json['e'];
    if (at == null || source is! String || type is! String) return null;
    return DiagnosticEntry(at: at, source: source, type: type);
  }

  @override
  String toString() => '${at.toIso8601String()} [$source] $type';
}

/// A small on-device log of failures, kept whether or not crash reports are
/// switched on, so problems (especially in background rescheduling) can be
/// seen and shared from Settings. Nothing here leaves the device unless the
/// user copies it.
abstract final class DiagnosticsLog {
  static const String entriesKey = 'diagnostics_log_v1';
  static const String backgroundErrorAtKey =
      'last_background_reschedule_error_at';
  static const String backgroundErrorTypeKey =
      'last_background_reschedule_error_type';

  /// Oldest entries are dropped beyond this many.
  static const int capacity = 50;

  /// Adds an entry. Never throws: diagnostics must not cause another error.
  static Future<void> record(
    Object error, {
    required String source,
    SharedPreferences? preferences,
    DateTime? now,
  }) async {
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      final entry = DiagnosticEntry(
        at: now ?? DateTime.now(),
        source: source,
        type: error.runtimeType.toString(),
      );
      final kept = [...entries(prefs), entry];
      final start = kept.length > capacity ? kept.length - capacity : 0;
      await prefs.setString(
        entriesKey,
        jsonEncode([for (final e in kept.sublist(start)) e.toJson()]),
      );
      if (source == 'background') {
        await prefs.setString(
          backgroundErrorAtKey,
          entry.at.toUtc().toIso8601String(),
        );
        await prefs.setString(backgroundErrorTypeKey, entry.type);
      }
    } catch (_) {
      // Ignore: storage may be unavailable this early or in a dying isolate.
    }
  }

  /// Entries, oldest first. Malformed storage reads as empty.
  static List<DiagnosticEntry> entries(SharedPreferences prefs) {
    final raw = prefs.get(entriesKey);
    if (raw is! String) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?DiagnosticEntry.fromJson(item)];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(entriesKey);
    await prefs.remove(backgroundErrorAtKey);
    await prefs.remove(backgroundErrorTypeKey);
  }

  /// Records uncaught framework and platform errors from now on, keeping
  /// the handlers installed before (default reporting in debug builds).
  /// Crash reporting, when enabled later, chains onto these.
  static void installErrorHandlers() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      unawaited(record(details.exception, source: 'flutter'));
      (previousFlutter ?? FlutterError.presentError)(details);
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(record(error, source: 'platform'));
      return previousPlatform?.call(error, stack) ?? false;
    };
  }
}
