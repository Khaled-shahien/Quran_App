import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';

/// The home screen's grid of destinations.
class CategoryGridWidget extends StatelessWidget {
  const CategoryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final tiles = <_Tile>[
      _Tile(l10n.appStringsMessage30, '/duas/all', image: 'الادعيه'),
      _Tile(
        l10n.categoryGridWidgetMessage1,
        '/tasbeeh',
        image: 'التسبيح_الالكتروني',
      ),
      _Tile(
        l10n.categoryGridWidgetMessage2,
        '/asma',
        image: 'اسماء_الله_الحسني',
      ),
      _Tile(l10n.appStringsMessage28, '/quran', image: 'القران'),
      _Tile(l10n.mainNavigationShellMessage2, '/duas', image: 'الاذكار'),
      _Tile(l10n.categoryGridWidgetMessage3, '/hadeath', image: 'الاحاديث'),
      _Tile(
        l10n.guideTileProphets,
        '/guide?section=prophets',
        image: 'الانبياء',
      ),
      _Tile(l10n.guideTilePrayer, '/guide?section=prayer', image: 'صفة_الصلاة'),
      _Tile(
        l10n.guideTilePillars,
        '/guide?section=pillars',
        image: 'اركان_الدين',
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      sliver: SliverGrid.builder(
        // Three columns normally; two taller ones when large text needs room.
        gridDelegate: textScale <= 1.15
            ? const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.ms,
                crossAxisSpacing: AppSpacing.ms,
                childAspectRatio: 0.86,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.ms,
                crossAxisSpacing: AppSpacing.ms,
                mainAxisExtent: 84 + 48 * textScale,
              ),
        itemCount: tiles.length,
        itemBuilder: (context, index) => _CategoryTile(tile: tiles[index]),
      ),
    );
  }
}

class _Tile {
  const _Tile(this.title, this.route, {required this.image});

  final String title;
  final String route;

  /// File name (without extension) under `assets/images/`.
  final String image;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.tile});

  final _Tile tile;

  static const double _medallion = 56;
  static const double _art = 34;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);

    return Pressable(
      onTap: () => context.push(tile.route),
      color: scheme.secondary,
      semanticLabel: tile.title,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.ms,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _medallion,
              height: _medallion,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadius.card,
              ),
              child: Image.asset(
                'assets/images/${tile.image}.png',
                width: _art,
                height: _art,
                fit: BoxFit.contain,
                // Decode at display size, not the source size.
                cacheWidth: (_art * pixelRatio).round(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: Text(
                tile.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
