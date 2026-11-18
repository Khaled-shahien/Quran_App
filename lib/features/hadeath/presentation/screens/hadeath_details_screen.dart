import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/hadeath_entity.dart';

class HadeathDetailsScreen extends StatelessWidget {
  final HadeathEntity hadeath;

  const HadeathDetailsScreen({super.key, required this.hadeath});

  @override
  Widget build(BuildContext context) {
    return SakinaHeroScaffold(
      title: hadeath.title.replaceAll('  ', ' ').trim(),
      slivers: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: SliverList.list(
            children: [
              // شريط البسملة الداخلي ليتماشى
              // مع تصميم السور لو أحببنا
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: AppRadius.controls,
                ),
                width: double.infinity,
                child: Text(
                  l10nOf(context).hadeathDetailsScreenMessage1,
                  textAlign: TextAlign.center,
                  style: AppTypography.script.copyWith(
                    fontSize: 17,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),

              // محتوى الحديث
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Text(
                  hadeath.content.join(
                    ' ',
                  ), // Join lines with spaces as it's continuous text
                  textAlign: TextAlign.justify,
                  // Long reading text: the script face in the body ink,
                  // which is easier on the eye than the accent colour.
                  style: AppTypography.script.copyWith(
                    fontSize: 22,
                    height: 2,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (hadeath.study case final study?)
                HadeathStudyView(study: study),
            ],
          ),
        ),
      ],
    );
  }
}

/// What the source says about the hadith, each part under its heading.
class HadeathStudyView extends StatelessWidget {
  const HadeathStudyView({super.key, required this.study});

  final HadeathStudy study;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    Widget section(String title, Widget body) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          body,
        ],
      ),
    );
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section(l10n.hadithGrade, Text(study.grade, style: bodyStyle)),
        section(
          l10n.hadithAttribution,
          Text(study.attribution, style: bodyStyle),
        ),
        section(
          l10n.hadithExplanation,
          Text(
            study.explanation,
            textAlign: TextAlign.justify,
            style: bodyStyle,
          ),
        ),
        if (study.hints.isNotEmpty)
          section(
            l10n.hadithLessons,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final hint in study.hints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: 10,
                            end: AppSpacing.sm,
                          ),
                          child: Icon(Icons.circle, size: 6),
                        ),
                        Expanded(child: Text(hint, style: bodyStyle)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        section(
          l10n.hadithReferences,
          Text(study.reference, style: theme.textTheme.bodyMedium),
        ),
        section(
          l10n.hadithSourceTitle,
          Text(l10n.hadithSource, style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}
