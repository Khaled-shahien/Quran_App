import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/workmanager_service.dart';

/// Static checks only. They keep native files aligned with Dart and do not
/// show that reboot or background behavior works on a device.
void main() {
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final bootReceiver = File(
    'android/app/src/main/kotlin/app/sakina/quran/BootReceiver.kt',
  ).readAsStringSync();

  test('iOS permits and registers the periodic reschedule task', () {
    expect(infoPlist, contains('BGTaskSchedulerPermittedIdentifiers'));
    expect(infoPlist, contains(kRescheduleAlarmsPeriodicUniqueName));
    expect(appDelegate, contains('"$kRescheduleAlarmsPeriodicUniqueName"'));
  });

  test('iOS registers plugins once, through the implicit engine', () {
    expect(appDelegate, isNot(contains('register(with: self)')));
    expect(appDelegate, contains('engineBridge.pluginRegistry'));
  });

  test('boot receiver uses plugin constants and the Dart task name', () {
    expect(bootReceiver, isNot(contains('be.tramckrijte')));
    expect(bootReceiver, contains('BackgroundWorker.DART_TASK_KEY'));
    expect(bootReceiver, contains('"$kRescheduleAlarmsTaskName"'));
    expect(bootReceiver, contains('"$kRescheduleAlarmsOneOffUniqueName"'));
  });

  test('Android does not expose app UI over the lock screen', () {
    expect(manifest, isNot(contains('showWhenLocked')));
    expect(manifest, isNot(contains('turnScreenOn')));
  });

  test('boot receiver is not exported', () {
    final receiver = RegExp(
      r'<receiver[^>]*\.BootReceiver[^>]*>',
    ).firstMatch(manifest)!.group(0)!;
    expect(receiver, contains('android:exported="false"'));
  });
}
