import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/prayers/presentation/screens/prayer_times_screen.dart';

class FakePrayerTimesRepository implements PrayerTimesRepository {
  FakePrayerTimesRepository({this.shouldThrow = false});

  final bool shouldThrow;
  int calls = 0;

  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    calls++;
    if (shouldThrow) {
      throw Exception('network failed');
    }

    return PrayerTimesEntity(
      fajr: '05:00',
      sunrise: '06:20',
      dhuhr: '12:10',
      asr: '15:30',
      maghrib: '18:05',
      isha: '19:20',
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
    );
  }
}

class DelayedPrayerTimesRepository implements PrayerTimesRepository {
  DelayedPrayerTimesRepository({required this.completer});

  final Completer<void> completer;

  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    await completer.future;
    return PrayerTimesEntity(
      fajr: '05:11',
      sunrise: '06:25',
      dhuhr: '12:15',
      asr: '15:35',
      maghrib: '18:07',
      isha: '19:21',
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
    );
  }
}

class FlakyPrayerTimesRepository implements PrayerTimesRepository {
  int calls = 0;

  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 3,
  }) async {
    calls++;
    if (calls == 1) {
      throw Exception('first call failed');
    }
    return PrayerTimesEntity(
      fajr: '05:02',
      sunrise: '06:21',
      dhuhr: '12:12',
      asr: '15:31',
      maghrib: '18:06',
      isha: '19:22',
      latitude: latitude,
      longitude: longitude,
      calculationMethod: calculationMethod,
    );
  }
}

class IdlePrayerTimesProvider extends PrayerTimesProvider {
  IdlePrayerTimesProvider({required super.repository});

  @override
  Future<void> fetchTodayForCurrentLocation({
    int calculationMethod = 5,
  }) async {}

  @override
  bool get isLoading => false;

  @override
  bool get hasError => false;

  @override
  bool get hasData => false;

  @override
  String? get errorMessage => null;

  @override
  Map<String, String> getMainPrayerTimes() => <String, String>{};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders successful prayer times list', (tester) async {
    final repository = FakePrayerTimesRepository();
    final provider = PrayerTimesProvider(
      repository: repository,
      locationService: const FixedPrayerLocationService(
        latitude: 30,
        longitude: 31,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('أوقات الصلاة'), findsOneWidget);
    expect(find.text('مواقيت اليوم'), findsOneWidget);
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.textContaining('05:00'), findsAtLeastNWidgets(1));
    expect(repository.calls, greaterThanOrEqualTo(1));
  });

  testWidgets('renders error state and retry action', (tester) async {
    final repository = FakePrayerTimesRepository(shouldThrow: true);
    final provider = PrayerTimesProvider(
      repository: repository,
      locationService: const FixedPrayerLocationService(
        latitude: 30,
        longitude: 31,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('تعذر عرض مواقيت الصلاة'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(repository.calls, greaterThanOrEqualTo(2));
  });

  testWidgets('shows loading indicator while fetch is pending', (tester) async {
    final completer = Completer<void>();
    final repository = DelayedPrayerTimesRepository(completer: completer);
    final provider = PrayerTimesProvider(
      repository: repository,
      locationService: const FixedPrayerLocationService(
        latitude: 30,
        longitude: 31,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );

    await tester.pump();
    expect(find.byType(PulseLoader), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.text('مواقيت اليوم'), findsOneWidget);
  });

  testWidgets('renders all Arabic prayer names in success state', (
    tester,
  ) async {
    final repository = FakePrayerTimesRepository();
    final provider = PrayerTimesProvider(
      repository: repository,
      locationService: const FixedPrayerLocationService(
        latitude: 30,
        longitude: 31,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الشروق'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('العصر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);
  });

  testWidgets('renders no-data branch when provider stays idle', (
    tester,
  ) async {
    final provider = IdlePrayerTimesProvider(
      repository: FakePrayerTimesRepository(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('حدد موقعك لعرض المواقيت'), findsOneWidget);
  });

  testWidgets('retry recovers from first failure to success', (tester) async {
    final repository = FlakyPrayerTimesRepository();
    final provider = PrayerTimesProvider(
      repository: repository,
      locationService: const FixedPrayerLocationService(
        latitude: 30,
        longitude: 31,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر عرض مواقيت الصلاة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('مواقيت اليوم'), findsOneWidget);
    expect(find.text('الفجر'), findsOneWidget);
    expect(repository.calls, 2);
  });

  testWidgets('renders current date header in content card', (tester) async {
    final repository = FakePrayerTimesRepository();
    final provider = PrayerTimesProvider(
      repository: repository,
      locationService: const FixedPrayerLocationService(
        latitude: 30,
        longitude: 31,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final expectedDate = '${now.day}/${now.month}/${now.year}';
    expect(find.text(expectedDate), findsOneWidget);
  });
}
