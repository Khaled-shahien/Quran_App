import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/theme/app_design.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/guide_entities.dart';
import '../providers/islamic_guide_provider.dart';

class GuideItemCard extends StatelessWidget {
  const GuideItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  final GuideItem item;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: SakinaDecor.of(context).card,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : AppShadows.subtle,
      ),
      child: Theme(
        // Removes the default divider lines ExpansionTile draws.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Its own PageStorage slot: without a key it shares the list's
          // slot, reads the saved scroll offset as its open state and
          // crashes after scrolling back.
          key: PageStorageKey<String>('guide-item-${item.title}'),
          initiallyExpanded: initiallyExpanded,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: AppRadius.card,
          ),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          expansionAnimationStyle: AnimationStyle(
            duration: AppMotion.of(context, AppMotion.base),
            curve: AppMotion.standard,
          ),
          iconColor: scheme.primary,
          collapsedIconColor: scheme.primary,
          title: Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: _subtitle(theme),
          children: <Widget>[
            for (final GuideBlock block in item.blocks) _BlockView(block),
          ],
        ),
      ),
    );
  }

  Widget? _subtitle(ThemeData theme) {
    if (item.subtitle == null && item.badges.isEmpty) return null;
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (item.subtitle != null)
            Text(
              item.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          for (final String badge in item.badges)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: scheme.secondary,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                badge,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView(this.block);

  final GuideBlock block;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? body = theme.textTheme.bodyMedium?.copyWith(
      height: 1.7,
      color: scheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              block.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (block.text != null) Text(block.text!, style: body),
          if (block.steps.isNotEmpty) _StepsView(steps: block.steps),
          if (block.dua != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _DuaView(text: block.dua!),
          ],
          for (final QuranRef ref in block.quran) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _QuranRefView(reference: ref),
          ],
          if (block.source != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10nOf(context).guideSource(block.source!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepsView extends StatelessWidget {
  const _StepsView({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(
                  child: Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(top: AppSpacing.xxs),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Semantics(
                    label: '${i + 1}. ${steps[i]}',
                    excludeSemantics: true,
                    child: Text(
                      steps[i],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                        color: scheme.onSurface,
                      ),
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

class _DuaView extends StatelessWidget {
  const _DuaView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: AppRadius.controls,
        border: BorderDirectional(
          start: BorderSide(color: SakinaDecor.of(context).accent, width: 3),
        ),
      ),
      // SelectionArea rather than SelectableText: the latter owns a
      // Scrollable that collides with ExpansionTile's PageStorage slot.
      child: SelectionArea(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.script.copyWith(
            fontSize: 19,
            height: 1.9,
            fontWeight: FontWeight.w400,
            color: scheme.onSecondary,
          ),
        ),
      ),
    );
  }
}

class _QuranRefView extends StatefulWidget {
  const _QuranRefView({required this.reference});

  final QuranRef reference;

  @override
  State<_QuranRefView> createState() => _QuranRefViewState();
}

class _QuranRefViewState extends State<_QuranRefView> {
  late Future<List<GuideVerse>> _verses;

  @override
  void initState() {
    super.initState();
    _verses = _load();
  }

  Future<List<GuideVerse>> _load() =>
      context.read<IslamicGuideProvider>().versesFor(widget.reference);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: AppRadius.controls,
      ),
      child: FutureBuilder<List<GuideVerse>>(
        future: _verses,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final List<GuideVerse>? verses = snapshot.data;
          if (snapshot.hasError || verses == null || verses.isEmpty) {
            return Row(
              children: <Widget>[
                Icon(Icons.error_outline, color: scheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10nOf(context).guideQuranLoadError,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _verses = _load()),
                  child: Text(l10nOf(context).retry),
                ),
              ],
            );
          }

          final String text = verses
              .map((v) => '${v.text} \uFD3F${_arabicDigits(v.ayah)}\uFD3E')
              .join(' ');
          final GuideVerse first = verses.first;
          final String range = widget.reference.from == widget.reference.to
              ? _arabicDigits(first.ayah)
              : '${_arabicDigits(widget.reference.from)}–'
                    '${_arabicDigits(widget.reference.to)}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SelectionArea(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTypography.script.copyWith(
                    fontSize: 20,
                    height: 2,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '[${first.surahName}: $range]',
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _arabicDigits(int value) {
  const String digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((c) => digits[int.parse(c)]).join();
}
