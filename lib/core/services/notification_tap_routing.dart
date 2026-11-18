import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../navigation/notification_router.dart';

/// Turns a tap on a notification (or one of its buttons) into navigation.
abstract final class NotificationTapRouting {
  static ({int? id, String? actionId, String? payload, DateTime at})?
  _lastRouted;

  /// Routes a tap on a notification or one of its buttons. The same tap
  /// reported twice within two seconds (as a launch and as a response, or a
  /// double tap) opens its screen only once.
  static void routeNotificationResponse({
    int? id,
    String? actionId,
    String? payload,
    DateTime? now,
  }) {
    final DateTime at = now ?? DateTime.now();
    final last = _lastRouted;
    // Every real notification has an id; without one there is nothing to
    // tell two taps apart by, so each is routed.
    if (id != null &&
        last != null &&
        last.id == id &&
        last.actionId == actionId &&
        last.payload == payload &&
        at.difference(last.at).abs() < const Duration(seconds: 2)) {
      return;
    }
    _lastRouted = (id: id, actionId: actionId, payload: payload, at: at);
    routeNotificationPayload(payload, actionId: actionId);
  }

  static void resetRoutingHistory() => _lastRouted = null;

  static void routeLaunchDetails(NotificationAppLaunchDetails? details) {
    if (details == null || !details.didNotificationLaunchApp) return;
    final NotificationResponse? response = details.notificationResponse;
    routeNotificationResponse(
      id: response?.id,
      actionId: response?.actionId,
      payload: response?.payload,
    );
  }

  static void routeNotificationPayload(String? rawPayload, {String? actionId}) {
    final String payload = rawPayload ?? '';
    if (payload.isEmpty) {
      NotificationRouter.handleNotification(type: 'general');
      return;
    }

    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        final String type = decoded['type']?.toString() ?? 'general';
        final dynamic rawData = decoded['data'];
        final Map<String, dynamic> data = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};
        NotificationRouter.handleNotification(
          type: type,
          data: data,
          actionId: actionId,
        );
        return;
      }
    } catch (_) {
      // Plain string payloads are treated as a notification type.
    }

    NotificationRouter.handleNotification(type: payload);
  }
}
