import 'package:sakina_app/l10n/localization.dart';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import '../navigation/notification_router.dart';
import 'notification_service.dart';

/// Background message handler - MUST be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    '[FCM][BG] messageId=${message.messageId} '
    'data=${message.data} '
    'hasNotification=${message.notification != null}',
    name: 'sakina_app.fcm',
  );

  // Ensure Firebase is initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Show notification even when app is in background
  final NotificationService notificationService = NotificationService.instance;
  await notificationService.initialize(requestPermissions: false);
  await notificationService.showNotification(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title:
        message.notification?.title ?? appL10n.firebaseMessagingServiceMessage1,
    body: message.notification?.body ?? '',
    payload: message.data['type'] ?? 'general',
    payloadData: Map<String, dynamic>.from(message.data),
  );
}

/// Firebase Cloud Messaging Service
///
/// Handles:
/// - FCM initialization
/// - Permission requests
/// - Foreground messages (onMessage)
/// - Background messages (onBackgroundMessage)
/// - Notification taps (onMessageOpenedApp)
/// - Token management
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  static FirebaseMessagingService get instance => _instance;

  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  bool _isInitialized = false;
  static const int _maxInitAttempts = 3;

  // Callbacks for notification interactions
  Function(String type, Map<String, dynamic> data)? onNotificationTap;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    if (_isInitialized) return;

    for (int attempt = 1; attempt <= _maxInitAttempts; attempt++) {
      try {
        developer.log(
          '[FCM] Initialization attempt $attempt started',
          name: 'sakina_app.fcm',
        );

        // Initialize Firebase if not already done
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }

        // Set up background message handler
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        developer.log(
          '[FCM] Background message handler registered',
          name: 'sakina_app.fcm',
        );

        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Request permissions
        await _requestPermissions();

        // Set up message handlers
        await _setupMessageHandlers();

        // Get the FCM token with timeout to avoid startup stalls.
        final token = await _firebaseMessaging.getToken().timeout(
          const Duration(seconds: 6),
        );
        developer.log(
          '[FCM] Token generated: ${token == null ? 'no' : 'yes'}',
          name: 'sakina_app.fcm',
        );

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          developer.log('[FCM] Token refreshed', name: 'sakina_app.fcm');
          _updateTokenInBackend(newToken);
        });

        _isInitialized = true;
        developer.log(
          '[FCM] Firebase Messaging Service initialized successfully',
          name: 'sakina_app.fcm',
        );
        return;
      } catch (e) {
        developer.log(
          '[FCM] Initialization failed '
          '(attempt $attempt/$_maxInitAttempts): $e',
          name: 'sakina_app.fcm',
          level: 1000,
          error: e,
        );

        if (attempt == _maxInitAttempts) {
          rethrow;
        }

        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // iOS/macOS permissions
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
        // Check current authorization status
        NotificationSettings settings = await _firebaseMessaging
            .requestPermission(
              alert: true,
              announcement: false,
              badge: true,
              carPlay: false,
              criticalAlert: false,
              provisional: false,
              sound: true,
            );

        developer.log(
          'iOS Notification Settings granted: ${settings.authorizationStatus}',
          name: 'sakina_app.fcm',
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          developer.log(
            'User granted notification permission',
            name: 'sakina_app.fcm',
          );
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
          developer.log(
            'User granted provisional notification permission',
            name: 'sakina_app.fcm',
          );
        } else {
          developer.log(
            'User declined notification permission',
            name: 'sakina_app.fcm',
            level: 900,
          );
        }
      }

      // Android permissions are handled by flutter_local_notifications
    } catch (e) {
      developer.log(
        'Error requesting permissions',
        name: 'sakina_app.fcm',
        level: 1000,
        error: e,
      );
    }
  }

  /// Set up message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '[FCM][FG] messageId=${message.messageId} '
        'title=${message.notification?.title} '
        'body=${message.notification?.body} '
        'data=${message.data}',
        name: 'sakina_app.fcm',
      );
      _handleForegroundMessage(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        '[FCM][OPENED_APP] messageId=${message.messageId} data=${message.data}',
        name: 'sakina_app.fcm',
      );
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        '[FCM][INITIAL] App opened from terminated state: '
        '${initialMessage.messageId}',
        name: 'sakina_app.fcm',
      );
      _handleNotificationTap(initialMessage);
    } else {
      developer.log(
        '[FCM][INITIAL] No initial notification payload',
        name: 'sakina_app.fcm',
      );
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification for foreground message
    final NotificationService notificationService =
        NotificationService.instance;
    notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title:
          message.notification?.title ??
          appL10n.firebaseMessagingServiceMessage1,
      body: message.notification?.body ?? '',
      payload: message.data['type'] ?? 'general',
      payloadData: Map<String, dynamic>.from(message.data),
    );
    developer.log(
      '[FCM][FG] Local notification trigger requested',
      name: 'sakina_app.fcm',
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final String type = message.data['type'] ?? 'general';
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);

    developer.log(
      '[FCM][NAV] Routing notification type=$type data=$data',
      name: 'sakina_app.fcm',
    );

    NotificationRouter.handleNotification(type: type, data: data);

    // Call callback if provided
    if (onNotificationTap != null) {
      onNotificationTap!(type, data);
    }
  }

  /// Update token in backend (placeholder)
  void _updateTokenInBackend(String _) {
    // Intentionally left as a hook for optional backend token registration.
    developer.log('Backend token sync hook invoked', name: 'sakina_app.fcm');
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      developer.log(
        'Error getting FCM token',
        name: 'sakina_app.fcm',
        level: 1000,
        error: e,
      );
      return null;
    }
  }

  /// Refresh FCM token
  Future<void> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final newToken = await _firebaseMessaging.getToken();
      developer.log('Token refreshed', name: 'sakina_app.fcm');
      if (newToken == null || newToken.isEmpty) {
        developer.log(
          'Token refresh returned null/empty token',
          name: 'sakina_app.fcm',
          level: 900,
        );
        return;
      }
      _updateTokenInBackend(newToken);
    } catch (e) {
      developer.log(
        'Error refreshing token',
        name: 'sakina_app.fcm',
        level: 1000,
        error: e,
      );
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'sakina_app.fcm');
    } catch (e) {
      developer.log(
        'Error subscribing to topic',
        name: 'sakina_app.fcm',
        level: 1000,
        error: e,
      );
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic', name: 'sakina_app.fcm');
    } catch (e) {
      developer.log(
        'Error unsubscribing from topic',
        name: 'sakina_app.fcm',
        level: 1000,
        error: e,
      );
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Delete token (for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      developer.log('Token deleted', name: 'sakina_app.fcm');
    } catch (e) {
      developer.log(
        'Error deleting token',
        name: 'sakina_app.fcm',
        level: 1000,
        error: e,
      );
    }
  }
}
