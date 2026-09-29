import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(NotificationProvider, FakeLocalNotificationGateway)> buildProvider({
    FakeLocalNotificationGateway? localGateway,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'morning_alarm_enabled': true,
      'evening_alarm_enabled': true,
      'mulk_alarm_enabled': true,
      'baqarah_alarm_enabled': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final local = localGateway ?? FakeLocalNotificationGateway();

    final provider = NotificationProvider(
      prefs: prefs,
      notificationGateway: local,
    );
    return (provider, local);
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
    expect(find.textContaining('FCM'), findsNothing);
    expect(find.byIcon(Icons.copy), findsNothing);
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

  testWidgets('requests local permission only after explicit action', (
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

    expect(local.requestPermissionsCalls, 0);
    await tester.tap(find.text('طلب الصلاحيات'));
    await tester.pumpAndSettle();

    expect(local.requestPermissionsCalls, 1);
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
