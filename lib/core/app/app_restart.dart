import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayers/domain/repositories/prayer_times_repository.dart';
import '../../features/prayers/domain/services/prayer_notification_scheduler.dart';
import '../../features/prayers/presentation/providers/prayer_times_provider.dart';
import '../navigation/app_router.dart';
import '../providers/settings_provider.dart';
import 'app_root.dart';

/// After the user's data was replaced (import) or cleared (reset): plans
/// every alert again from the stored settings, then rebuilds the whole app
/// so no screen keeps values read before the change.
Future<void> restartAfterDataChange() async {
  final GetIt di = GetIt.instance;
  final SharedPreferences prefs = di<SharedPreferences>();
  final SettingsProvider settings = SettingsProvider(prefs: prefs);
  final PrayerTimesProvider prayer = PrayerTimesProvider(
    repository: di<PrayerTimesRepository>(),
    preferences: prefs,
    notificationScheduler: di<PrayerNotificationScheduler>(),
  );
  try {
    await settings.resyncAlarms();
    if (prayer.selectedCoordinates != null) {
      await prayer.refresh();
    } else {
      await di<PrayerNotificationScheduler>().cancelPrayerNotifications();
    }
  } finally {
    settings.dispose();
    prayer.dispose();
  }
  runApp(AppRoot(key: UniqueKey()));
  appRouter.go('/splash');
}
