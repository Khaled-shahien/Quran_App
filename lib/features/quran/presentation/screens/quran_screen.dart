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
import '../../../../core/widgets/sakina_segmented.dart';
import '../../../../core/widgets/status_view.dart';
import '../../data/data_sources/quran_master_asset.dart';
import '../../domain/entities/surah_entity.dart';
import '../../domain/repositories/surah_repository.dart';
import '../../domain/services/quran_divisions.dart';

/// The Quran index: the 114 surahs, or the 30 juz or 60 hizb of the
/// mushaf, and a "go to" for a page or a verse.
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

  /// 0 surahs, 1 juz, 2 hizb.
  int _view = 0;
  QuranDivisions? _divisions;
  bool _divisionsFailed = false;

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

  /// Builds the juz/hizb/page index the first time it is needed.
  Future<QuranDivisions?> _loadDivisions() async {
    if (_divisions != null) return _divisions;
    try {
      final QuranDivisions divisions = QuranDivisions.fromSurahs(
        await QuranMasterAsset.load(),
      );
      if (mounted) {
        setState(() {
          _divisions = divisions;
          _divisionsFailed = false;
        });
      }
      return divisions;
    } catch (_) {
      if (mounted) setState(() => _divisionsFailed = true);
      return null;
    }
  }

  void _selectView(int view) {
    setState(() => _view = view);
    if (view != 0) _loadDivisions();
  }

  void _openVerse(int surah, int ayah) {
    final SurahEntity? entity = surah >= 1 && surah <= _surahs.length
        ? _surahs[surah - 1]
        : null;
    context.push(
      '/quran/surah/$surah',
      extra: <String, dynamic>{
        if (entity != null) 'surah': entity,
        'initialAyahNumber': ayah,
      },
    );
  }

  int _ayahCount(int surah) =>
      surah >= 1 && surah <= _surahs.length ? _surahs[surah - 1].totalAyah : 0;

  Future<void> _showGoTo() async {
    final l10n = l10nOf(context);
    final QuranGoTo? target = await showDialog<QuranGoTo>(
      context: context,
      builder: (_) => _GoToDialog(parse: (t) => parseQuranGoTo(t, _ayahCount)),
    );
    if (target == null || !mounted) return;
    switch (target) {
      case QuranGoToVerse(:final surah, :final ayah):
        _openVerse(surah, ayah);
      case QuranGoToPage(:final page):
        final QuranDivisions? divisions = await _loadDivisions();
        final QuranDivisionStart? start = divisions?.pageStart(page);
        if (!mounted) return;
        if (start == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.quranIndexLoadFailed)));
          return;
        }
        _openVerse(start.surah, start.ayah);
    }
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
              actions: [
                if (!_isLoading && _error == null)
                  IconButton(
                    tooltip: l10nOf(context).quranGoTo,
                    icon: const Icon(Icons.manage_search_rounded),
                    onPressed: _showGoTo,
                  ),
              ],
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

    final l10n = l10nOf(context);
    return [
      SliverToBoxAdapter(
        child: SakinaSegmented(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          labels: [
            l10n.quranIndexSurahs,
            l10n.quranIndexJuz,
            l10n.quranIndexHizb,
          ],
          selectedIndex: _view,
          onChanged: _selectView,
        ),
      ),
      if (_view == 0)
        _buildSurahList(accentColor, cardBackground, theme)
      else
        _buildDivisionList(theme, accentColor),
    ];
  }

  Widget _buildDivisionList(ThemeData theme, Color accentColor) {
    final l10n = l10nOf(context);
    final QuranDivisions? divisions = _divisions;
    if (divisions == null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _divisionsFailed
            ? StatusView.error(
                message: l10n.quranIndexLoadFailed,
                actionLabel: appL10n.retry,
                onAction: _loadDivisions,
              )
            : const Center(child: PulseLoader(lines: 6)),
      );
    }
    final bool juz = _view == 1;
    final List<QuranDivisionStart> starts = juz
        ? divisions.juz
        : divisions.hizb;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      sliver: SliverList.builder(
        itemCount: starts.length,
        itemBuilder: (context, index) {
          final QuranDivisionStart start = starts[index];
          final String number = context.digits(start.number);
          final String surahName = start.surah <= _surahs.length
              ? _surahs[start.surah - 1].name
              : context.digits(start.surah);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.ms),
            child: SakinaCard(
              onTap: () => _openVerse(start.surah, start.ayah),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.ms,
              ),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 46,
                    child: CustomPaint(
                      painter: _StarBadgePainter(accentColor),
                      child: Center(
                        child: Text(
                          number,
                          style: theme.textTheme.labelLarge?.copyWith(
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
                          juz
                              ? l10n.quranJuzTitle(number)
                              : l10n.quranHizbTitle(number),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.quranDivisionStart(
                            surahName,
                            context.digits(start.ayah),
                            context.digits(start.page),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSurahList(
    Color accentColor,
    Color cardBackground,
    ThemeData theme,
  ) {
    return SliverPadding(
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
    );
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

/// Asks for a page number or a surah:ayah reference.
class _GoToDialog extends StatefulWidget {
  const _GoToDialog({required this.parse});

  final QuranGoTo? Function(String text) parse;

  @override
  State<_GoToDialog> createState() => _GoToDialogState();
}

class _GoToDialogState extends State<_GoToDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final QuranGoTo? target = widget.parse(_controller.text);
    if (target == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return AlertDialog(
      title: Text(l10n.quranGoTo),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _submit(),
        onChanged: (_) {
          if (_invalid) setState(() => _invalid = false);
        },
        decoration: InputDecoration(
          labelText: l10n.quranGoToLabel,
          hintText: l10n.quranGoToHint,
          errorText: _invalid ? l10n.quranGoToInvalid : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.appStringsMessage9),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.quranGoToAction)),
      ],
    );
  }
}
