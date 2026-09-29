import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/api/api_constants.dart';
import 'package:sakina_app/core/config/app_environment.dart';

void main() {
  test(
    'environment parsing is explicit and safely defaults to development',
    () {
      expect(
        AppConfig.parseEnvironment('development'),
        AppEnvironment.development,
      );
      expect(AppConfig.parseEnvironment(' STAGING '), AppEnvironment.staging);
      expect(
        AppConfig.parseEnvironment('PRODUCTION'),
        AppEnvironment.production,
      );
      expect(AppConfig.parseEnvironment('unknown'), AppEnvironment.development);
    },
  );

  test('API configuration has valid safe defaults', () {
    expect(Uri.parse(ApiConstants.quranBaseUrl).hasScheme, isTrue);
    expect(Uri.parse(ApiConstants.prayerTimesBaseUrl).hasScheme, isTrue);
    expect(ApiConstants.quranBaseUrl.endsWith('/'), isFalse);
    expect(ApiConstants.prayerTimesBaseUrl.endsWith('/'), isFalse);
  });
}
