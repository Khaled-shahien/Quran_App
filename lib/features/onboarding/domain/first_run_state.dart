import 'package:shared_preferences/shared_preferences.dart';

/// Written when the user finishes or skips onboarding.
const String onboardingCompleteKey = 'onboarding_complete';

/// Written once the notification permission explanation has been answered
/// (first-run step or the later in-context dialog), so it is never asked
/// again by the app itself.
const String notificationPromptSeenKey = 'has_seen_notification_permission';

/// Written once the first-run location step has been answered.
const String locationIntroSeenKey = 'location_intro_seen';

/// True from the end of the onboarding pages until the permission steps
/// that follow them are finished, so closing the app in between resumes
/// there. Installs that finished onboarding before these steps existed
/// never have it and are not shown them.
const String permissionIntroPendingKey = 'permission_intro_pending';

/// Older installs recorded first-run completion only through the prompt flag.
/// `get` keeps a wrongly typed stored value from breaking launch routing.
bool hasCompletedOnboarding(SharedPreferences preferences) =>
    preferences.get(onboardingCompleteKey) == true ||
    preferences.get(notificationPromptSeenKey) == true;

bool isPermissionIntroPending(SharedPreferences preferences) =>
    preferences.get(permissionIntroPendingKey) == true;

/// Where launch goes once the splash is done.
String firstRunDestination(SharedPreferences preferences) {
  if (!hasCompletedOnboarding(preferences)) return '/onboarding';
  if (isPermissionIntroPending(preferences)) return '/onboarding/permissions';
  return '/home';
}
