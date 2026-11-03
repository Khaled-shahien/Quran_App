import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/onboarding/domain/first_run_state.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnusedRepository implements PrayerTimesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wrongly typed first-run flags read as not completed', () async {
    SharedPreferences.setMockInitialValues({
      onboardingCompleteKey: 'yes',
      notificationPromptSeenKey: 1,
    });
    expect(
      hasCompletedOnboarding(await SharedPreferences.getInstance()),
      isFalse,
    );
  });

  test('wrongly typed prayer settings read as not configured', () async {
    SharedPreferences.setMockInitialValues({
      'prayer_latitude': 'x',
      'prayer_longitude': 1,
      'prayer_location_label': 3,
      'prayer_method': 'y',
    });
    final provider = PrayerTimesProvider(
      repository: _UnusedRepository(),
      preferences: await SharedPreferences.getInstance(),
    );
    addTearDown(provider.dispose);

    expect(provider.selectedCoordinates, isNull);
    expect(provider.selectedMethod, PrayerCalculationPolicy.defaultMethod);
  });
}
