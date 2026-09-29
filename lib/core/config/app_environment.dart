/// Production-safe build profiles for the app.
///
/// Use a dart-define like `--dart-define=APP_ENV=production` to pin the profile
/// for each build. Local development remains the default, while staging and
/// production explicitly opt into stricter behavior.
enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig._();

  static const String _environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get environment {
    return parseEnvironment(_environmentName);
  }

  static AppEnvironment parseEnvironment(String value) {
    switch (value.trim().toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  static String get profileName => environment.name;

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isStaging => environment == AppEnvironment.staging;

  static bool get enableFirebaseMonitoring {
    const bool firebaseMonitoringOverride = bool.fromEnvironment(
      'ENABLE_FIREBASE_MONITORING',
      defaultValue: false,
    );

    return firebaseMonitoringOverride || isProduction;
  }
}
