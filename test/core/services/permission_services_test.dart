import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakina_app/core/services/location_access_service.dart';
import 'package:sakina_app/core/services/notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/permission_fakes.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('NotificationPermissionService', () {
    NotificationPermissionService service(FakeNotificationPlatform platform) =>
        NotificationPermissionService(prefs: prefs, platform: platform);

    test('reads "allowed" from the system, not from a stored answer', () async {
      final platform = FakeNotificationPlatform(enabled: true);
      expect(
        await service(platform).status(),
        NotificationPermissionStatus.granted,
      );
      // Turned off in system settings later.
      platform.enabled = false;
      await prefs.setBool(NotificationPermissionService.requestedKey, true);
      expect(
        await service(platform).status(),
        NotificationPermissionStatus.permanentlyDenied,
      );
    });

    test('tells "never asked" from "refused"', () async {
      final platform = FakeNotificationPlatform(rationale: true);
      expect(
        await service(platform).status(),
        NotificationPermissionStatus.notRequested,
      );
      await prefs.setBool(NotificationPermissionService.requestedKey, true);
      // Android 13+ after one refusal: the dialog can still be shown.
      expect(
        await service(platform).status(),
        NotificationPermissionStatus.denied,
      );
    });

    test('Android without a rationale and iOS after a refusal need '
        'settings', () async {
      await prefs.setBool(NotificationPermissionService.requestedKey, true);
      expect(
        await service(FakeNotificationPlatform(rationale: false)).status(),
        NotificationPermissionStatus.permanentlyDenied,
      );
      expect(
        await service(FakeNotificationPlatform(rationale: null)).status(),
        NotificationPermissionStatus.permanentlyDenied,
      );
    });

    test('an unavailable plugin reads as unsupported, never throws', () async {
      expect(
        await service(FakeNotificationPlatform(throwOnCheck: true)).status(),
        NotificationPermissionStatus.unsupported,
      );
      expect(
        await service(FakeNotificationPlatform(enabled: null)).status(),
        NotificationPermissionStatus.unsupported,
      );
    });

    test('request asks the system once and reports the real result', () async {
      final platform = FakeNotificationPlatform(grantOnRequest: true);
      final result = await service(platform).request();
      expect(result, NotificationPermissionStatus.granted);
      expect(platform.requests, 1);
      expect(prefs.getBool(NotificationPermissionService.requestedKey), true);
    });

    test('a refusal on request is reported as such', () async {
      final platform = FakeNotificationPlatform(rationale: true);
      expect(
        await service(platform).request(),
        NotificationPermissionStatus.denied,
      );
    });

    test('never shows the system dialog when it is already allowed or only '
        'settings can allow it', () async {
      final allowed = FakeNotificationPlatform(enabled: true);
      await service(allowed).request();
      expect(allowed.requests, 0);

      await prefs.setBool(NotificationPermissionService.requestedKey, true);
      final blocked = FakeNotificationPlatform(rationale: false);
      expect(
        await service(blocked).request(),
        NotificationPermissionStatus.permanentlyDenied,
      );
      expect(blocked.requests, 0);
    });

    test('opens the system settings page', () async {
      final platform = FakeNotificationPlatform();
      expect(await service(platform).openSettings(), isTrue);
      expect(platform.settingsOpened, 1);
    });
  });

  group('LocationAccessService', () {
    LocationAccessService service(FakeLocationPlatform platform) =>
        LocationAccessService(platform: platform, prefs: prefs);

    test('maps system permission states', () async {
      final platform = FakeLocationPlatform();
      expect(
        await service(platform).status(),
        LocationAccessStatus.notRequested,
      );
      await prefs.setBool(LocationAccessService.requestedKey, true);
      expect(await service(platform).status(), LocationAccessStatus.denied);
      platform.permission = LocationPermission.deniedForever;
      expect(
        await service(platform).status(),
        LocationAccessStatus.permanentlyDenied,
      );
      platform.permission = LocationPermission.whileInUse;
      expect(await service(platform).status(), LocationAccessStatus.granted);
      platform.servicesEnabled = false;
      expect(
        await service(platform).status(),
        LocationAccessStatus.servicesDisabled,
      );
      platform.supported = false;
      expect(
        await service(platform).status(),
        LocationAccessStatus.unsupported,
      );
    });

    test('requests foreground access once and records the request', () async {
      final platform = FakeLocationPlatform();
      expect(await service(platform).request(), LocationAccessStatus.granted);
      expect(platform.requests, 1);
      expect(prefs.getBool(LocationAccessService.requestedKey), isTrue);
      // Already granted: no second dialog.
      await service(platform).request();
      expect(platform.requests, 1);
    });

    test('a refusal right after the dialog reads as denied', () async {
      final platform = FakeLocationPlatform(
        resultOnRequest: LocationPermission.denied,
      );
      expect(await service(platform).request(), LocationAccessStatus.denied);
    });

    test('never re-asks after a permanent refusal', () async {
      final platform = FakeLocationPlatform(
        permission: LocationPermission.deniedForever,
      );
      expect(
        await service(platform).request(),
        LocationAccessStatus.permanentlyDenied,
      );
      expect(platform.requests, 0);
    });

    test('granted with location services off is reported', () async {
      final platform = FakeLocationPlatform(servicesEnabled: false);
      expect(
        await service(platform).request(),
        LocationAccessStatus.servicesDisabled,
      );
    });

    test('a silent lookup never shows a dialog', () async {
      final platform = FakeLocationPlatform();
      await expectLater(
        service(platform).currentFix(requestAccess: false),
        throwsA(
          isA<LocationAccessException>().having(
            (e) => e.status,
            'status',
            LocationAccessStatus.notRequested,
          ),
        ),
      );
      expect(platform.requests, 0);
      expect(platform.fixes, 0);
    });

    test('a lookup with access returns the validated fix', () async {
      final platform = FakeLocationPlatform(
        permission: LocationPermission.whileInUse,
      );
      final fix = await service(platform).currentFix(requestAccess: false);
      expect(fix.latitude, 30.0444);
      expect(platform.fixes, 1);
    });

    test('opens the settings page that can fix the problem', () async {
      final platform = FakeLocationPlatform();
      await service(
        platform,
      ).openSettings(LocationAccessStatus.servicesDisabled);
      await service(
        platform,
      ).openSettings(LocationAccessStatus.permanentlyDenied);
      expect(platform.locationSettingsOpened, 1);
      expect(platform.appSettingsOpened, 1);
    });
  });
}
