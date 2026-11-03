import 'package:shared_preferences/shared_preferences.dart';

/// Written when the user finishes or skips onboarding.
const String onboardingCompleteKey = 'onboarding_complete';

/// Written once the notification permission explanation has been answered.
const String notificationPromptSeenKey = 'has_seen_notification_permission';

/// Older installs recorded first-run completion only through the prompt flag.
/// `get` keeps a wrongly typed stored value from breaking launch routing.
bool hasCompletedOnboarding(SharedPreferences preferences) =>
    preferences.get(onboardingCompleteKey) == true ||
    preferences.get(notificationPromptSeenKey) == true;
