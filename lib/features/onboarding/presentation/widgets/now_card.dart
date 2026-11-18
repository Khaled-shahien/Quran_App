import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/features/prayers/data/services/local_prayer_notification_scheduler.dart';
import 'package:sakina_app/features/prayers/domain/entities/adhan_settings.dart';
import 'package:sakina_app/features/prayers/presentation/providers/prayer_times_provider.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

/// What fits this moment of the day, decided from the day's prayer times.
enum NowSuggestion { morningAdhkar, eveningAdhkar, sleepAdhkar }

typedef NowPlan = ({NowSuggestion? main, bool kahf});

/// Pure decision, for tests: morning adhkar from Fajr until Dhuhr,
/// evening adhkar from Asr until Isha, sleep adhkar from Isha until Fajr;
/// on Friday before Maghrib, Surat al-Kahf as well.
NowPlan planNow({
  required Map<DailyPrayer, DateTime> today,
  required DateTime now,
  required bool friday,
}) {
  final DateTime? fajr = today[DailyPrayer.fajr];
  final DateTime? dhuhr = today[DailyPrayer.dhuhr];
  final DateTime? asr = today[DailyPrayer.asr];
  final DateTime? maghrib = today[DailyPrayer.maghrib];
  final DateTime? isha = today[DailyPrayer.isha];
  if (fajr == null ||
      dhuhr == null ||
      asr == null ||
      maghrib == null ||
      isha == null) {
    return (main: null, kahf: false);
  }
  NowSuggestion? main;
  if (!now.isBefore(fajr) && now.isBefore(dhuhr)) {
    main = NowSuggestion.morningAdhkar;
  } else if (!now.isBefore(asr) && now.isBefore(isha)) {
    main = NowSuggestion.eveningAdhkar;
  } else if (!now.isBefore(isha) || now.isBefore(fajr)) {
    main = NowSuggestion.sleepAdhkar;
  }
  return (main: main, kahf: friday && now.isBefore(maghrib));
}

/// The Home card that follows the day: the adhkar of this time, and Surat
/// al-Kahf on Friday. Hidden until prayer times are known.
class NowCard extends StatelessWidget {
  const NowCard({super.key, this.now});

  /// Injected in tests.
  final DateTime Function()? now;

  static const int sleepChapterId = 28;

  @override
  Widget build(BuildContext context) {
    final PrayerTimesProvider? provider = context.watch<PrayerTimesProvider?>();
    final entity = provider?.prayerTimes;
    if (provider == null || entity == null) return const SizedBox.shrink();
    final DateTime wall = provider.locationNow;
    final Map<DailyPrayer, DateTime> today =
        LocalPrayerNotificationScheduler.buildPrayerSchedule(
          prayerTimes: entity,
          date: DateTime(wall.year, wall.month, wall.day),
        );
    final NowPlan plan = planNow(
      today: today,
      now: (now ?? DateTime.now)(),
      friday: wall.weekday == DateTime.friday,
    );
    if (plan.main == null && !plan.kahf) return const SizedBox.shrink();
    final AppLocalizations l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);

    Widget action(String label, IconData icon, String route) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () => context.push(route),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: SakinaCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.nowCardTitle, style: theme.textTheme.titleSmall),
            switch (plan.main) {
              NowSuggestion.morningAdhkar => action(
                l10n.nowMorningAdhkar,
                Icons.wb_sunny_outlined,
                '/duas/morning',
              ),
              NowSuggestion.eveningAdhkar => action(
                l10n.nowEveningAdhkar,
                Icons.nights_stay_outlined,
                '/duas/evening',
              ),
              NowSuggestion.sleepAdhkar => action(
                l10n.nowSleepAdhkar,
                Icons.bedtime_outlined,
                '/duas/hisn/$sleepChapterId',
              ),
              null => const SizedBox.shrink(),
            },
            if (plan.main == NowSuggestion.sleepAdhkar)
              action(
                l10n.nowSurahMulk,
                Icons.menu_book_outlined,
                '/quran/surah/67',
              ),
            if (plan.kahf)
              action(
                l10n.nowSurahKahf,
                Icons.auto_stories_outlined,
                '/quran/surah/18',
              ),
          ],
        ),
      ),
    );
  }
}
