import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/core/widgets/status_view.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/widgets/geometric_pattern.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:flutter/material.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/result/failure_messages.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/models/azkar_model.dart';
import '../../domain/repositories/adhan_adhkar_repository.dart';
import '../widgets/dhikr_text_block.dart';

/// Opened from a prayer notification: the adhkar for the adhan, including
/// the dua after it.
class AfterAdhanScreen extends StatefulWidget {
  const AfterAdhanScreen({
    super.key,
    required this.repository,
    this.prayerName,
  });

  final AdhanAdhkarRepository repository;
  final String? prayerName;

  @override
  State<AfterAdhanScreen> createState() => _AfterAdhanScreenState();
}

class _AfterAdhanScreenState extends State<AfterAdhanScreen> {
  late final Future<Result<List<AzkarItemModel>>> _items = widget.repository
      .getAdhanAdhkar();

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    return SakinaHeroScaffold(
      title: l10n.afterAdhanTitle,
      slivers: [
        FutureBuilder<Result<List<AzkarItemModel>>>(
          future: _items,
          builder: (context, snapshot) {
            final result = snapshot.data;
            if (result == null) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: PulseLoader(lines: 5)),
              );
            }
            return switch (result) {
              Err(:final failure) => SliverFillRemaining(
                hasScrollBody: false,
                child: StatusView.error(message: failureMessage(failure)),
              ),
              Success(:final value) => SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.page),
                sliver: SliverList.list(
                  children: [
                    if (widget.prayerName case final name?)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                            colors: SakinaDecor.of(context).heroColors,
                          ),
                          borderRadius: AppRadius.hero,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: GeometricPattern(
                                pattern: SakinaDecor.of(context).pattern,
                                color: SakinaDecor.of(
                                  context,
                                ).onFeature.withValues(alpha: 0.08),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.lg,
                              ),
                              child: Text(
                                l10n.prayerTimeArrived(name),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: SakinaDecor.of(context).onFeature,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final item in value)
                      SakinaCard(
                        tone: SakinaCardTone.tinted,
                        margin: const EdgeInsets.only(bottom: AppSpacing.ms),
                        padding: const EdgeInsets.all(
                          AppSpacing.md + AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DhikrTextBlock(item: item),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.reference,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            };
          },
        ),
      ],
    );
  }
}
