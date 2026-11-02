import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/navigation/notification_router.dart';
import 'package:sakina_app/core/services/notification_service.dart';

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
    NotificationService.routeLaunchDetails(
      details(true, jsonEncode({'type': 'khatma'})),
    );
    expect(routes, ['/khatma']);
  });

  test('a normal launch does not navigate', () {
    NotificationService.routeLaunchDetails(details(false, 'prayer_time'));
    NotificationService.routeLaunchDetails(null);
    expect(routes, isEmpty);
  });

  test('plain, empty and malformed payloads stay safe', () {
    NotificationService.routeNotificationPayload('prayer_time');
    NotificationService.routeNotificationPayload(null);
    NotificationService.routeNotificationPayload('{not json');
    expect(routes, ['/prayers', '/', '/']);
  });
}
