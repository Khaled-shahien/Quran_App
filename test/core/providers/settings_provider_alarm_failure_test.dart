import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/providers/settings_provider.dart';
import 'package:sakina_app/core/services/notification_scheduling_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingCoordinator extends NotificationSchedulingCoordinator {
  int attempts = 0;

  @override
  Future<void> syncFromSettings({
    required bool isMorningEnabled,
    required bool isEveningEnabled,
    required bool isMulkEnabled,
    required bool isBaqarahEnabled,
  }) async {
    attempts++;
    throw StateError('scheduling refused');
  }

  @override
  Future<void> requestReschedule(String source) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a scheduling failure keeps the choice and is not uncaught', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final coordinator = _FailingCoordinator();
    final provider = SettingsProvider(
      prefs: prefs,
      schedulingCoordinator: coordinator,
    );

    await provider.toggleMorningAlarm(true);
    await pumpEventQueue();

    // An uncaught async error would fail this test through its zone.
    expect(coordinator.attempts, 2);
    expect(provider.isMorningAlarmEnabled, isTrue);
    expect(prefs.getBool('morning_alarm_enabled'), isTrue);
  });
}
