import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:sakina_app/firebase_options.dart';
import 'package:sakina_app/core/di/service_locator.dart';
import 'package:sakina_app/core/services/notification_service.dart';
import 'package:sakina_app/core/services/firebase_messaging_service.dart';
import 'package:sakina_app/core/services/workmanager_service.dart';

/// AppInitializer is responsible for orchestrating the app's boot sequence.
/// It establishes Firebase, sets up Dependency Injection, and launches
/// background services in the correct order.
class AppInitializer {
  static bool _isInitialized = false;

  /// Returns whether the app has finished initializing.
  static bool get isInitialized => _isInitialized;

  /// Entry point for all initialization logic.
  static Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('App already initialized', name: 'sakina_app.init');
      return;
    }

    await _initializeFirebase();
    await _setupDependencyInjection();
    await _registerBackgroundHandlers();
    await _initializeBackgroundServices();

    _isInitialized = true;
    developer.log('App initialization complete', name: 'sakina_app.init');
  }

  /// Initializes the Firebase app instance.
  static Future<void> _initializeFirebase() async {
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

  /// Registers background/terminated state handlers.
  static Future<void> _registerBackgroundHandlers() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      developer.log(
        'FCM background handler registered',
        name: 'sakina_app.init',
      );
    } catch (e) {
      developer.log(
        'Failed to register FCM background handler',
        name: 'sakina_app.init',
        error: e,
        level: 1000,
      );
    }
  }

  /// Bootstraps local services sequentially.
  static Future<void> _initializeBackgroundServices() async {
    try {
      // Assuming getIt is loaded successfully
      final firebaseMessagingService = getIt<FirebaseMessagingService>();
      await firebaseMessagingService.initialize();

      final notificationService = getIt<NotificationService>();
      try {
        await notificationService.initialize(requestPermissions: false);
      } catch (error) {
        developer.log(
          'Notification initialization error',
          name: 'sakina_app.init',
          level: 1000,
          error: error,
        );
      }

      // Initialize background task scheduler for boot/update alarm recovery.
      final workManagerService = getIt<WorkManagerService>();
      await workManagerService.initialize();
      await workManagerService.registerBootRescheduleTask();

      developer.log('Background services initialized', name: 'sakina_app.init');
    } catch (e) {
      developer.log(
        'Background services initialization error',
        name: 'sakina_app.init',
        level: 1000,
        error: e,
      );
    }
  }
}
