import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/navigation/app_router.dart';

/// Handles navigation triggered by notification taps
///
/// This function routes the user to the appropriate screen based on
/// the notification route and payload data. Targets open above home because
/// their back buttons pop, and a sole page has nothing to return to.
void handleNotificationNavigation(String route, Map<String, dynamic>? data) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;

  final router = GoRouter.of(context);
  final location = _locationFor(route, data);
  router.go('/home');
  if (location != '/home') router.push(location);
}

String _locationFor(String route, Map<String, dynamic>? data) {
  switch (route) {
    case '/duas':
      final String? dhikrType = data?['type']?.toString();
      if (dhikrType == 'morning') return '/duas/morning';
      if (dhikrType == 'evening') return '/duas/evening';
      return '/duas';
    case '/quran':
      final number = int.tryParse(data?['surahNumber']?.toString() ?? '');
      return number != null && number >= 1 && number <= 114
          ? '/quran/surah/$number'
          : '/quran';
    case '/prayers':
      // A prayer-time alert opens the adhan adhkar (dua after the adhan).
      final String? prayer = data?['prayerName']?.toString();
      return prayer == null || prayer.isEmpty
          ? '/prayers'
          : Uri(
              path: '/after-adhan',
              queryParameters: {'prayer': prayer},
            ).toString();
    case '/khatma':
      return '/khatma';
    case '/':
    default:
      return '/home';
  }
}
