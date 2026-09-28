import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/pulse_loader.dart';
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

    try {
      final surahs = await _repository.getAllSurahs();
      setState(() {
        _surahs = surahs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final Color cardBackground = theme.colorScheme.surface;
    final Color accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              stretch: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              leading: Semantics(
                button: true,
                label: 'الرجوع للشاشة السابقة',
                child: IconButton(
                  tooltip: 'رجوع',
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                centerTitle: true,
                title: Text(
                  'القرآن الكريم',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 24),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 92,
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'إعادة تحميل السور',
                  child: ElevatedButton(
                    onPressed: _loadSurahs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            ),
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
            return RepaintBoundary(
              child: AnimatedEntrance(
                delay: Duration(milliseconds: (index > 8 ? 8 : index) * 30),
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
              ),
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
      return 'مكية';
    } else if (normalizedPlace == 'madina' ||
        normalizedPlace == 'medinan' ||
        normalizedPlace == 'md') {
      return 'مدنية';
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
    return Semantics(
      button: true,
      label: 'سورة $arabicName، عدد الآيات $versesCount، $type',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: AppRadius.card,
          border: Border.all(color: accentColor.withValues(alpha: 0.28)),
          boxShadow: AppShadows.subtle,
        ),
        child: Material(
          color: cardBackground,
          borderRadius: AppRadius.card,
          child: InkWell(
            borderRadius: AppRadius.card,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arabicName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          englishName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: accentColor.withAlpha((0.8 * 255).round()),
                          ),
                        ),
                        Text(
                          translation,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$versesCount آية',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
