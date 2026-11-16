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
            ],
          ),
        ),
      ],
    );
  }
}
