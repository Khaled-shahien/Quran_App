import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
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
  bool throwOnInitialize = false;
  bool? initializationRequestedPermissions;
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
    initializationRequestedPermissions = requestPermissions;
    if (throwOnInitialize) throw Exception('initialization failed');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'NotificationProvider initializes locally without Firebase or permission prompts',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifications = FakeLocalNotificationGateway();

      final provider = NotificationProvider(
        prefs: prefs,
        notificationGateway: notifications,
      );

      await provider.initialize();

      expect(provider.isInitialized, isTrue);
      expect(notifications.initializeCalls, 1);
      expect(notifications.initializationRequestedPermissions, isFalse);
      expect(notifications.requestPermissionCalls, 0);
      provider.dispose();
    },
  );

  test('failed local initialization can be retried without Firebase', () async {
    SharedPreferences.setMockInitialValues({});
    final notifications = FakeLocalNotificationGateway()
      ..throwOnInitialize = true;
    final provider = NotificationProvider(
      prefs: await SharedPreferences.getInstance(),
      notificationGateway: notifications,
    );
    addTearDown(provider.dispose);

    await provider.initialize();
    expect(provider.isInitialized, isFalse);
    expect(provider.debugLogs.join('\n'), contains('Error initializing'));

    notifications.throwOnInitialize = false;
    await provider.initialize();
    expect(provider.isInitialized, isTrue);
    expect(notifications.initializeCalls, 2);
    expect(notifications.requestPermissionCalls, 0);
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

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: notifications,
    );

    await provider.initialize();
    await provider.initialize();

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
    );

    await provider.cancelAllNotifications();

    expect(
      provider.debugLogs.join('\n'),
      contains('Error cancelling all notifications'),
    );
  });
}
