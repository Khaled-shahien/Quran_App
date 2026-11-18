import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/services/alert_health.dart';
import 'package:sakina_app/core/services/diagnostics_log.dart';
import 'package:sakina_app/core/services/notification_permission_service.dart';
import 'package:sakina_app/core/services/workmanager_service.dart';
import 'package:sakina_app/features/settings/presentation/screens/alert_health_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

const Map<String, Object> _configured = {
  'prayer_latitude': 30.0,
  'prayer_longitude': 31.0,
};

AlertHealthChecker _checker(
  SharedPreferences prefs, {
  NotificationPermissionStatus status = NotificationPermissionStatus.granted,
  bool? exact = true,
  bool? battery = true,
  List<int> pending = const [2011, 2021, 3011, 1001, 4001],
  bool throws = false,
}) => AlertHealthChecker(
  prefs: prefs,
  notificationStatus: () async => throws ? throw StateError('plugin') : status,
  exactAlarms: () async => throws ? throw StateError('plugin') : exact,
  pendingIds: () async => throws ? throw StateError('plugin') : pending,
  batteryUnrestricted: () async => battery,
);

void main() {
  test('a configured device with everything allowed is healthy', () async {
    final snapshot = await _checker(await _prefs(_configured)).check();
    expect(snapshot.healthy, isTrue);
    expect(snapshot.pendingPrayerAlerts, 3, reason: 'only prayer IDs count');
  });

  test('each problem is reported, most serious first', () async {
    final prefs = await _prefs({
      ..._configured,
      kLastBackgroundRescheduleAtMsKey: DateTime(
        2026,
        11,
        1,
      ).millisecondsSinceEpoch,
      DiagnosticsLog.backgroundErrorAtKey: DateTime.utc(
        2026,
        11,
        2,
      ).toIso8601String(),
    });
    final snapshot = await _checker(
      prefs,
      status: NotificationPermissionStatus.permanentlyDenied,
      exact: false,
      battery: false,
      pending: const [],
    ).check();
    expect(snapshot.issues, [
      AlertHealthIssue.notificationsOff,
      AlertHealthIssue.exactAlarmsOff,
      AlertHealthIssue.batteryRestricted,
      AlertHealthIssue.backgroundFailing,
    ]);
  });

  test('nothing scheduled is reported only when it should have been', () async {
    final on = await _checker(
      await _prefs(_configured),
      pending: const [],
    ).check();
    expect(on.issues, [AlertHealthIssue.nothingScheduled]);

    final off = await _checker(
      await _prefs({..._configured, 'prayer_notifications_enabled': false}),
      pending: const [],
    ).check();
    expect(off.issues, [AlertHealthIssue.prayerAlertsDisabled]);

    final noPlace = await _checker(await _prefs({}), pending: const []).check();
    expect(noPlace.issues, [AlertHealthIssue.noLocation]);
  });

  test('a later success clears an older background error', () async {
    final prefs = await _prefs({
      ..._configured,
      DiagnosticsLog.backgroundErrorAtKey: DateTime.utc(
        2026,
        11,
        1,
      ).toIso8601String(),
      kLastBackgroundRescheduleAtMsKey: DateTime(
        2026,
        11,
        3,
      ).millisecondsSinceEpoch,
    });
    expect((await _checker(prefs).check()).healthy, isTrue);
  });

  test('failing platform reads are unknown, not crashes', () async {
    final snapshot = await _checker(
      await _prefs(_configured),
      throws: true,
      battery: null,
    ).check();
    expect(snapshot.notifications, NotificationPermissionStatus.unsupported);
    expect(snapshot.exactAlarms, isNull);
    expect(snapshot.issues, [AlertHealthIssue.nothingScheduled]);
  });

  testWidgets('the screen lists problems with their fixes', (tester) async {
    final prefs = await _prefs(_configured);
    await tester.pumpWidget(
      Provider<SharedPreferences>.value(
        value: prefs,
        child: MaterialApp(
          home: AlertHealthScreen(
            checker: _checker(prefs, exact: false, battery: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('وُجد ما قد يمنع وصول التنبيهات (2)'), findsOneWidget);
    expect(find.text('قد تتأخر التنبيهات'), findsOneWidget);
    expect(find.text('توفير البطارية يقيّد سكينة'), findsOneWidget);
    expect(find.text('تنبيهات صلاة جاهزة في النظام الآن: 3'), findsOneWidget);
  });

  testWidgets('a healthy device says so', (tester) async {
    final prefs = await _prefs(_configured);
    await tester.pumpWidget(
      Provider<SharedPreferences>.value(
        value: prefs,
        child: MaterialApp(home: AlertHealthScreen(checker: _checker(prefs))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('كل شيء جاهز لوصول التنبيهات في وقتها'), findsOneWidget);
  });
}
