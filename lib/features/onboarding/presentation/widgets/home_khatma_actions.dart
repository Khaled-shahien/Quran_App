part of 'home_drawer.dart';

mixin _HomeKhatmaActions on State<HomeDrawer> {
  final KhatmaQuranLocator _quranLocator = KhatmaQuranLocator();
  void _showFeatureMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  void _showKhatmaWirdSheet({required bool showCompleted}) {
    final khatmaProvider = Provider.of<KhatmaProvider>(context, listen: false);
    final activeKhatma = khatmaProvider.activeKhatma;

    if (activeKhatma == null) {
      _showFeatureMessage(appL10n.homeScreenMessage8);
      return;
    }

    final int duration = activeKhatma.durationDays;
    final int completed = activeKhatma.completedDays.clamp(0, duration);
    final int remaining = (duration - completed).clamp(0, duration);
    final List<KhatmaCompletedWird> completedWirds = activeKhatma
        .completedWirds
        .reversed
        .toList();
    final int count = showCompleted ? completedWirds.length : remaining;
    final String title;
    if (showCompleted) {
      title = appL10n.homeScreenMessage9;
    } else {
      title = appL10n.homeScreenMessage10;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showCompleted
                      ? l10nOf(
                          context,
                        ).homeScreenMessage11((completed).toString())
                      : l10nOf(
                          context,
                        ).homeScreenMessage12((remaining).toString()),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                if (count == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      showCompleted
                          ? l10nOf(context).homeScreenMessage13
                          : l10nOf(context).homeScreenMessage14,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: count,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (showCompleted) {
                          final KhatmaCompletedWird wird =
                              completedWirds[index];
                          final DateTime at = wird.completedAt;
                          final String dateLabel =
                              '${at.year}/${at.month.toString().padLeft(2, '0')}/'
                              '${at.day.toString().padLeft(2, '0')}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10nOf(context).homeScreenMessage15(
                                (wird.fromUnit).toString(),
                                (wird.toUnit).toString(),
                                (activeKhatma.amountType).toString(),
                              ),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            subtitle: Text(
                              l10nOf(
                                context,
                              ).homeScreenMessage16((dateLabel).toString()),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.65),
                              ),
                              textAlign: TextAlign.right,
                            ),
                            leading: Icon(
                              Icons.open_in_new,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _openWirdFromUnit(
                                khatma: activeKhatma,
                                unitIndex: wird.fromUnit,
                              );
                            },
                          );
                        }

                        final int wirdDay = completed + index + 1;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10nOf(
                              context,
                            ).homeScreenMessage17((wirdDay).toString()),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            l10nOf(context).homeScreenMessage18,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.65),
                            ),
                            textAlign: TextAlign.right,
                          ),
                          leading: Icon(
                            Icons.schedule,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWirdFromUnit({
    required KhatmaModel khatma,
    required int unitIndex,
  }) async {
    final SurahRepository surahRepository = Provider.of<SurahRepository>(
      context,
      listen: false,
    );
    final position = await _quranLocator.resolveStartPosition(
      trackingUnit: khatma.trackingUnit,
      unitIndex: unitIndex,
    );

    final List<SurahEntity> surahs = await surahRepository.getAllSurahs();
    if (surahs.isEmpty) {
      if (!mounted) return;
      _showFeatureMessage(appL10n.homeScreenMessage19);
      return;
    }

    final SurahEntity targetSurah = surahs.firstWhere(
      (surah) => surah.number == position.surahNumber,
      orElse: () => surahs.first,
    );

    if (!mounted) return;

    context.push(
      '/quran/surah/${targetSurah.number}',
      extra: <String, dynamic>{
        'surah': targetSurah,
        'initialSurahNumber': position.surahNumber,
        'initialAyahNumber': position.ayahNumber,
        'rangeTrackingUnit': khatma.trackingUnit.storageValue,
        'rangeFromUnit': unitIndex,
        'rangeToUnit': khatma.todayToUnit < unitIndex
            ? unitIndex
            : khatma.todayToUnit,
      },
    );
  }
}
