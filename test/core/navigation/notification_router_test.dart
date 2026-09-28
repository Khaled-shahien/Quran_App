import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/navigation/notification_router.dart';

void main() {
  tearDown(NotificationRouter.clearNavigationCallback);
  test('khatma reminder resolves to canonical destination', () {
    String? destination;
    NotificationRouter.setNavigationCallback((route, _) => destination = route);
    NotificationRouter.handleNotification(type: 'khatma');
    expect(destination, '/khatma');
  });
  test('untrusted data cannot replace a fixed surah destination', () {
    Map<String, dynamic>? payload;
    NotificationRouter.setNavigationCallback((_, data) => payload = data);
    NotificationRouter.handleNotification(
      type: 'mulk_surah',
      data: {'surahNumber': -1},
    );
    expect(payload?['surahNumber'], 67);
  });
}
