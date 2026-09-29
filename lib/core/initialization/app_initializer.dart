import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../services/monitoring_service.dart';

import 'package:sakina_app/firebase_options.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/core/services/preference_schema.dart';

import 'package:sakina_app/core/services/workmanager_service.dart';

enum AppInitializationStage {
  none,
  firebase,
  dependencyInjection,
  monitoring,
  backgroundServices,
}

/// AppInitializer is responsible for orchestrating the app's boot sequence.
/// It establishes Firebase, sets up Dependency Injection, and launches
/// background services in the correct order.
class AppInitializer {
  static bool _isInitialized = false;
  static bool _isDegradedBoot = false;
  static AppInitializationStage _currentStage = AppInitializationStage.none;

  /// Returns whether the app has finished initializing.
  static bool get isInitialized => _isInitialized;

  /// Returns whether startup degraded gracefully after an optional service failed.
  static bool get isDegradedBoot => _isDegradedBoot;

  /// Returns the last completed phase during startup.
  static AppInitializationStage get currentStage => _currentStage;

  /// Entry point for all initialization logic.
  static Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('App already initialized', name: 'sakina_app.init');
      return;
    }

    _isDegradedBoot = false;
    _currentStage = AppInitializationStage.firebase;

    try {
      await _initializeFirebase();
      _currentStage = AppInitializationStage.dependencyInjection;
      await _setupDependencyInjection();
      await PreferenceSchema.migrate(getIt<SharedPreferences>());

      if (Firebase.apps.isNotEmpty) {
        _currentStage = AppInitializationStage.monitoring;
        await MonitoringService.instance.initialize(getIt<SharedPreferences>());
      }

      _currentStage = AppInitializationStage.backgroundServices;
      await _initializeBackgroundServices();

      _isInitialized = true;
      developer.log('App initialization complete', name: 'sakina_app.init');
    } catch (error) {
      _isDegradedBoot = true;
      _currentStage = AppInitializationStage.none;
      developer.log(
        'Startup failed in required phase; app will continue in degraded mode',
        name: 'sakina_app.init',
        error: error,
        level: 1000,
      );
      rethrow;
    }
  }

  /// Initializes the Firebase app instance.
  static Future<void> _initializeFirebase() async {
    if (!MonitoringService.configured) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      developer.log(
        'Firebase Core initialized successfully',
        name: 'sakina_app.init',
      );
    } catch (e) {
      developer.log(
        'Firebase Core initialization failed',
        name: 'sakina_app.init',
        error: e,
        level: 1000,
      );
    }
  }

  /// Sets up GetIt service locator.
  static Future<void> _setupDependencyInjection() async {
    try {
      await setupServiceLocator();
      developer.log(
        'Dependency Injection configured successfully',
        name: 'sakina_app.init',
      );
    } catch (e) {
      developer.log(
        'Dependency Injection failed',
        name: 'sakina_app.init',
        error: e,
        level: 1000,
      );
      rethrow; // Critical failure, app cannot run without DI
    }
  }

  /// Bootstraps local services sequentially.
  static Future<void> _initializeBackgroundServices() async {
    try {
      final notificationService = getIt<NotificationService>();
      try {
        await notificationService.initialize(requestPermissions: false);
      } catch (error) {
        _isDegradedBoot = true;
        developer.log(
          'Notification initialization error',
          name: 'sakina_app.init',
          level: 1000,
          error: error,
        );
      }

      final workManagerService = getIt<WorkManagerService>();
      await workManagerService.initialize();
      try {
        await workManagerService.registerBootRescheduleTask();
      } catch (error) {
        _isDegradedBoot = true;
        developer.log(
          'WorkManager boot reschedule unavailable',
          name: 'sakina_app.init',
          level: 1000,
          error: error,
        );
      }

      developer.log('Background services initialized', name: 'sakina_app.init');
    } catch (e) {
      _isDegradedBoot = true;
      developer.log(
        'Background services initialization error',
        name: 'sakina_app.init',
        level: 1000,
        error: e,
      );
    }
  }
}
