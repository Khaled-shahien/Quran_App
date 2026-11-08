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
    if (enabled && failEnable) throw StateError('SDK unavailable');
    if (!enabled && failDisable) throw StateError('SDK unavailable');
  }

  @override
  Future<void> deleteUnsentReports() async => calls.add('delete');
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
    'default off disables crash collection and clears pending reports',
    () async {
      await service.initialize(prefs);
      expect(service.enabled, isFalse);
      expect(gateway.calls, containsAll(['crash:false', 'delete']));
      FlutterError.onError!(FlutterErrorDetails(exception: StateError('x')));
      await Future<void>.delayed(Duration.zero);
      expect(gateway.calls.where((v) => v.startsWith('error:')), isEmpty);
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

  test('saved opt-in is restored once', () async {
    prefs.consent = true;
    await service.initialize(prefs);
    await service.initialize(prefs);
    expect(service.enabled, isTrue);
    expect(gateway.calls.where((v) => v == 'crash:true').length, 1);
  });

  test(
    'opt-out stops forwarding immediately and persists before SDK failures',
    () async {
      prefs.consent = true;
      await service.initialize(prefs);
      gateway.calls.clear();
      gateway.failDisable = true;
      final off = service.setEnabled(false);
      expect(service.enabled, isFalse);
      FlutterError.onError!(FlutterErrorDetails(exception: StateError('x')));
      await expectLater(off, throwsStateError);
      expect(prefs.consent, isFalse);
      expect(gateway.calls, containsAll(['crash:false', 'delete']));
      expect(gateway.calls.where((v) => v.startsWith('error:')), isEmpty);
    },
  );

  test('failed SDK opt-in rolls back and allows retry', () async {
    await service.initialize(prefs);
    gateway.failEnable = true;
    gateway.calls.clear();
    await expectLater(service.setEnabled(true), throwsStateError);
    expect(service.enabled, isFalse);
    expect(prefs.consent, isFalse);
    expect(gateway.calls, containsAll(['crash:false', 'delete']));
    gateway.failEnable = false;
    await service.setEnabled(true);
    expect(service.enabled, isTrue);
  });

  test('false preference write cannot be reported as a saved opt-in', () async {
    await service.initialize(prefs);
    prefs.failOptIn = true;
    await expectLater(service.setEnabled(true), throwsStateError);
    expect(service.enabled, isFalse);
    expect(prefs.consent, isFalse);
    expect(gateway.calls.last, 'delete');
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
    expect(gateway.calls.last, 'delete');
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
