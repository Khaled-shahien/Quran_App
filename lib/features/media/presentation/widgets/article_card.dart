import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/features/media/domain/entities/article.dart';
import 'package:sakina_app/core/widgets/external_link_confirmation.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: () => _openArticle(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      article.sourceName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                article.title,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (article.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  article.description,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(article.pubDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openArticle(BuildContext context) async {
    final outcome = await openExternalLinkWithConsent(context, article.link);
    if (outcome == ExternalLinkOutcome.failed && context.mounted) {
      _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10nOf(context).articleCardMessage1,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
