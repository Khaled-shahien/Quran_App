import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina_app/core/providers/notification_provider.dart';
import 'package:sakina_app/core/services/notification_facades.dart';
import 'package:sakina_app/features/settings/presentation/screens/notification_test_screen.dart';

class FakeLocalNotificationGateway implements LocalNotificationGateway {
  FakeLocalNotificationGateway({
    this.throwOnTestNotification = false,
    this.throwOnDelayedNotification = false,
    this.throwOnUpdateAll = false,
  });

  final bool throwOnTestNotification;
  final bool throwOnDelayedNotification;
  final bool throwOnUpdateAll;

  int requestPermissionsCalls = 0;
  int testNotificationCalls = 0;
  int delayedNotificationCalls = 0;
  int cancelAllCalls = 0;
  int updateAllAlarmsCalls = 0;
  int getPendingNotificationsCalls = 0;

  final List<PendingNotificationRequest> _pending =
      <PendingNotificationRequest>[
        const PendingNotificationRequest(
          101,
          'تنبيه مجدول',
          'رسالة مجدولة',
          'p1',
        ),
      ];

  @override
  Future<void> initialize({bool requestPermissions = false}) async {}

  @override
  Future<void> requestPermissions() async {
    requestPermissionsCalls++;
  }

  @override
  Future<void> testNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (throwOnTestNotification) {
      throw Exception('test notification failed');
    }
    testNotificationCalls++;
  }

  @override
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    if (throwOnDelayedNotification) {
      throw Exception('delayed scheduling failed');
    }
    delayedNotificationCalls++;
    _pending.add(PendingNotificationRequest(id, title, body, payload));
  }

  @override
  Future<void> cancelNotification(int id) async {
    _pending.removeWhere((n) => n.id == id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCalls++;
    _pending.clear();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    getPendingNotificationsCalls++;
    return List<PendingNotificationRequest>.from(_pending);
  }

  @override
  Future<void> updateAllAlarms({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {
    if (throwOnUpdateAll) {
      throw Exception('reschedule failed');
    }
    updateAllAlarmsCalls++;
  }
}

class FakeMessagingGateway implements MessagingGateway {
  FakeMessagingGateway({this.token = 'fake-fcm-token'});

  int refreshCalls = 0;
  final String? token;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getToken() async => token;

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    throw Exception('not needed for this widget test');
  }

  @override
  Future<void> refreshToken() async {
    refreshCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    (NotificationProvider, FakeLocalNotificationGateway, FakeMessagingGateway)
  >
  buildProvider({
    FakeLocalNotificationGateway? localGateway,
    FakeMessagingGateway? messagingGateway,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'morning_alarm_enabled': true,
      'evening_alarm_enabled': true,
      'mulk_alarm_enabled': true,
      'baqarah_alarm_enabled': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final local = localGateway ?? FakeLocalNotificationGateway();
    final messaging = messagingGateway ?? FakeMessagingGateway();

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: local,
      messagingGateway: messaging,
    );
    return (provider, local, messaging);
  }

  testWidgets('renders all main notification sections', (tester) async {
    final tuple = await buildProvider();
    final provider = tuple.$1;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('اختبار الإشعارات'), findsOneWidget);
    expect(find.text('حالة الصلاحيات'), findsOneWidget);
    expect(find.text('الإشعارات المحلية'), findsOneWidget);
    expect(find.text('إشعارات الدفع (FCM)'), findsOneWidget);
    expect(find.text('الإشعارات المجدولة'), findsOneWidget);
    expect(find.text('التحكم في المنبهات'), findsOneWidget);
    expect(find.text('سجلات التصحيح'), findsOneWidget);
  });

  testWidgets('executes local notification actions', (tester) async {
    final tuple = await buildProvider();
    final provider = tuple.$1;
    final local = tuple.$2;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('إشعار فوري'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إشعار بعد دقيقة'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إلغاء الكل'));
    await tester.pumpAndSettle();

    expect(local.testNotificationCalls, 1);
    expect(local.delayedNotificationCalls, 1);
    expect(local.cancelAllCalls, 1);
  });

  testWidgets('renders pending notifications and supports alarm reschedule', (
    tester,
  ) async {
    final tuple = await buildProvider();
    final provider = tuple.$1;
    final local = tuple.$2;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تنبيه مجدول'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('إعادة جدولة جميع المنبهات'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('إعادة جدولة جميع المنبهات'));
    await tester.pumpAndSettle();

    expect(local.updateAllAlarmsCalls, 1);
  });

  testWidgets('requests permission and refreshes token from push section', (
    tester,
  ) async {
    final tuple = await buildProvider();
    final provider = tuple.$1;
    final local = tuple.$2;
    final messaging = tuple.$3;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('طلب الصلاحيات'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('رمز FCM:'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('تحديث').first);
    await tester.pumpAndSettle();

    expect(local.requestPermissionsCalls, 1);
    expect(messaging.refreshCalls, 1);
  });

  testWidgets('can cancel a single pending notification from list', (
    tester,
  ) async {
    final tuple = await buildProvider();
    final provider = tuple.$1;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تنبيه مجدول'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cancel).first);
    await tester.pumpAndSettle();

    expect(find.text('تنبيه مجدول'), findsNothing);
  });

  testWidgets('shows error snackbar when immediate test notification fails', (
    tester,
  ) async {
    final tuple = await buildProvider(
      localGateway: FakeLocalNotificationGateway(throwOnTestNotification: true),
    );
    final provider = tuple.$1;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('إشعار فوري'));
    await tester.pumpAndSettle();

    expect(find.textContaining('فشل الاختبار'), findsOneWidget);
  });

  testWidgets('shows scheduling error when delayed notification fails', (
    tester,
  ) async {
    final tuple = await buildProvider(
      localGateway: FakeLocalNotificationGateway(
        throwOnDelayedNotification: true,
      ),
    );
    final provider = tuple.$1;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('إشعار بعد دقيقة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('فشل الجدولة'), findsOneWidget);
  });

  testWidgets('handles reschedule failure path without crashing', (
    tester,
  ) async {
    final tuple = await buildProvider(
      localGateway: FakeLocalNotificationGateway(throwOnUpdateAll: true),
    );
    final provider = tuple.$1;
    final local = tuple.$2;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('إعادة جدولة جميع المنبهات'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('إعادة جدولة جميع المنبهات'));
    await tester.pumpAndSettle();

    expect(find.textContaining('تم إعادة جدولة جميع المنبهات'), findsOneWidget);
    expect(local.updateAllAlarmsCalls, 0);
  });

  testWidgets('copies FCM token to clipboard and shows success snackbar', (
    tester,
  ) async {
    final clipboardCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(call);
          }
          return null;
        });

    final tuple = await buildProvider();
    final provider = tuple.$1;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('نسخ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('نسخ'));
    await tester.pumpAndSettle();

    expect(clipboardCalls, hasLength(1));
    expect(
      clipboardCalls.single.arguments,
      containsPair('text', 'fake-fcm-token'),
    );
    expect(find.text('تم نسخ الرمز'), findsOneWidget);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('does not copy token when FCM token is unavailable', (
    tester,
  ) async {
    final clipboardCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardCalls.add(call);
          }
          return null;
        });

    final tuple = await buildProvider(
      messagingGateway: FakeMessagingGateway(token: null),
    );
    final provider = tuple.$1;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('نسخ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('نسخ'));
    await tester.pumpAndSettle();

    expect(clipboardCalls, isEmpty);
    expect(find.text('تم نسخ الرمز'), findsNothing);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('refresh button in pending section reloads scheduled list', (
    tester,
  ) async {
    final tuple = await buildProvider();
    final provider = tuple.$1;
    final local = tuple.$2;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final before = local.getPendingNotificationsCalls;
    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, 'تحديث').last,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(TextButton, 'تحديث').last);
    await tester.pumpAndSettle();

    expect(local.getPendingNotificationsCalls, greaterThan(before));
    expect(find.text('تنبيه مجدول'), findsOneWidget);
  });

  testWidgets('clears debug logs from debug section action', (tester) async {
    final tuple = await buildProvider();
    final provider = tuple.$1;

    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationProvider>.value(
        value: provider,
        child: const MaterialApp(home: NotificationTestScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(provider.debugLogs, isNotEmpty);

    await tester.scrollUntilVisible(
      find.text('مسح'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('مسح'));
    await tester.pumpAndSettle();

    expect(provider.debugLogs, isEmpty);
  });
}
