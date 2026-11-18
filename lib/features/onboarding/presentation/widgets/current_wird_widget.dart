import 'package:sakina_app/features/khatma/presentation/widgets/wird_portions_card.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'dart:async';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/feedback_service.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sakina_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../khatma/domain/models/khatma_model.dart';
import '../../../khatma/domain/models/wird_reading_position.dart';
import '../../../khatma/domain/services/khatma_quran_locator.dart';
import '../../../quran/domain/entities/surah_entity.dart';
import '../../../quran/domain/repositories/surah_repository.dart';
import 'package:provider/provider.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';

class _WirdPreviewData {
  final String ayahText;
  final String reference;

  const _WirdPreviewData({required this.ayahText, required this.reference});
}

class CurrentWirdWidget extends StatelessWidget {
  const CurrentWirdWidget({super.key});

  static final KhatmaQuranLocator _quranLocator = KhatmaQuranLocator();

  static final String _completedWirdMessage = appL10n.currentWirdWidgetMessage1;
  static final String _completedKhatmaMessage =
      appL10n.currentWirdWidgetMessage2;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final Color textDark = scheme.onSurface;
    final Color dividerColor = scheme.outlineVariant;
    final Color primaryColor = scheme.primary;

    return Consumer<KhatmaProvider>(
      builder: (context, khatmaProvider, child) {
        final activeKhatma = khatmaProvider.activeKhatma;
        final WirdReadingPosition? savedPosition = activeKhatma == null
            ? null
            : khatmaProvider.savedWirdPositionFor(activeKhatma);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: l10nOf(context).currentWirdWidgetMessage3,
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.ms,
                ),
              ),

              if (activeKhatma != null) ...[
                // Main Card
                SakinaCard(
                  child: Column(
                    children: [
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              l10nOf(context).currentWirdWidgetMessage4,
                              style: text.titleSmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.ms,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondary,
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              l10nOf(context).khatmaLocationScreenMessage5(
                                (activeKhatma.currentJuz).toString(),
                              ),
                              style: text.labelMedium?.copyWith(
                                color: scheme.onSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Dynamic first ayah preview for current wird range.
                      _AnimatedWirdAyahPreview(
                        cacheKey:
                            '${activeKhatma.id}_'
                            '${activeKhatma.todayFromUnit}_'
                            '${activeKhatma.todayToUnit}',
                        textColor: textDark,
                        loader: () => _loadCurrentWirdPreview(
                          context: context,
                          khatma: activeKhatma,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Details Row 1 (Start)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10nOf(context).currentWirdWidgetMessage5(
                              (activeKhatma.startMode).toString(),
                            ),
                            style: text.labelLarge?.copyWith(
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            l10nOf(context).currentWirdWidgetMessage6(
                              (activeKhatma.amountValue).toString(),
                            ),
                            style: text.labelLarge?.copyWith(
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10nOf(context).currentWirdWidgetMessage7(
                          (activeKhatma.todayFromUnit).toString(),
                          (activeKhatma.todayToUnit).toString(),
                          (activeKhatma.amountType).toString(),
                        ),
                        style: text.bodySmall,
                        textAlign: TextAlign.start,
                      ),
                      if (savedPosition != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                l10nOf(context).currentWirdWidgetMessage8,
                                style: text.labelMedium?.copyWith(
                                  color: primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // Action Buttons
                      Row(
                        children: [
                          // Finished: the quieter of the two actions.
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await khatmaProvider
                                    .markCurrentWirdAsFinished();
                                if (!context.mounted) return;
                                playFeedback(context, FeedbackEvent.success);

                                final nextKhatma = khatmaProvider.activeKhatma;
                                final bool stillActive =
                                    nextKhatma != null &&
                                    !nextKhatma.isCompleted;

                                final String message = stillActive
                                    ? _completedWirdMessage
                                    : _completedKhatmaMessage;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.ms,
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 20),
                              label: Text(
                                l10nOf(context).currentWirdWidgetMessage9,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.ms),

                          // Read: the primary action.
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await _openWirdAtStart(
                                  context: context,
                                  khatma: activeKhatma,
                                );
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.ms,
                                ),
                              ),
                              child: Text(
                                l10nOf(context).currentWirdWidgetMessage10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Khatma Details (Progress Section)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10nOf(context).appRouterMessage1,
                      style: text.titleSmall,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10nOf(context).currentWirdWidgetMessage11,
                          icon: Icon(
                            Icons.close_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  l10nOf(context).currentWirdWidgetMessage11,
                                  style: const TextStyle(),
                                ),
                                content: Text(
                                  l10nOf(context).currentWirdWidgetMessage12,
                                  style: const TextStyle(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      l10nOf(
                                        context,
                                      ).currentWirdWidgetMessage13,
                                      style: const TextStyle(),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      khatmaProvider.cancelKhatma();
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      l10nOf(
                                        context,
                                      ).currentWirdWidgetMessage14,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Progress Bar
                _KhatmaProgressBar(
                  progress: activeKhatma.progress,
                  fillColor: primaryColor,
                  trackColor: dividerColor,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Progress Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10nOf(context).currentWirdWidgetMessage15(
                        context.digits(activeKhatma.remainingUnits.ceil()),
                        (activeKhatma.amountType).toString(),
                      ),
                      style: text.labelMedium,
                    ),
                    Text(
                      l10nOf(context).currentWirdWidgetMessage16(
                        context.digits(
                          (activeKhatma.progress * 100).toStringAsFixed(1),
                        ),
                      ),
                      style: text.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                WirdPortionsCard(khatma: activeKhatma),
              ] else ...[
                // Empty State (No Active Khatma)
                SakinaCard(
                  tone: SakinaCardTone.tinted,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 30,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10nOf(context).homeScreenMessage8,
                        textAlign: TextAlign.center,
                        style: text.titleMedium?.copyWith(
                          color: scheme.onSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10nOf(context).currentWirdWidgetMessage17,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSecondary.withValues(alpha: 0.78),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () {
                          context.push('/khatma/location');
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(l10nOf(context).currentWirdWidgetMessage18),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWirdAtStart({
    required BuildContext context,
    required KhatmaModel khatma,
  }) async {
    final SurahRepository surahRepository = Provider.of<SurahRepository>(
      context,
      listen: false,
    );
    final KhatmaProvider khatmaProvider = Provider.of<KhatmaProvider>(
      context,
      listen: false,
    );
    final WirdReadingPosition? savedPosition = khatmaProvider
        .savedWirdPositionFor(khatma);

    final int targetSurahNumber;
    final int targetAyahNumber;
    if (savedPosition != null) {
      targetSurahNumber = savedPosition.surahNumber;
      targetAyahNumber = savedPosition.ayahNumber;
    } else {
      final KhatmaAyahPosition position = await _quranLocator
          .resolvePositionFromStoredOrUnit(khatma: khatma);
      targetSurahNumber = position.surahNumber;
      targetAyahNumber = position.ayahNumber;
    }

    final List<SurahEntity> surahs =
        (await surahRepository.getAllSurahs()).valueOrNull ??
        const <SurahEntity>[];
    if (surahs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nOf(context).homeScreenMessage19)),
      );
      return;
    }

    final SurahEntity targetSurah = surahs.firstWhere(
      (surah) => surah.number == targetSurahNumber,
      orElse: () => surahs.first,
    );

    if (!context.mounted) return;

    unawaited(
      context.push(
        '/quran/surah/${targetSurah.number}',
        extra: <String, dynamic>{
          'surah': targetSurah,
          'initialSurahNumber': targetSurahNumber,
          'initialAyahNumber': targetAyahNumber,
          'rangeTrackingUnit': khatma.trackingUnit.storageValue,
          'rangeFromUnit': khatma.todayFromUnit,
          'rangeToUnit': khatma.todayToUnit,
        },
      ),
    );
  }

  Future<_WirdPreviewData> _loadCurrentWirdPreview({
    required BuildContext context,
    required KhatmaModel khatma,
  }) async {
    final strings = l10nOf(context);
    final KhatmaAyahPosition position = await _quranLocator
        .resolvePositionFromStoredOrUnit(khatma: khatma);

    return _WirdPreviewData(
      ayahText: position.ayahText.isEmpty
          ? strings.currentWirdWidgetMessage19
          : position.ayahText,
      reference: strings.currentWirdWidgetMessage20(
        (position.surahName).toString(),
        (position.ayahNumber).toString(),
        (position.pageNumber).toString(),
      ),
    );
  }
}

class _KhatmaProgressBar extends StatelessWidget {
  final double progress;
  final Color fillColor;
  final Color trackColor;

  const _KhatmaProgressBar({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final double safeProgress = progress.clamp(0.0, 1.0).toDouble();

    Widget buildBar(double value) {
      return ClipRRect(
        borderRadius: AppRadius.pill,
        child: LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      );
    }

    if (MediaQuery.of(context).disableAnimations) {
      return buildBar(safeProgress);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: safeProgress),
      duration: AppMotion.slow,
      curve: AppMotion.enter,
      builder: (context, value, child) => buildBar(value),
    );
  }
}

class _AnimatedWirdAyahPreview extends StatefulWidget {
  final String cacheKey;
  final Color textColor;
  final Future<_WirdPreviewData> Function() loader;

  const _AnimatedWirdAyahPreview({
    required this.cacheKey,
    required this.textColor,
    required this.loader,
  });

  @override
  State<_AnimatedWirdAyahPreview> createState() =>
      _AnimatedWirdAyahPreviewState();
}

class _AnimatedWirdAyahPreviewState extends State<_AnimatedWirdAyahPreview> {
  _WirdPreviewData? _current;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _AnimatedWirdAyahPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final _WirdPreviewData data = await widget.loader();
      if (!mounted) return;
      setState(() {
        _current = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _WirdPreviewData display =
        _current ??
        _WirdPreviewData(
          ayahText: l10nOf(context).currentWirdWidgetMessage21,
          reference: '',
        );

    return Column(
      children: [
        AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Column(
            key: ValueKey<String>('${display.reference}_${display.ayahText}'),
            children: [
              Text(
                display.ayahText,
                style: AppTypography.script.copyWith(color: widget.textColor),
                textAlign: TextAlign.center,
              ),
              if (display.reference.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  display.reference,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        if (_isLoading && _current != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 48,
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: widget.textColor.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
    );
  }
}
