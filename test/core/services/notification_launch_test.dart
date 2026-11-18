import 'package:sakina_app/core/services/notification_tap_routing.dart';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/navigation/notification_router.dart';

void main() {
  late List<String> routes;

  setUp(() {
    routes = [];
    NotificationRouter.setNavigationCallback((route, _) => routes.add(route));
  });
  tearDown(NotificationRouter.clearNavigationCallback);

  NotificationAppLaunchDetails details(bool launched, String? payload) =>
      NotificationAppLaunchDetails(
        launched,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: payload,
        ),
      );

  test('routes the notification that launched the app', () {
    NotificationTapRouting.routeLaunchDetails(
      details(true, jsonEncode({'type': 'khatma'})),
    );
    expect(routes, ['/khatma']);
  });

  test('a normal launch does not navigate', () {
    NotificationTapRouting.routeLaunchDetails(details(false, 'prayer_time'));
    NotificationTapRouting.routeLaunchDetails(null);
    expect(routes, isEmpty);
  });

  test('plain, empty and malformed payloads stay safe', () {
    NotificationTapRouting.routeNotificationPayload('prayer_time');
    NotificationTapRouting.routeNotificationPayload(null);
    NotificationTapRouting.routeNotificationPayload('{not json');
    expect(routes, ['/prayers', '/', '/']);
  });
}
