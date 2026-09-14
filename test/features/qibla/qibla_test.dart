import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina_app/features/qibla/data/qibla_device_service.dart';
import 'package:sakina_app/features/qibla/domain/qibla_direction.dart';
import 'package:sakina_app/features/qibla/presentation/qibla_controller.dart';
import 'package:sakina_app/features/qibla/presentation/screens/qibla_screen.dart';

class FakeQiblaDevice extends QiblaDeviceService {
  bool enabled = true;
  bool supported = true;
  bool settingsOpened = false;
  int requests = 0;
  LocationPermission access = LocationPermission.whileInUse;
  Completer<Position>? pendingPosition;
  final readings = StreamController<QiblaHeading>.broadcast();
  @override
  bool get isSupported => supported;
  @override
  Future<bool> locationEnabled() async => enabled;
  @override
  Future<LocationPermission> permission() async => access;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return access;
  }

  @override
  Future<bool> openLocationSettings() async => settingsOpened = true;
  @override
  Future<bool> openAppSettings() async => settingsOpened = true;
  @override
  Future<Position> currentPosition() async => pendingPosition == null
      ? Position(
          latitude: 30.0444,
          longitude: 31.2357,
          timestamp: DateTime(2026),
          accuracy: 5,
          altitude: 20,
          altitudeAccuracy: 5,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        )
      : pendingPosition!.future;
  @override
  Stream<QiblaHeading> headings(Position position) => readings.stream;
}

void main() {
  group('Qibla calculation', () {
    test('bearings from cities in different hemispheres', () {
      expect(qiblaBearing(30.0444, 31.2357), closeTo(136.14, .1));
      expect(qiblaBearing(51.5074, -.1278), closeTo(118.99, .1));
      expect(qiblaBearing(40.7128, -74.0060), closeTo(58.48, .1));
      expect(qiblaBearing(-6.2088, 106.8456), closeTo(295.15, .1));
    });
    test('takes the short turn across north in both directions', () {
      expect(qiblaTurn(1, 359), 2);
      expect(qiblaTurn(359, 1), -2);
      expect(qiblaTurn(136, 136), 0);
      expect(qiblaTurn(136, 100), 36);
    });
  });

  late FakeQiblaDevice device;
  late QiblaController controller;
  setUp(() {
    device = FakeQiblaDevice();
    controller = QiblaController(device: device);
  });
  tearDown(() async {
    controller.dispose();
    await device.readings.close();
  });

  test(
    'location disabled offers settings without requesting permission',
    () async {
      device.enabled = false;
      await controller.start();
      expect(controller.status, QiblaStatus.locationOff);
      expect(device.requests, 0);
      await controller.openSettings();
      expect(device.settingsOpened, isTrue);
    },
  );
  test('denied and permanently denied permissions are distinct', () async {
    device.access = LocationPermission.denied;
    await controller.start();
    expect(controller.status, QiblaStatus.denied);
    expect(device.requests, 1);
    device.access = LocationPermission.deniedForever;
    await controller.start();
    expect(controller.status, QiblaStatus.deniedForever);
    expect(device.requests, 1);
  });
  test(
    'resume does not automatically prompt again for denied permission',
    () async {
      device.access = LocationPermission.denied;
      await controller.start(requestPermission: false);
      expect(device.requests, 0);
      expect(controller.status, QiblaStatus.denied);
    },
  );
  test(
    'alignment requires a calibrated sensor and clears on sensor error',
    () async {
      await controller.start();
      expect(controller.status, QiblaStatus.ready);
      device.readings.add(QiblaHeading(controller.bearing!));
      await Future<void>.delayed(Duration.zero);
      expect(controller.aligned, isTrue);
      device.readings.add(
        QiblaHeading(controller.bearing!, needsCalibration: true),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.aligned, isFalse);
      device.readings.addError(Exception('No sensor'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.sensorUnavailable, isTrue);
      expect(controller.heading, isNull);
      expect(controller.bearing, isNotNull);
    },
  );
  test('pause cancels sensor subscription', () async {
    await controller.start();
    expect(device.readings.hasListener, isTrue);
    controller.pause();
    expect(device.readings.hasListener, isFalse);
    expect(controller.heading, isNull);
  });
  test('ignores a location response after leaving the screen', () async {
    final position = await device.currentPosition();
    device.pendingPosition = Completer<Position>();
    final start = controller.start();
    await Future<void>.delayed(Duration.zero);
    controller.pause();
    device.pendingPosition!.complete(position);
    await start;
    expect(device.readings.hasListener, isFalse);
    expect(controller.bearing, isNull);
  });
  test('location timeout is recoverable', () async {
    device.pendingPosition = Completer<Position>();
    final start = controller.start();
    await Future<void>.delayed(Duration.zero);
    device.pendingPosition!.completeError(TimeoutException('No GPS fix'));
    await start;
    expect(controller.status, QiblaStatus.locationError);
    device.pendingPosition = null;
    await controller.start();
    expect(controller.status, QiblaStatus.ready);
  });
  testWidgets('settings action and retry recover from disabled location', (
    tester,
  ) async {
    device.enabled = false;
    await tester.pumpWidget(
      MaterialApp(home: QiblaScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    expect(find.text('خدمة الموقع متوقفة'), findsOneWidget);
    await tester.tap(find.text('فتح الإعدادات'));
    await tester.pump();
    expect(device.settingsOpened, isTrue);
    device.enabled = true;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    await tester.pump();
    device.readings.add(QiblaHeading(controller.bearing!));
    await tester.pumpAndSettle();
    expect(find.text('أنت باتجاه القبلة'), findsOneWidget);
    expect(find.byType(QiblaDial), findsOneWidget);
  });
  testWidgets('missing sensor preserves numeric bearing without a fake arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: QiblaScreen(controller: controller)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('تعذّرت قراءة البوصلة'), findsOneWidget);
    expect(find.byType(QiblaDial), findsNothing);
    expect(find.textContaining('من الشمال الجغرافي'), findsOneWidget);
  });
  testWidgets('small screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: QiblaScreen(controller: controller),
      ),
    );
    await tester.pump();
    device.readings.add(const QiblaHeading(0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
