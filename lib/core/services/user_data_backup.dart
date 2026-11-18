import 'package:sakina_app/core/database/user_data_tables.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/quran/data/repositories/verse_library_repository.dart';
import 'preference_schema.dart';

/// What a backup file holds, read before anything is written.
class BackupSummary {
  const BackupSummary({
    required this.exportedAt,
    required this.preferenceCount,
    required this.savedVerses,
    required this.notes,
  });

  final DateTime? exportedAt;
  final int preferenceCount;
  final int savedVerses;
  final int notes;
}

/// The backup file could not be used; nothing was changed.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);
  final String reason;
  @override
  String toString() => 'BackupFormatException($reason)';
}

/// Exports the user's own data to one JSON document and restores it.
///
/// Only listed keys are carried: settings, prayer place and alerts,
/// reading position, bookmark, khatma, tasbih, adhkar progress and
/// favourites, plus the database rows (saved verses, notes). Device state
/// (diagnostics, scheduling bookkeeping, permission prompts already shown,
/// crash-report consent) is never exported or imported. Import replaces
/// the listed data and leaves everything else as it is.
class UserDataBackup {
  UserDataBackup({
    required SharedPreferences prefs,
    required VerseLibraryRepository library,
    List<UserDataTables> otherTables = const [],
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _tables = [library, ...otherTables],
       _clock = clock ?? DateTime.now;

  static const String format = 'sakina-backup';
  static const int version = 1;

  /// Exact keys of user data.
  static const Set<String> keys = {
    // Appearance and reading
    'theme_mode', 'app_design', 'ui_text_size', 'digit_style',
    'hijri_offset_days', 'feedback_haptics_enabled', 'feedback_sounds_enabled',
    'reading_font_size', 'reading_line_height', 'reading_verse_markers',
    'reading_layout', 'reading_night_mode',
    // Quran, khatma, tasbih, favourites
    'bookmark_v2', 'active_khatma_plan', 'saved_wird_position',
    'tasbih_state_v1', 'favorite_verses',
    'recitation_reciter_id', 'recitation_speed',
    'recitation_last_surah', 'recitation_last_ayah',
    // Prayer place and calculation
    'prayer_latitude', 'prayer_longitude', 'prayer_location_label',
    'prayer_method', 'prayer_asr_madhab', 'prayer_timezone',
    'prayer_location_source', 'prayer_time_adjustments',
    'prayer_method_suggestion_dismissed',
    // Alerts and reminders
    'prayer_notifications_enabled', 'adhan_reminder_minutes',
    'morning_alarm_enabled', 'morning_alarm_hour', 'morning_alarm_minute',
    'evening_alarm_enabled', 'evening_alarm_hour', 'evening_alarm_minute',
    'mulk_alarm_enabled', 'mulk_alarm_hour', 'mulk_alarm_minute',
    'baqarah_alarm_enabled', 'baqarah_alarm_hour', 'baqarah_alarm_minute',
    'daily_verse_alarm_enabled', 'verse_alarm_hour', 'verse_alarm_minute',
    'morning_alarm_anchor_minutes', 'evening_alarm_anchor_minutes',
    'adhan_quiet_minutes', 'fajr_wake_enabled', 'fajr_wake_snooze_minutes',
    // Prayer and fasting log
    'practice_excused_mode', 'fasting_qada_base',
  };

  /// Families of keys with a variable suffix.
  static const List<String> prefixes = [
    'adhan_mode_', // per prayer
    'adhan_voice_', // per prayer
    'adhkar_progress_v1_', // per category
    'reading_last_ayah_', // per surah
  ];

  /// Tables read from a backup file; any other entry is ignored.
  static const List<String> tableNames = [
    'saved_verses',
    'verse_notes',
    'prayer_log',
    'fasting_log',
  ];

  static bool isUserKey(String key) =>
      keys.contains(key) || prefixes.any(key.startsWith);

  final SharedPreferences _prefs;
  final List<UserDataTables> _tables;
  final DateTime Function() _clock;

  Future<String> export() async {
    final Map<String, Object?> preferences = {
      for (final String key
          in _prefs.getKeys().where(isUserKey).toList()..sort())
        key: _prefs.get(key),
    };
    final rows = <String, List<Map<String, Object?>>>{
      for (final tables in _tables) ...await tables.exportRows(),
    };
    return const JsonEncoder.withIndent(' ').convert({
      'format': format,
      'version': version,
      'preferencesSchema': PreferenceSchema.currentVersion,
      'exportedAt': _clock().toUtc().toIso8601String(),
      'preferences': preferences,
      'database': rows,
    });
  }

  /// Checks [raw] without changing anything.
  BackupSummary inspect(String raw) {
    final _Parsed parsed = _parse(raw);
    return BackupSummary(
      exportedAt: parsed.exportedAt,
      preferenceCount: parsed.preferences.length,
      savedVerses: parsed.rows['saved_verses']?.length ?? 0,
      notes: parsed.rows['verse_notes']?.length ?? 0,
    );
  }

  /// Replaces the user's data with the backup's. Prayer alerts must be
  /// rescheduled afterwards (the app restarts).
  Future<void> restore(String raw) async {
    final _Parsed parsed = _parse(raw);
    for (final String key in _prefs.getKeys().where(isUserKey).toList()) {
      if (!parsed.preferences.containsKey(key)) await _prefs.remove(key);
    }
    for (final MapEntry(:key, :value) in parsed.preferences.entries) {
      switch (value) {
        case final bool v:
          await _prefs.setBool(key, v);
        case final int v:
          await _prefs.setInt(key, v);
        case final double v:
          await _prefs.setDouble(key, v);
        case final String v:
          await _prefs.setString(key, v);
        case final List<String> v:
          await _prefs.setStringList(key, v);
      }
    }
    for (final tables in _tables) {
      await tables.replaceAll(parsed.rows);
    }
  }

  /// Removes the user's data (the listed keys and every saved verse and
  /// note). Device state such as onboarding stays, so the app does not
  /// ask for permissions again.
  Future<void> erase() async {
    for (final String key in _prefs.getKeys().where(isUserKey).toList()) {
      await _prefs.remove(key);
    }
    for (final tables in _tables) {
      await tables.clear();
    }
  }

  _Parsed _parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupFormatException('not json');
    }
    if (decoded is! Map<String, dynamic> || decoded['format'] != format) {
      throw const BackupFormatException('not a Sakina backup');
    }
    final Object? fileVersion = decoded['version'];
    if (fileVersion is! int || fileVersion > version) {
      throw const BackupFormatException('newer backup version');
    }
    final Object? schema = decoded['preferencesSchema'];
    if (schema is int && schema > PreferenceSchema.currentVersion) {
      throw const BackupFormatException('newer preferences');
    }
    final Map<String, Object> preferences = {};
    final Object? prefs = decoded['preferences'];
    if (prefs is Map<String, dynamic>) {
      for (final MapEntry(:key, :value) in prefs.entries) {
        if (!isUserKey(key)) continue;
        final Object? typed = switch (value) {
          bool() || int() || String() => value,
          // JSON has one number type: keep a whole double a double.
          double() => value,
          List() when value.every((e) => e is String) =>
            value.cast<String>().toList(),
          _ => null,
        };
        if (typed != null) preferences[key] = typed;
      }
    }
    final Map<String, List<Map<String, Object?>>> rows = {};
    final Object? database = decoded['database'];
    if (database is Map<String, dynamic>) {
      for (final String table in tableNames) {
        final Object? list = database[table];
        if (list is List) {
          rows[table] = [
            for (final Object? row in list)
              if (row is Map<String, dynamic>) row,
          ];
        }
      }
    }
    final Object? at = decoded['exportedAt'];
    return _Parsed(
      preferences: preferences,
      rows: rows,
      exportedAt: at is String ? DateTime.tryParse(at)?.toLocal() : null,
    );
  }
}

class _Parsed {
  const _Parsed({
    required this.preferences,
    required this.rows,
    required this.exportedAt,
  });
  final Map<String, Object> preferences;
  final Map<String, List<Map<String, Object?>>> rows;
  final DateTime? exportedAt;
}
