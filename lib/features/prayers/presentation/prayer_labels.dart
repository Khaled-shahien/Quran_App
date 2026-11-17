import 'package:sakina_app/l10n/app_localizations.dart';

import '../domain/entities/adhan_settings.dart';

/// Display names for prayers and alert modes. Logic keys on [DailyPrayer];
/// these strings are only shown, never compared.
extension AdhanLabels on AppLocalizations {
  String prayerName(DailyPrayer p) => switch (p) {
    DailyPrayer.fajr => prayerTimesWidgetMessage8,
    DailyPrayer.dhuhr => prayerTimesWidgetMessage9,
    DailyPrayer.asr => prayerTimesWidgetMessage10,
    DailyPrayer.maghrib => prayerTimesWidgetMessage11,
    DailyPrayer.isha => prayerTimesWidgetMessage12,
  };

  String alertMode(PrayerAlertMode m) => switch (m) {
    PrayerAlertMode.adhan => prayerAlertModeAdhan,
    PrayerAlertMode.sound => prayerAlertModeSound,
    PrayerAlertMode.notificationOnly => prayerAlertModeNotification,
    PrayerAlertMode.silent => prayerAlertModeSilent,
  };
}
