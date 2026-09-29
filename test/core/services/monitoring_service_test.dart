import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/services/monitoring_gateway.dart';
import 'package:sakina_app/core/services/monitoring_service.dart';

class Gateway implements MonitoringGateway {
  final calls = <String>[];
  bool failEnable = false;
  bool failDisable = false;
  Completer<void>? enableWait;
  @override
  Future<void> setCrashCollection(bool enabled) async {
    calls.add('crash:$enabled');
    if (enabled) await enableWait?.future;
    if (!enabled && failDisable) throw StateError('SDK unavailable');
  }

  @override
  Future<void> setAnalyticsCollection(bool enabled) async {
    calls.add('analytics:$enabled');
    if (enabled && failEnable) throw StateError('SDK unavailable');
  }

  @override
  Future<void> deleteUnsentReports() async => calls.add('delete');
  @override
  Future<void> resetAnalyticsData() async => calls.add('reset');
  @override
  Future<void> logEvent(String name) async => calls.add('event:$name');
  @override
  Future<void> recordError(String type, StackTrace stack) async =>
      calls.add('error:$type');
}

class Preferences implements SharedPreferences {
  bool? consent;
  bool failOptIn = false;
  @override
  bool? getBool(String key) => consent;
  @override
  Future<bool> setBool(String key, bool value) async {
    if (value && failOptIn) return false;
    consent = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Gateway gateway;
  late Preferences prefs;
  late MonitoringService service;
  FlutterExceptionHandler? previousFlutter;
  bool Function(Object, StackTrace)? previousPlatform;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    previousFlutter = FlutterError.onError;
    previousPlatform = PlatformDispatcher.instance.onError;
    FlutterError.onError = (_) {};
    gateway = Gateway();
    prefs = Preferences();
    service = MonitoringService(gateway: gateway, configurationEnabled: true);
  });
  tearDown(() {
    FlutterError.onError = previousFlutter;
    PlatformDispatcher.instance.onError = previousPlatform;
    debugDefaultTargetPlatformOverride = null;
    service.dispose();
  });

  test(
    'default off disables both SDKs, clears pending data and sends no events',
    () async {
      await service.initialize(prefs);
      expect(service.enabled, isFalse);
      expect(
        gateway.calls,
        containsAll(['crash:false', 'analytics:false', 'delete', 'reset']),
      );
      await service.event('app_open');
      expect(gateway.calls.where((v) => v.startsWith('event:')), isEmpty);
    },
  );

  test(
    'unconfigured build never touches SDKs even with stored consent',
    () async {
      final disabled = MonitoringService(
        gateway: gateway,
        configurationEnabled: false,
      );
      prefs.consent = true;
      await disabled.initialize(prefs);
      expect(disabled.available, isFalse);
      expect(gateway.calls, isEmpty);
      disabled.dispose();
    },
  );

  test(
    'saved opt-in is restored once and only allowlisted events are sent',
    () async {
      prefs.consent = true;
      await service.initialize(prefs);
      await service.initialize(prefs);
      await service.event('settings_open');
      await service.event('query:private text');
      expect(service.enabled, isTrue);
      expect(gateway.calls.where((v) => v.startsWith('event:')).toList(), [
        'event:app_open',
        'event:settings_open',
      ]);
    },
  );

  test(
    'opt-out stops forwarding immediately and persists before SDK failures',
    () async {
      prefs.consent = true;
      await service.initialize(prefs);
      gateway.calls.clear();
      gateway.failDisable = true;
      final off = service.setEnabled(false);
      expect(service.enabled, isFalse);
      await service.event('settings_open');
      await expectLater(off, throwsStateError);
      expect(prefs.consent, isFalse);
      expect(
        gateway.calls,
        containsAll(['analytics:false', 'delete', 'reset']),
      );
      expect(gateway.calls.where((v) => v.startsWith('event:')), isEmpty);
    },
  );

  test(
    'partial SDK opt-in failure rolls both SDKs back and allows retry',
    () async {
      await service.initialize(prefs);
      gateway.failEnable = true;
      await expectLater(service.setEnabled(true), throwsStateError);
      expect(service.enabled, isFalse);
      expect(prefs.consent, isFalse);
      expect(gateway.calls, containsAll(['crash:false', 'analytics:false']));
      gateway.failEnable = false;
      await service.setEnabled(true);
      expect(service.enabled, isTrue);
    },
  );

  test('false preference write cannot be reported as a saved opt-in', () async {
    await service.initialize(prefs);
    prefs.failOptIn = true;
    await expectLater(service.setEnabled(true), throwsStateError);
    expect(service.enabled, isFalse);
    expect(prefs.consent, isFalse);
    expect(gateway.calls.last, 'reset');
  });

  test('late opt-in cannot override a newer opt-out', () async {
    await service.initialize(prefs);
    gateway.enableWait = Completer<void>();
    final on = service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    final off = service.setEnabled(false);
    gateway.enableWait!.complete();
    await Future.wait([on, off]);
    expect(service.enabled, isFalse);
    expect(prefs.consent, isFalse);
    expect(gateway.calls.last, 'reset');
  });

  test('error forwarding redacts messages and stops after opt-out', () async {
    prefs.consent = true;
    await service.initialize(prefs);
    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('private query and coordinates'),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(gateway.calls, contains('error:StateError'));
    expect(gateway.calls.join(), isNot(contains('private')));
    await service.setEnabled(false);
    gateway.calls.clear();
    FlutterError.onError!(
      FlutterErrorDetails(exception: StateError('private')),
    );
    await Future<void>.delayed(Duration.zero);
    expect(gateway.calls, isEmpty);
  });
}
