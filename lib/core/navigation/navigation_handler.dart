import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/navigation/app_router.dart';

/// NavigationHandler provides central routing logic for out-of-band updates,
/// mainly for resolving navigation targets from notifications.
class NavigationHandler {
  /// Handles navigation from notification taps.
  /// Called globally without a direct widget context to navigate users upon notification interact.
  static void handleNotificationNavigation(
    String route,
    Map<String, dynamic>? data,
  ) {
    // Current application context grabbed from the global nav key
    final context = appNavigatorKey.currentContext;
    if (context == null) {
      developer.log(
        'Cannot navigate to $route: context is null',
        name: 'sakina_app.nav',
        level: 1000,
      );
      return;
    }

    final destination = _resolveRoute(route, data);
    developer.log(
      'Navigating to destination: $destination',
      name: 'sakina_app.nav',
    );
    context.go(destination);
  }

  /// Resolves the intended route path based on the route identifier and data.
  static String _resolveRoute(String route, Map<String, dynamic>? data) {
    switch (route) {
      case '/duas':
        return _resolveDuasRoute(data);
      case '/quran':
        return '/quran';
      case '/prayers':
        return '/prayers';
      case '/khatma':
        return '/home';
      case '/':
      default:
        // Default to home page for unresolved or unknown routes.
        return '/home';
    }
  }

  /// Specifically resolves routing for Duas (morning vs evening).
  static String _resolveDuasRoute(Map<String, dynamic>? data) {
    final String? dhikrType = data?['type']?.toString();
    if (dhikrType == 'morning') {
      return '/duas/morning';
    } else if (dhikrType == 'evening') {
      return '/duas/evening';
    } else {
      return '/duas';
    }
  }
}
