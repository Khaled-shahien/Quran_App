import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/feedback/feedback_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/geometric_pattern.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../quran/domain/daily_verses.dart';
import '../providers/favorites_provider.dart';

class DailyVerseSectionWidget extends StatefulWidget {
  const DailyVerseSectionWidget({super.key});

  @override
  State<DailyVerseSectionWidget> createState() =>
      _DailyVerseSectionWidgetState();
}

class _DailyVerseSectionWidgetState extends State<DailyVerseSectionWidget> {
  late Map<String, String> _selectedVerse;

  @override
  void initState() {
    super.initState();
    // One verse per calendar day, so it does not change on every visit.
    _selectedVerse = dailyVerses[dailyVerseIndex(DateTime.now())];
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SakinaDecor decor = SakinaDecor.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10nOf(context).dailyVerseSectionWidgetMessage1,
          trailing: Text(
            _selectedVerse['surah']!,
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: ClipRRect(
            borderRadius: AppRadius.hero,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: decor.heroColors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GeometricPattern(
                      pattern: decor.pattern,
                      color: decor.onFeature.withValues(alpha: 0.07),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.lg,
                    ),
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, child) {
                        final isFav = favoritesProvider.isFavorite(
                          _selectedVerse,
                        );
                        return Column(
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: IconButton(
                                tooltip: isFav
                                    ? l10nOf(context).homeScreenMessage60
                                    : l10nOf(context).addVerseToFavorites,
                                onPressed: () {
                                  playFeedback(context, FeedbackEvent.favorite);
                                  favoritesProvider.toggleFavorite(
                                    _selectedVerse,
                                  );
                                },
                                // The heart pops when its state changes.
                                icon: AnimatedSwitcher(
                                  duration: AppMotion.of(
                                    context,
                                    AppMotion.base,
                                  ),
                                  switchInCurve: Curves.easeOutBack,
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      ),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    key: ValueKey<bool>(isFav),
                                    color: isFav
                                        ? decor.accent
                                        : decor.onFeatureMuted,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.md,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _selectedVerse['arabic']!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.script.copyWith(
                                      fontSize: 26,
                                      color: decor.onFeature,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.ms),
                                  Text(
                                    _selectedVerse['english']!,
                                    textDirection: TextDirection.ltr,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: decor.onFeatureMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
