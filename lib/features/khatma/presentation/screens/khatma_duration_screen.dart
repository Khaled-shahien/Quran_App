import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_motion.dart';
import 'package:sakina_app/core/widgets/pressable.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import '../widgets/labeled_row.dart';

import 'package:provider/provider.dart';
import '../../../onboarding/presentation/widgets/notification_permission_dialog.dart';
import '../providers/khatma_provider.dart';
import '../../domain/models/khatma_model.dart';

class KhatmaDurationScreen extends StatefulWidget {
  final String startMode;
  final int? startJuz;

  const KhatmaDurationScreen({
    super.key,
    required this.startMode,
    this.startJuz,
  });

  @override
  State<KhatmaDurationScreen> createState() => _KhatmaDurationScreenState();
}

class _KhatmaDurationScreenState extends State<KhatmaDurationScreen> {
  KhatmaGoalType _goalType = KhatmaGoalType.byDuration;
  KhatmaTrackingUnit _trackingUnit = KhatmaTrackingUnit.page;
  int _durationDays = 30;
  double _dailyTarget = 20;
  int _reminderHour = 8;
  int _reminderMinute = 0;

  int get _startUnitIndex {
    final int startJuz = (widget.startJuz ?? 1).clamp(1, 30);
    switch (_trackingUnit) {
      case KhatmaTrackingUnit.page:
        return (((startJuz - 1) * 20) + 1).clamp(1, 604);
      case KhatmaTrackingUnit.hizb:
        return (((startJuz - 1) * 2) + 1).clamp(1, 60);
      case KhatmaTrackingUnit.juz:
        return startJuz;
    }
  }

  int get _totalUnits {
    switch (_trackingUnit) {
      case KhatmaTrackingUnit.page:
        return 604;
      case KhatmaTrackingUnit.hizb:
        return 60;
      case KhatmaTrackingUnit.juz:
        return 30;
    }
  }

  int get _remainingUnits => _totalUnits - _startUnitIndex + 1;

  String get _unitLabel {
    switch (_trackingUnit) {
      case KhatmaTrackingUnit.page:
        return appL10n.khatmaModelMessage1;
      case KhatmaTrackingUnit.hizb:
        return appL10n.khatmaModelMessage2;
      case KhatmaTrackingUnit.juz:
        return appL10n.khatmaModelMessage3;
    }
  }

  double get _computedDailyTargetForDuration =>
      (_remainingUnits / _durationDays).clamp(1, 2000);

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final cardColor = SakinaDecor.of(context).card;
    final dropdownTextColor = Theme.of(context).colorScheme.onSurface;

    return SakinaHeroScaffold(
      title: l10nOf(context).khatmaDurationScreenMessage1,
      backgroundColor: backgroundColor,
      // Scrolls when large text needs more room; the continue button stays
      // at the bottom when everything fits.
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title text
                Text(
                  l10nOf(context).khatmaDurationScreenMessage2,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: textColor),
                ),
                const SizedBox(height: 30),

                Directionality(
                  textDirection: Directionality.of(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPlanTypeCard(
                          title: l10nOf(context).khatmaDurationScreenMessage3,
                          subtitle: l10nOf(
                            context,
                          ).khatmaDurationScreenMessage4,
                          active: _goalType == KhatmaGoalType.byDuration,
                          onTap: () {
                            setState(() {
                              _goalType = KhatmaGoalType.byDuration;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPlanTypeCard(
                          title: l10nOf(context).khatmaDurationScreenMessage5,
                          subtitle: l10nOf(
                            context,
                          ).khatmaDurationScreenMessage6,
                          active: _goalType == KhatmaGoalType.byDailyAmount,
                          onTap: () {
                            setState(() {
                              _goalType = KhatmaGoalType.byDailyAmount;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Directionality(
                  textDirection: Directionality.of(context),
                  child: LabeledRow(
                    children: [
                      Text(
                        l10nOf(context).khatmaDurationScreenMessage7,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: textColor),
                      ),
                      const SizedBox(width: AppSpacing.ms),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.ms,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: AppRadius.controls,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.6),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<KhatmaTrackingUnit>(
                              value: _trackingUnit,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(color: dropdownTextColor),
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: KhatmaTrackingUnit.page,
                                  child: Text(
                                    l10nOf(
                                      context,
                                    ).khatmaDurationScreenMessage8,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: KhatmaTrackingUnit.hizb,
                                  child: Text(
                                    l10nOf(
                                      context,
                                    ).khatmaDurationScreenMessage9,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: KhatmaTrackingUnit.juz,
                                  child: Text(
                                    l10nOf(
                                      context,
                                    ).khatmaDurationScreenMessage10,
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _trackingUnit = val;
                                    if (_goalType ==
                                        KhatmaGoalType.byDailyAmount) {
                                      _dailyTarget = _dailyTarget.clamp(
                                        1,
                                        _remainingUnits.toDouble(),
                                      );
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (_goalType == KhatmaGoalType.byDuration)
                  _buildDurationSection(cardColor, textColor)
                else
                  _buildDailyTargetSection(cardColor, textColor),

                const SizedBox(height: 18),

                _buildReminderSection(cardColor, textColor),

                const SizedBox(height: AppSpacing.ms),

                // The plan in one sentence, updated as the choices change.
                Container(
                  padding: const EdgeInsets.all(AppSpacing.ms),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: AppRadius.controls,
                  ),
                  child: Text(
                    _goalType == KhatmaGoalType.byDuration
                        ? l10nOf(context).khatmaDurationScreenMessage11(
                            context.digits(
                              _formatDouble(_computedDailyTargetForDuration),
                            ),
                            (_unitLabel).toString(),
                          )
                        : l10nOf(context).khatmaDurationScreenMessage12(
                            context.digits(
                              (_remainingUnits / _dailyTarget).ceil(),
                            ),
                          ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                const SizedBox(height: AppSpacing.lg),
                // Continue Button
                ElevatedButton(
                  onPressed: () async {
                    final provider = Provider.of<KhatmaProvider>(
                      context,
                      listen: false,
                    );

                    final double target = _goalType == KhatmaGoalType.byDuration
                        ? _computedDailyTargetForDuration
                        : _dailyTarget;

                    final newKhatma = KhatmaModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      startMode: widget.startMode,
                      startJuz: widget.startJuz ?? 1,
                      startDate: DateTime.now(),
                      trackingUnit: _trackingUnit,
                      goalType: _goalType,
                      plannedDurationDays: _durationDays,
                      dailyTargetUnits: target,
                      completedUnits: 0,
                      reminderHour: _reminderHour,
                      reminderMinute: _reminderMinute,
                    );

                    await provider.startNewKhatma(newKhatma);

                    if (!context.mounted) return;
                    // A plan's daily reminder needs the same one-time permission
                    // explanation as a first prayer location.
                    await promptForNotificationPermissionOnce(context);

                    if (!context.mounted) return;

                    playFeedback(context, FeedbackEvent.success);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10nOf(context).khatmaDurationScreenMessage13,
                        ),
                      ),
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(l10nOf(context).khatmaDurationScreenMessage14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanTypeCard({
    required String title,
    required String subtitle,
    required bool active,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: active,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: onTap,
        feedback: active ? null : FeedbackEvent.selection,
        borderRadius: AppRadius.controls,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.base),
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(AppSpacing.ms),
          decoration: BoxDecoration(
            color: active ? scheme.secondary : Colors.transparent,
            borderRadius: AppRadius.controls,
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: active ? scheme.onSecondary : scheme.onSurface,
                      ),
                    ),
                  ),
                  // The chosen plan carries a tick as well as a colour.
                  if (active)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSection(Color cardColor, Color textColor) {
    return _StepperRow(
      label: appL10n.khatmaDurationScreenMessage15,
      value: appL10n.khatmaDurationScreenMessage16(
        context.digits(_durationDays),
      ),
      increaseTooltip: appL10n.khatmaIncreaseDays,
      decreaseTooltip: appL10n.khatmaDecreaseDays,
      onIncrease: () => setState(() => _durationDays++),
      onDecrease: () {
        if (_durationDays > 1) {
          setState(() => _durationDays--);
        }
      },
    );
  }

  Widget _buildDailyTargetSection(Color cardColor, Color textColor) {
    return _StepperRow(
      label: appL10n.khatmaDurationScreenMessage17,
      value: context.digits('${_formatDouble(_dailyTarget)} $_unitLabel'),
      increaseTooltip: appL10n.khatmaIncreaseDaily,
      decreaseTooltip: appL10n.khatmaDecreaseDaily,
      onIncrease: () {
        setState(() {
          _dailyTarget = (_dailyTarget + 0.5).clamp(
            1,
            _remainingUnits.toDouble(),
          );
        });
      },
      onDecrease: () {
        setState(() {
          _dailyTarget = (_dailyTarget - 0.5).clamp(
            1,
            _remainingUnits.toDouble(),
          );
        });
      },
    );
  }

  Widget _buildReminderSection(Color cardColor, Color textColor) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Directionality(
      textDirection: Directionality.of(context),
      child: LabeledRow(
        children: [
          Text(
            appL10n.khatmaDurationScreenMessage18,
            style: theme.textTheme.titleMedium?.copyWith(color: textColor),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Pressable(
              scale: false,
              borderRadius: AppRadius.controls,
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _reminderHour,
                    minute: _reminderMinute,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _reminderHour = picked.hour;
                    _reminderMinute = picked.minute;
                  });
                }
              },
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.touchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: AppRadius.controls,
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.digits(
                          '${_reminderHour.toString().padLeft(2, '0')}:'
                          '${_reminderMinute.toString().padLeft(2, '0')}',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label, the current value, and a pair of buttons to raise or lower it.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.increaseTooltip,
    required this.decreaseTooltip,
    required this.onIncrease,
    required this.onDecrease,
  });

  final String label;
  final String value;
  final String increaseTooltip;
  final String decreaseTooltip;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color card = SakinaDecor.of(context).card;
    final BorderSide outline = BorderSide(
      color: scheme.outline.withValues(alpha: 0.6),
    );

    Widget button(String tooltip, IconData icon, VoidCallback onPressed) {
      return IconButton(
        tooltip: tooltip,
        onPressed: () {
          playFeedback(context, FeedbackEvent.selection);
          onPressed();
        },
        icon: Icon(icon, color: scheme.primary, size: 20),
      );
    }

    return Directionality(
      textDirection: Directionality.of(context),
      child: LabeledRow(
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.touchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: card,
                borderRadius: AppRadius.controls,
                border: Border.fromBorderSide(outline),
              ),
              alignment: Alignment.center,
              // The value is announced when it changes.
              child: Semantics(
                liveRegion: true,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          DecoratedBox(
            decoration: BoxDecoration(
              color: card,
              border: Border.fromBorderSide(outline),
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                button(increaseTooltip, Icons.add, onIncrease),
                SizedBox(
                  height: 24,
                  child: VerticalDivider(width: 1, color: outline.color),
                ),
                button(decreaseTooltip, Icons.remove, onDecrease),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
