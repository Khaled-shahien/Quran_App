import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../prayers/presentation/prayer_labels.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../quran/data/data_sources/quran_master_asset.dart';
import '../../../quran/domain/services/quran_divisions.dart';
import '../../domain/models/khatma_model.dart';
import '../../domain/services/wird_portions.dart';

/// Today's wird split over the five prayers, with an optional reminder
/// after each (scheduled with the prayer alerts).
class WirdPortionsCard extends StatefulWidget {
  const WirdPortionsCard({super.key, required this.khatma, this.divisions});

  final KhatmaModel khatma;

  /// Supplied by tests; otherwise read from the bundled mushaf data.
  final QuranDivisions? divisions;

  @override
  State<WirdPortionsCard> createState() => _WirdPortionsCardState();
}

class _WirdPortionsCardState extends State<WirdPortionsCard> {
  QuranDivisions? _divisions;

  @override
  void initState() {
    super.initState();
    _divisions = widget.divisions;
    if (_divisions == null) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final d = QuranDivisions.fromSurahs(await QuranMasterAsset.load());
      if (mounted) setState(() => _divisions = d);
    } catch (_) {
      // Without the index the card simply stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final prefs = context.read<SharedPreferences?>();
    final divisions = _divisions;
    if (prefs == null || divisions == null) return const SizedBox.shrink();
    final range = todayPageRange(widget.khatma, divisions);
    if (range == null) return const SizedBox.shrink();
    final bool on = prefs.getBool(wirdAfterPrayersKey) ?? false;

    return SakinaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const Key('wird-after-prayers'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.wirdPortionsTitle),
            subtitle: Text(l10n.wirdPortionsHelp),
            value: on,
            onChanged: (value) async {
              await prefs.setBool(wirdAfterPrayersKey, value);
              if (!context.mounted) return;
              setState(() {});
              // Reminders are scheduled with the prayer alerts.
              unawaited(context.read<PrayerTimesProvider?>()?.refresh());
            },
          ),
          if (on)
            for (final p in splitAcrossPrayers(range.fromPage, range.toPage))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  context.digits(
                    l10n.wirdPortionLine(
                      l10n.prayerName(p.prayer),
                      wirdPagesLabel(p.fromPage, p.toPage),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// "pages 5–8" or "page 5".
String wirdPagesLabel(int from, int to) => from == to
    ? appL10n.wirdPortionPage('$from')
    : appL10n.wirdPortionPages('$from', '$to');
