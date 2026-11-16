import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/sakina_card.dart';

/// The media library's three destinations.
class MediaTilesWidget extends StatelessWidget {
  const MediaTilesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return SliverList.list(
      children: [
        _MediaTile(
          title: l10n.articlesScreenMessage1,
          icon: Icons.article_outlined,
          route: '/media/articles',
        ),
        _MediaTile(
          title: l10n.audioScreenMessage1,
          icon: Icons.graphic_eq_rounded,
          route: '/media/audio',
        ),
        _MediaTile(
          title: l10n.videoScreenMessage1,
          icon: Icons.video_library_outlined,
          route: '/media/videos',
        ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SakinaCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.xs + AppSpacing.xxs,
      ),
      onTap: () => context.push(route),
      semanticLabel: title,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondary,
              borderRadius: AppRadius.controls,
            ),
            child: Icon(icon, color: scheme.primary, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
