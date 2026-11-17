import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/services/location_access_service.dart';
import 'package:sakina_app/core/services/location_fix.dart';
import 'package:sakina_app/core/services/notification_permission_service.dart';
import 'package:sakina_app/core/theme/app_colors.dart';
import 'package:sakina_app/features/onboarding/presentation/screens/permission_onboarding_screen.dart';
import 'package:sakina_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sakina_app/features/prayers/domain/prayer_calculation_policy.dart';
import 'package:sakina_app/features/prayers/domain/prayer_city.dart';
import 'package:sakina_app/features/prayers/domain/prayer_location_source.dart';
import 'package:sakina_app/features/prayers/domain/repositories/prayer_times_repository.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/permission_fakes.dart';

class _Repository implements PrayerTimesRepository {
  @override
  Future<Result<PrayerTimesEntity>> getPrayerTimes(
    DateTime date,
    double latitude,
    double longitude, {
    int calculationMethod = PrayerCalculationPolicy.defaultMethod,
    AsrMadhab madhab = AsrMadhab.standard,
    String? timeZone,
  }) async => Success(
    PrayerTimesEntity(
      fajr: '05:00',
      sunrise: '06:20',
      dhuhr: '12:15',
      asr: '15:40',
      maghrib: '18:30',
      isha: '19:45',
      latitude: latitude,
      longitude: longitude,
    ),
  );
}

const _enableNotifications = 'تفعيل الإشعارات';
const _enableLocation = 'تفعيل الموقع';
const _notNow = 'ليس الآن';
const _continue = 'متابعة';
const _openSettings = 'فتح الإعدادات';
const _notificationsTitle = 'تنبيهات الصلاة في وقتها';
const _locationTitle = 'مواقيت دقيقة لمكانك';

void main() {
  late SharedPreferences prefs;
  late FakeNotificationPlatform notifications;
  late FakeLocationPlatform location;
  late FakeDeviceFixService device;
  late PrayerTimesProvider prayer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'permission_intro_pending': true});
    prefs = await SharedPreferences.getInstance();
    notifications = FakeNotificationPlatform(rationale: true);
    location = FakeLocationPlatform();
    device = FakeDeviceFixService(fakeFix());
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    prayer = PrayerTimesProvider(
      repository: _Repository(),
      preferences: prefs,
      deviceLocationService: device,
      nearestCity: (lat, lon) async => NearestCity.find(lat, lon, const [
        PrayerCity(
          name: 'القاهرة',
          country: 'مصر',
          englishName: 'Cairo',
          latitude: 30.06263,
          longitude: 31.24967,
        ),
      ]),
    );
    addTearDown(prayer.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => PermissionOnboardingScreen(
            notifications: NotificationPermissionService(
              prefs: prefs,
              platform: notifications,
            ),
            location: LocationAccessService(platform: location, prefs: prefs),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<PrayerTimesProvider>.value(
        value: prayer,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.lightPrimary,
              brightness: brightness,
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> returnToApp(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  group('display conditions', () {
    testWidgets('explains notifications first, then location', (tester) async {
      await pump(tester);
      expect(find.text(_notificationsTitle), findsOneWidget);
      expect(find.text('الخطوة 1 من 2'), findsOneWidget);
      expect(notifications.requests, 0, reason: 'no dialog before context');

      await tap(tester, _notNow);
      expect(find.text(_locationTitle), findsOneWidget);
      expect(find.text('الخطوة 2 من 2'), findsOneWidget);
    });

    testWidgets('"not now" on both asks nothing and enters the app', (
      tester,
    ) async {
      await pump(tester);
      await tap(tester, _notNow);
      await tap(tester, _notNow);

      expect(find.text('Home destination'), findsOneWidget);
      expect(notifications.requests, 0);
      expect(location.requests, 0);
      expect(prefs.getBool('has_seen_notification_permission'), isTrue);
      expect(prefs.getBool('location_intro_seen'), isTrue);
      expect(prefs.get('permission_intro_pending'), isNull);
    });

    testWidgets('notifications already allowed skip their step', (
      tester,
    ) async {
      notifications.enabled = true;
      await pump(tester);
      expect(find.text(_notificationsTitle), findsNothing);
      expect(find.text(_locationTitle), findsOneWidget);
      expect(find.textContaining('الخطوة'), findsNothing);
    });

    testWidgets('an answered prompt is never shown again', (tester) async {
      await prefs.setBool('has_seen_notification_permission', true);
      await prefs.setBool('location_intro_seen', true);
      await pump(tester);
      expect(find.text('Home destination'), findsOneWidget);
    });

    testWidgets('an existing location skips the location step', (tester) async {
      notifications.enabled = true;
      await prefs.setDouble('prayer_latitude', 30.0);
      await prefs.setDouble('prayer_longitude', 31.0);
      await pump(tester);
      expect(find.text('Home destination'), findsOneWidget);
      expect(prefs.get('permission_intro_pending'), isNull);
    });
  });

  group('notifications', () {
    testWidgets('allowing them continues to the location step', (tester) async {
      notifications.grantOnRequest = true;
      await pump(tester);
      await tap(tester, _enableNotifications);
      expect(notifications.requests, 1);
      expect(find.text(_locationTitle), findsOneWidget);
    });

    testWidgets('a refusal is explained and the app continues', (tester) async {
      await pump(tester);
      await tap(tester, _enableNotifications);
      expect(
        find.text('لم تُفعَّل الإشعارات، ويمكنك تفعيلها لاحقًا من الإعدادات.'),
        findsOneWidget,
      );
      expect(find.text(_enableNotifications), findsNothing);
      await tap(tester, _continue);
      expect(find.text(_locationTitle), findsOneWidget);
      expect(notifications.requests, 1);
    });

    testWidgets('a permanent refusal offers settings, never the dialog, and '
        'continues once allowed there', (tester) async {
      await prefs.setBool(NotificationPermissionService.requestedKey, true);
      notifications.rationale = false;
      await pump(tester);
      expect(find.textContaining('افتح الإعدادات واسمح'), findsOneWidget);

      await tap(tester, _openSettings);
      expect(notifications.settingsOpened, 1);
      expect(notifications.requests, 0);

      notifications.enabled = true; // allowed in system settings
      await returnToApp(tester);
      expect(find.text(_locationTitle), findsOneWidget);
    });
  });

  group('location', () {
    Future<void> toLocation(WidgetTester tester) async {
      notifications.enabled = true;
      await pump(tester);
      expect(find.text(_locationTitle), findsOneWidget);
    }

    testWidgets('allowing it locates and names the place', (tester) async {
      await toLocation(tester);
      await tap(tester, _enableLocation);

      expect(location.requests, 1);
      expect(device.requestAccessCalls, isNotEmpty);
      expect(find.text('موقع الصلاة: القاهرة، مصر'), findsOneWidget);
      expect(prayer.locationSource, PrayerLocationSource.device);
      expect(prefs.getDouble('prayer_latitude'), 30.0444);

      await tap(tester, _continue);
      expect(find.text('Home destination'), findsOneWidget);
    });

    testWidgets('a last-known position is shown as such', (tester) async {
      device.fix = fakeFix(source: LocationFixSource.staleCache);
      await toLocation(tester);
      await tap(tester, _enableLocation);
      expect(find.textContaining('آخر موقع معروف'), findsOneWidget);
    });

    testWidgets('a refusal offers the manual city choice', (tester) async {
      location.resultOnRequest = LocationPermission.denied;
      await toLocation(tester);
      await tap(tester, _enableLocation);
      expect(
        find.textContaining('لم يُسمح بالوصول إلى الموقع'),
        findsOneWidget,
      );
      expect(find.text('اختيار المدينة يدويًا'), findsOneWidget);
      expect(prayer.selectedCoordinates, isNull);
      await tap(tester, _notNow);
      expect(find.text('Home destination'), findsOneWidget);
    });

    testWidgets('a permanent refusal opens settings and locates on return', (
      tester,
    ) async {
      location.permission = LocationPermission.deniedForever;
      await toLocation(tester);
      expect(find.textContaining('الوصول إلى الموقع متوقف'), findsOneWidget);

      await tap(tester, _openSettings);
      expect(location.appSettingsOpened, 1);
      expect(location.requests, 0);

      location.permission = LocationPermission.whileInUse;
      await returnToApp(tester);
      expect(find.text('موقع الصلاة: القاهرة، مصر'), findsOneWidget);
    });

    testWidgets('location services off point to their settings', (
      tester,
    ) async {
      location
        ..permission = LocationPermission.whileInUse
        ..servicesEnabled = false;
      await toLocation(tester);
      expect(find.textContaining('خدمة الموقع متوقفة'), findsOneWidget);
      await tap(tester, 'فتح إعدادات الموقع');
      expect(location.locationSettingsOpened, 1);
    });

    testWidgets('a failed fix explains and keeps every way forward', (
      tester,
    ) async {
      device.error = const PrayerLocationException('تعذر تحديد الموقع');
      await toLocation(tester);
      await tap(tester, _enableLocation);
      expect(find.text('تعذر تحديد الموقع'), findsOneWidget);
      expect(find.text(_enableLocation), findsOneWidget);
      expect(find.text('اختيار المدينة يدويًا'), findsOneWidget);
      expect(find.text(_notNow), findsOneWidget);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('both steps fit a small screen with large text, $brightness', (
      tester,
    ) async {
      await pump(
        tester,
        size: const Size(320, 568),
        textScale: 2,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      await tap(tester, _notNow);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(_enableLocation));
      expect(find.text(_enableLocation).hitTestable(), findsOneWidget);
    });
  }
}
