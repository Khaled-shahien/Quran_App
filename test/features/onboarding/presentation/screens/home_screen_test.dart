import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/providers/settings_provider.dart';
import 'package:quran_app/core/services/alarm_reschedule_task_service.dart';
import 'package:quran_app/core/services/alarm_scheduler.dart';
import 'package:quran_app/core/theme/theme_provider.dart';
import 'package:quran_app/features/hadeath/domain/repositories/hadeath_repository.dart';
import 'package:quran_app/features/hadeath/presentation/providers/hadeath_provider.dart';
import 'package:quran_app/features/duas/data/models/azkar_model.dart';
import 'package:quran_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:quran_app/features/duas/data/repositories/duas_repository.dart';
import 'package:quran_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:quran_app/features/duas/presentation/providers/duas_provider.dart';
import 'package:quran_app/features/hadeath/domain/entities/hadeath_entity.dart';
import 'package:quran_app/features/khatma/data/repositories/khatma_repository.dart';
import 'package:quran_app/features/khatma/presentation/providers/khatma_provider.dart';
import 'package:quran_app/features/onboarding/presentation/providers/favorites_provider.dart';
import 'package:quran_app/features/onboarding/presentation/screens/home_screen.dart';
import 'package:quran_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:quran_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:quran_app/features/prayers/presentation/providers/prayer_times_performance_provider.dart';
import 'package:quran_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:quran_app/features/quran/domain/entities/surah_entity.dart';
import 'package:quran_app/features/quran/domain/repositories/surah_repository.dart';
import 'package:quran_app/features/quran/presentation/providers/bookmark_provider.dart';

class FakeAlarmScheduler implements AlarmScheduler {
  @override
  Future<Map<String, int>> getAlarmTime(String type) async => <String, int>{
    'hour': 7,
    'minute': 0,
  };

  @override
  Future<void> initialize({bool requestPermissions = false}) async {}

  @override
  Future<void> rescheduleSingleAlarm({
    required String type,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> saveAlarmTime({
    required String type,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {}
}

class FakeRescheduleTaskService implements AlarmRescheduleTaskService {
  @override
  Future<void> registerImmediateRescheduleTask({
    String source = 'manual_settings_update',
  }) async {}
}

class FakePrayerTimesRepository implements PrayerTimesRepository {
  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    return PrayerTimesEntity(
      fajr: '05:00',
      sunrise: '06:20',
      dhuhr: '12:15',
      asr: '15:40',
      maghrib: '18:30',
      isha: '19:45',
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
    );
  }
}

class FakeSurahRepository implements SurahRepository {
  @override
  Future<void> clearCache() async {}

  @override
  Future<List<SurahEntity>> getAllSurahs() async => const <SurahEntity>[];

  @override
  Future<SurahEntity> getSurahByIndex(int index) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getSurahStatistics() async =>
      <String, dynamic>{};

  @override
  Future<List<SurahEntity>> getSurahsByRevelationPlace(String place) async =>
      const <SurahEntity>[];

  @override
  Future<List<SurahEntity>> searchSurahs(String query) async =>
      const <SurahEntity>[];
}

class FakeAzkarRepository implements AzkarRepository {
  @override
  Future<List<AzkarCategoryModel>> getAllAzkar() async =>
      <AzkarCategoryModel>[];
}

class FakeDuasRepository implements DuasRepository {
  @override
  Future<List<AzkarCategoryModel>> getAllDuas() async => <AzkarCategoryModel>[];
}

class FakeHadeathRepository implements HadeathRepository {
  @override
  Future<List<HadeathEntity>> getAllAhadeth() async => <HadeathEntity>[];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> buildHome() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final prayerRepository = FakePrayerTimesRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<BookmarkProvider>(
          create: (_) => BookmarkProvider(prefs: prefs),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(
            prefs: prefs,
            alarmScheduler: FakeAlarmScheduler(),
            rescheduleTaskService: FakeRescheduleTaskService(),
          ),
        ),
        ChangeNotifierProvider<PrayerTimesProvider>(
          create: (_) => PrayerTimesProvider(repository: prayerRepository),
        ),
        ChangeNotifierProvider<PrayerTimesPerformanceProvider>(
          create: (_) =>
              PrayerTimesPerformanceProvider(repository: prayerRepository),
        ),
        ChangeNotifierProvider<KhatmaProvider>(
          create: (_) =>
              KhatmaProvider(repository: KhatmaRepository(prefs: prefs)),
        ),
        ChangeNotifierProvider<AzkarProvider>(
          create: (_) => AzkarProvider(repository: FakeAzkarRepository()),
        ),
        ChangeNotifierProvider<DuasProvider>(
          create: (_) => DuasProvider(repository: FakeDuasRepository()),
        ),
        ChangeNotifierProvider<HadeathProvider>(
          create: (_) => HadeathProvider(repository: FakeHadeathRepository()),
        ),
        Provider<SurahRepository>(create: (_) => FakeSurahRepository()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  testWidgets('HomeScreen renders main sections', (tester) async {
    await tester.pumpWidget(await buildHome());
    await tester.pumpAndSettle();

    expect(find.text('سكينة'), findsOneWidget);
    expect(find.text('الورد الحالي'), findsOneWidget);
    expect(find.byIcon(Icons.segment), findsOneWidget);
  });

  testWidgets('HomeScreen opens drawer and shows settings sections', (
    tester,
  ) async {
    await tester.pumpWidget(await buildHome());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.segment));
    await tester.pumpAndSettle();

    expect(find.text('المزيد'), findsOneWidget);
    expect(find.text('دعم التطبيق'), findsOneWidget);
    expect(find.text('الختمة الحالية'), findsOneWidget);
  });
}
