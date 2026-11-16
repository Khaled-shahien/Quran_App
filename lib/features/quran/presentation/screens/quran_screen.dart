import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/result/failure_messages.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../../../../core/theme/app_design.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/pulse_loader.dart';
import '../../../../core/widgets/sakina_hero_app_bar.dart';
import '../../../../core/widgets/sakina_card.dart';
import '../../../../core/widgets/status_view.dart';
import '../../domain/entities/surah_entity.dart';
import '../../domain/repositories/surah_repository.dart';

/// Quran Screen
///
/// Displays the list of all 114 Surahs in the Quran with their details.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SurahRepository>(
      builder: (context, repository, child) {
        return _QuranScreenContent(repository: repository);
      },
    );
  }
}

class _QuranScreenContent extends StatefulWidget {
  final SurahRepository repository;

  const _QuranScreenContent({required this.repository});

  @override
  State<_QuranScreenContent> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<_QuranScreenContent> {
  late SurahRepository _repository;
  List<SurahEntity> _surahs = <SurahEntity>[];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repository.getAllSurahs();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Success(:final value):
          _surahs = value;
        case Err(:final failure):
          // Friendly copy; the technical cause is never shown.
          _error = failureMessage(failure);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SakinaDecor decor = SakinaDecor.of(context);
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color cardBackground = decor.card;
    final Color accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SakinaHeroAppBar(
              title: l10nOf(context).continueReadingCardMessage2,
              backTooltip: l10nOf(context).appStringsMessage13,
            ),
            ..._buildBodySlivers(theme, accentColor, cardBackground),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBodySlivers(
    ThemeData theme,
    Color accentColor,
    Color cardBackground,
  ) {
    if (_isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: PulseLoader(lines: 8)),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StatusView.error(
            message: _error!,
            actionLabel: appL10n.retry,
            actionSemanticLabel: appL10n.quranScreenMessage1,
            onAction: _loadSurahs,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        sliver: SliverList.builder(
          itemCount: _surahs.length,
          itemBuilder: (context, index) {
            final surah = _surahs[index];
            final Widget card = RepaintBoundary(
              child: SurahCard(
                index: index + 1,
                arabicName: surah.name,
                englishName: surah.englishName,
                translation: surah.englishNameTranslation,
                versesCount: surah.totalAyah,
                type: _getRevelationPlaceArabic(surah.revelationType),
                accentColor: accentColor,
                cardBackground: cardBackground,
                textColor: theme.colorScheme.onSurface,
                secondaryTextColor: theme.colorScheme.onSurfaceVariant,
                onTap: () => _onSurahTap(context, surah, index + 1),
              ),
            );
            // Only the first screenful enters in sequence; rows scrolled
            // into view later appear at once.
            if (index > 7) return card;
            return AnimatedEntrance(
              delay: AppMotion.stagger * index,
              child: card,
            );
          },
        ),
      ),
    ];
  }

  String _getRevelationPlaceArabic(String revelationPlace) {
    final normalizedPlace = revelationPlace.toLowerCase();
    if (normalizedPlace == 'mecca' ||
        normalizedPlace == 'meccan' ||
        normalizedPlace == 'mc') {
      return appL10n.quranScreenMessage2;
    } else if (normalizedPlace == 'madina' ||
        normalizedPlace == 'medinan' ||
        normalizedPlace == 'md') {
      return appL10n.quranScreenMessage3;
    }
    return revelationPlace;
  }

  void _onSurahTap(BuildContext context, SurahEntity surah, int number) {
    context.push(
      '/quran/surah/$number',
      extra: <String, dynamic>{'surah': surah},
    );
  }
}

class SurahCard extends StatelessWidget {
  final int index;
  final String arabicName;
  final String englishName;
  final String translation;
  final int versesCount;
  final String type;
  final Color accentColor;
  final Color cardBackground;
  final Color textColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.index,
    required this.arabicName,
    required this.englishName,
    required this.translation,
    required this.versesCount,
    required this.type,
    required this.accentColor,
    required this.cardBackground,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: l10nOf(context).quranScreenMessage4(
        (arabicName).toString(),
        context.digits(versesCount),
        (type).toString(),
      ),
      excludeSemantics: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.ms),
        child: SakinaCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.ms,
          ),
          child: Row(
            children: [
              // The surah number sits in an eight-pointed star, the same
              // ornament the headers use.
              SizedBox.square(
                dimension: 46,
                child: CustomPaint(
                  painter: _StarBadgePainter(accentColor),
                  child: Center(
                    child: Text(
                      context.digits(index),
                      style: text.labelLarge?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arabicName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$englishName · $translation',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.end,
                      style: text.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(color: accentColor),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10nOf(
                        context,
                      ).quranScreenMessage5(context.digits(versesCount)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An eight-pointed star outline: two squares, one turned 45 degrees.
class _StarBadgePainter extends CustomPainter {
  const _StarBadgePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final Offset center = size.center(Offset.zero);
    final double side = size.shortestSide * 0.68;
    final Rect square = Rect.fromCenter(
      center: center,
      width: side,
      height: side,
    );
    final RRect rounded = RRect.fromRectAndRadius(
      square,
      const Radius.circular(AppRadius.xs),
    );
    canvas.drawRRect(rounded, paint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.785398);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRRect(rounded, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarBadgePainter oldDelegate) =>
      oldDelegate.color != color;
}
