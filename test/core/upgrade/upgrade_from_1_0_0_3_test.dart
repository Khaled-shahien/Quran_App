import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/preference_schema.dart';
import 'package:sakina_app/features/khatma/data/repositories/khatma_repository.dart';
import 'package:sakina_app/features/khatma/domain/models/khatma_model.dart';
import 'package:sakina_app/features/prayers/data/repositories/adhan_settings_store.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/presentation/providers/bookmark_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What an install of `1.0.0+3` (commit 4bc16bc) has in SharedPreferences.
/// Formats were taken from that commit's code; do not edit this fixture to
/// match newer formats — add a new fixture for each release instead.
Map<String, Object> releasePreferences1003() => <String, Object>{
  'onboarding_complete': true,
  'has_seen_notification_permission': true,
  // Bookmark before `bookmark_v2`: four separate keys.
  'bookmark_surah_number': 18,
  'bookmark_surah_name': 'الكهف',
  'bookmark_page_index': 3,
  'bookmark_ayah_number': 45,
  'active_khatma_plan': jsonEncode(<String, Object?>{
    'id': 'k1',
    'start_mode': 'بداية المصحف',
    'start_juz': 1,
    'start_date': '2026-10-01T00:00:00.000',
    'tracking_unit': 'juz',
    'goal_type': 'byDuration',
    'planned_duration_days': 30,
    'daily_target_units': 1.0,
    'completed_units': 4.0,
    'reminder_hour': 21,
    'reminder_minute': 30,
    'is_completed': false,
    'next_surah_number': 4,
    'next_ayah_number': 24,
    'next_page_number': 82,
    'daily_logs': <Object>[
      <String, Object?>{'date': '2026-10-01T00:00:00.000', 'units_read': 1.0},
    ],
    'completed_wirds': <Object>[],
  }),
  'tasbih_state_v1': jsonEncode(<String, Object?>{
    'selected': 0,
    'phrases': <Object>[
      <String, Object?>{'id': 'subhan_allah', 'count': 12, 'target': 33},
    ],
  }),
  'morning_alarm_enabled': true,
  'morning_alarm_hour': 6,
  'morning_alarm_minute': 45,
  'evening_alarm_enabled': false,
  'prayer_latitude': 30.06263,
  'prayer_longitude': 31.24967,
  'prayer_location_label': 'القاهرة',
  'prayer_method': 5,
  'prayer_asr_madhab': 'standard',
  'prayer_timezone': 'Africa/Cairo',
  'adhan_mode_fajr': 'adhan',
  'adhan_mode_dhuhr': 'sound',
  'adhan_reminder_minutes': 10,
  // Single muezzin choice of 1.0.0+3, replaced by per-prayer voices.
  'adhan_muezzin': 'makkah',
  'theme_mode': 'dark',
  'hijri_offset_days': -1,
  'recitation_reciter_id': 7,
  'recitation_speed': 1.25,
  'recitation_last_surah': 36,
  'recitation_last_ayah': 12,
};

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(releasePreferences1003());
    prefs = await SharedPreferences.getInstance();
    await PreferenceSchema.migrate(prefs);
  });

  test('the schema is stamped without touching user data', () {
    expect(
      prefs.getInt(PreferenceSchema.versionKey),
      PreferenceSchema.currentVersion,
    );
    expect(prefs.getDouble('prayer_latitude'), 30.06263);
    expect(prefs.getString('prayer_timezone'), 'Africa/Cairo');
  });

  test('the four-key bookmark becomes the single bookmark', () {
    final bookmark = BookmarkProvider(prefs: prefs);
    expect(bookmark.surahNumber, 18);
    expect(bookmark.ayahNumber, 45);
    expect(bookmark.pageIndex, 3);
    expect(prefs.containsKey('bookmark_surah_number'), isFalse);
    expect(prefs.containsKey(BookmarkProvider.storageKey), isTrue);
  });

  test('the khatma plan is read with its progress and reminder', () {
    final KhatmaModel? khatma = KhatmaRepositoryImpl(
      prefs: prefs,
    ).getActiveKhatma().valueOrNull;
    expect(khatma, isNotNull);
    expect(khatma!.completedUnits, 4.0);
    expect(khatma.reminderHour, 21);
    expect(khatma.nextSurahNumber, 4);
    expect(khatma.dailyLogs, hasLength(1));
  });

  test('tasbih counts survive', () {
    final snapshot = SharedPreferencesTasbihRepository(prefs).load();
    expect(snapshot.valueOrNull?.phrases.first.count, 12);
  });

  test('adhan modes survive; the old muezzin falls back to the default', () {
    final AdhanSettings settings = AdhanSettingsStore(prefs).read();
    expect(settings.modeFor(DailyPrayer.fajr), PrayerAlertMode.adhan);
    expect(settings.modeFor(DailyPrayer.dhuhr), PrayerAlertMode.sound);
    expect(settings.reminderMinutes, 10);
    expect(settings.voices, isEmpty);
  });
}
