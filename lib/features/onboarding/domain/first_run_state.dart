import 'package:shared_preferences/shared_preferences.dart';

/// Written when the user finishes or skips onboarding.
const String onboardingCompleteKey = 'onboarding_complete';

/// Written once the notification permission explanation has been answered.
const String notificationPromptSeenKey = 'has_seen_notification_permission';

/// Older installs recorded first-run completion only through the prompt flag.
bool hasCompletedOnboarding(SharedPreferences preferences) =>
    (preferences.getBool(onboardingCompleteKey) ?? false) ||
    (preferences.getBool(notificationPromptSeenKey) ?? false);
