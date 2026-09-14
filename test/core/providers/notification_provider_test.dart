import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/core/providers/notification_provider.dart';
import 'package:sakina_app/core/services/notification_facades.dart';

class FakeLocalNotificationGateway implements LocalNotificationGateway {
  FakeLocalNotificationGateway({
    List<PendingNotificationRequest>? pending,
    this.throwOnUpdateAll = false,
    this.throwOnCancelAll = false,
  }) : _pending = pending ?? <PendingNotificationRequest>[];

  int initializeCalls = 0;
  int requestPermissionCalls = 0;
  int testNotificationCalls = 0;
  int oneTimeScheduleCalls = 0;
  int cancelCalls = 0;
  int cancelAllCalls = 0;
  int updateAllAlarmsCalls = 0;
  final bool throwOnUpdateAll;
  final bool throwOnCancelAll;
  final List<PendingNotificationRequest> _pending;

  @override
  Future<void> cancelAllNotifications() async {
    if (throwOnCancelAll) {
      throw Exception('cancel all failed');
    }
    cancelAllCalls++;
    _pending.clear();
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelCalls++;
    _pending.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return List<PendingNotificationRequest>.from(_pending);
  }

  @override
  Future<void> initialize({bool requestPermissions = false}) async {
    initializeCalls++;
  }

  @override
  Future<void> requestPermissions() async {
    requestPermissionCalls++;
  }

  @override
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    oneTimeScheduleCalls++;
    _pending.add(PendingNotificationRequest(id, title, body, payload));
  }

  @override
  Future<void> testNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    testNotificationCalls++;
  }

  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {
    if (throwOnUpdateAll) {
      throw Exception('update alarms failed');
    }
    updateAllAlarmsCalls++;
  }
}

class FakeMessagingGateway implements MessagingGateway {
  FakeMessagingGateway({this.initialToken = 'token-123', this.refreshedToken});

  int initializeCalls = 0;
  int refreshTokenCalls = 0;
  final String? initialToken;
  final String? refreshedToken;
  String? _token;

  @override
  Future<String?> getToken() async {
    _token ??= initialToken;
    return _token;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    throw Exception('not needed in this test context');
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> refreshToken() async {
    refreshTokenCalls++;
    _token = refreshedToken ?? initialToken;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NotificationProvider initializes with injected gateways', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = FakeLocalNotificationGateway();
    final messaging = FakeMessagingGateway();

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: notifications,
      messagingGateway: messaging,
    );

    await provider.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(provider.isInitialized, isTrue);
    expect(notifications.initializeCalls, 1);
    expect(messaging.initializeCalls, greaterThanOrEqualTo(1));
    expect(provider.fcmToken, 'token-123');
  });

  test(
    'NotificationProvider schedules notifications without platform plugins',
    () async {
      SharedPreferences.setMockInitialValues({
        'morning_alarm_enabled': true,
        'evening_alarm_enabled': false,
        'mulk_alarm_enabled': false,
        'baqarah_alarm_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final notifications = FakeLocalNotificationGateway();

      final provider = NotificationProvider(
        prefs: prefs,
        notificationGateway: notifications,
        messagingGateway: FakeMessagingGateway(),
      );

      await provider.scheduleTestNotification(id: 1, title: 't', body: 'b');
      await provider.scheduleDelayedNotification(
        id: 2,
        title: 't2',
        body: 'b2',
      );
      await provider.rescheduleAllAlarms();

      expect(notifications.testNotificationCalls, 1);
      expect(notifications.oneTimeScheduleCalls, 1);
      expect(notifications.updateAllAlarmsCalls, 1);
    },
  );

  test('initialize is idempotent when called multiple times', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = FakeLocalNotificationGateway();
    final messaging = FakeMessagingGateway();

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: notifications,
      messagingGateway: messaging,
    );

    await provider.initialize();
    await provider.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(provider.isInitialized, isTrue);
    expect(notifications.initializeCalls, 1);
  });

  test('maps pending notifications and supports single cancel', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = FakeLocalNotificationGateway(
      pending: <PendingNotificationRequest>[
        const PendingNotificationRequest(7, 'عنوان', 'محتوى', 'p7'),
      ],
    );

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: notifications,
      messagingGateway: FakeMessagingGateway(),
    );

    final first = await provider.getPendingNotifications();
    expect(first, hasLength(1));
    expect(first.first['id'], 7);
    expect(first.first['title'], 'عنوان');

    await provider.cancelNotification(7);
    final second = await provider.getPendingNotifications();
    expect(notifications.cancelCalls, 1);
    expect(second, isEmpty);
  });

  test('refreshFCMToken requests refresh and updates token value', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final messaging = FakeMessagingGateway(
      initialToken: 'old-token',
      refreshedToken: 'new-token',
    );

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: FakeLocalNotificationGateway(),
      messagingGateway: messaging,
    );

    await provider.refreshFCMToken();

    expect(messaging.refreshTokenCalls, 1);
    expect(provider.fcmToken, 'new-token');
  });

  test('rescheduleAllAlarms swallows gateway errors safely', () async {
    SharedPreferences.setMockInitialValues({
      'morning_alarm_enabled': true,
      'evening_alarm_enabled': true,
      'mulk_alarm_enabled': true,
      'baqarah_alarm_enabled': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: FakeLocalNotificationGateway(throwOnUpdateAll: true),
      messagingGateway: FakeMessagingGateway(),
    );

    await provider.rescheduleAllAlarms();

    expect(
      provider.debugLogs.join('\n'),
      contains('Error rescheduling alarms'),
    );
  });

  test('cancelAllNotifications swallows gateway errors safely', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: FakeLocalNotificationGateway(throwOnCancelAll: true),
      messagingGateway: FakeMessagingGateway(),
    );

    await provider.cancelAllNotifications();

    expect(
      provider.debugLogs.join('\n'),
      contains('Error cancelling all notifications'),
    );
  });
}
