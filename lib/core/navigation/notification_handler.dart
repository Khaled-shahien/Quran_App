import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/navigation/app_router.dart';

/// Handles navigation triggered by notification taps
///
/// This function routes the user to the appropriate screen based on
/// the notification route and payload data.
void handleNotificationNavigation(String route, Map<String, dynamic>? data) {
  final context = appNavigatorKey.currentContext;
  if (context == null) return;

  switch (route) {
    case '/duas':
      final String? dhikrType = data?['type']?.toString();
      if (dhikrType == 'morning') {
        context.go('/duas/morning');
      } else if (dhikrType == 'evening') {
        context.go('/duas/evening');
      } else {
        context.go('/duas');
      }
      break;
    case '/quran':
      final number = int.tryParse(data?['surahNumber']?.toString() ?? '');
      context.go(
        number != null && number >= 1 && number <= 114
            ? '/quran/surah/$number'
            : '/quran',
      );
      break;
    case '/prayers':
      context.go('/prayers');
      break;
    case '/khatma':
      context.go('/khatma');
      break;
    case '/':
    default:
      context.go('/home');
      break;
  }
}
