import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:sakina_app/features/prayers/domain/Entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/features/prayers/presentation/screens/prayer_times_screen.dart';

class FlakyPrayerTimesRepository implements PrayerTimesRepository {
  int calls = 0;

  @override
  Future<PrayerTimesEntity> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = 5,
  }) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (calls == 1) {
      throw Exception('temporary network failure');
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  testWidgets('Prayer flow: load -> error -> retry -> display', (tester) async {
    final repository = FlakyPrayerTimesRepository();
    final provider = PrayerTimesProvider(repository: repository);

    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: provider,
        child: const MaterialApp(home: PrayerTimesScreen()),
      ),
    );

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Error loading prayer times'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Today\'s Prayer Times'), findsOneWidget);
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);
    expect(find.textContaining('05:00'), findsOneWidget);
    expect(find.textContaining('07:20'), findsOneWidget);
    expect(repository.calls, 2);
  });
}
