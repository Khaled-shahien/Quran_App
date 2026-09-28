import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../khatma/domain/models/khatma_model.dart';
import '../../../khatma/domain/models/wird_reading_position.dart';
import '../../../khatma/domain/services/khatma_quran_locator.dart';
import '../../../quran/domain/entities/surah_entity.dart';
import '../../../quran/domain/repositories/surah_repository.dart';
import 'package:provider/provider.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';

class _WirdPreviewData {
  final String ayahText;
  final String reference;

  const _WirdPreviewData({required this.ayahText, required this.reference});
}

class CurrentWirdWidget extends StatelessWidget {
  const CurrentWirdWidget({super.key});

  static final KhatmaQuranLocator _quranLocator = KhatmaQuranLocator();

  static const String _completedWirdMessage =
      'تم إتمام ورد اليوم، '
      'انتقل إلى الورد التالي';
  static const String _completedKhatmaMessage =
      'تم إتمام الختمة بنجاح، بارك الله فيك';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Colors from the design
    final Color cardBgColor = isDarkMode
        ? AppColors.darkCardContent
        : Colors.white;
    final Color accentYellow = isDarkMode
        ? AppColors.darkSecondary
        : const Color(0xFFF9D030); // Yellow button
    final Color finishedBtnText = isDarkMode ? Colors.white : Colors.black87;
    final Color textDark = isDarkMode ? Colors.white : const Color(0xFF4A4A4A);
    final Color dividerColor = isDarkMode
        ? AppColors.darkGray
        : const Color(0xFFE5E5E5);
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Consumer<KhatmaProvider>(
      builder: (context, khatmaProvider, child) {
        final activeKhatma = khatmaProvider.activeKhatma;
        final WirdReadingPosition? savedPosition = activeKhatma == null
            ? null
            : khatmaProvider.savedWirdPositionFor(activeKhatma);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Title
              Text(
                'الورد الحالي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),

              if (activeKhatma != null) ...[
                // Main Card
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: AppRadius.card,
                    boxShadow: AppShadows.card,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Top Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'من قوله تعالى',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            Text(
                              'الجزء ${activeKhatma.currentJuz}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Dynamic first ayah preview for current wird range.
                        _AnimatedWirdAyahPreview(
                          cacheKey:
                              '${activeKhatma.id}_'
                              '${activeKhatma.todayFromUnit}_'
                              '${activeKhatma.todayToUnit}',
                          textColor: textDark,
                          loader: () => _loadCurrentWirdPreview(
                            context: context,
                            khatma: activeKhatma,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Details Row 1 (Start)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'بدء الختمة: ${activeKhatma.startMode}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              '${activeKhatma.amountValue} / يوم',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ورد اليوم: '
                          'من ${activeKhatma.todayFromUnit} '
                          'إلى ${activeKhatma.todayToUnit} '
                          '(${activeKhatma.amountType})',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textDark.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        if (savedPosition != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  'يوجد موضع محفوظ لاستكمال الورد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.bookmark,
                                size: 16,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            // Finished Button (Yellow)
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await khatmaProvider
                                      .markCurrentWirdAsFinished();
                                  if (!context.mounted) return;

                                  final nextKhatma =
                                      khatmaProvider.activeKhatma;
                                  final bool stillActive =
                                      nextKhatma != null &&
                                      !nextKhatma.isCompleted;

                                  final String message = stillActive
                                      ? _completedWirdMessage
                                      : _completedKhatmaMessage;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        message,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentYellow,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chevron_left,
                                      color: finishedBtnText,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'أتممت القراءة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: finishedBtnText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Read Button (Green)
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _openWirdAtStart(
                                    context: context,
                                    khatma: activeKhatma,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'اقرأ الورد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: dividerColor, thickness: 1),
                const SizedBox(height: 16),

                // Khatma Details (Progress Section)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الختمة الحالية',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'إلغاء الختمة',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                                content: const Text(
                                  'هل أنت متأكد من '
                                  'إلغاء الختمة الحالية؟',
                                  style: TextStyle(fontFamily: 'Cairo'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'تراجع',
                                      style: TextStyle(fontFamily: 'Cairo'),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      khatmaProvider.cancelKhatma();
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'نعم، إلغاء',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                _KhatmaProgressBar(
                  progress: activeKhatma.progress,
                  fillColor: primaryColor,
                  trackColor: dividerColor,
                ),
                const SizedBox(height: 12),

                // Progress Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المتبقي: ${activeKhatma.remainingUnits.ceil()} '
                      '${activeKhatma.amountType}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    Text(
                      'الإنجاز: '
                      '${(activeKhatma.progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Empty State (No Active Khatma)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 48,
                        color: primaryColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد ختمة نشطة حالياً',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ابدأ ختمة جديدة '
                        'وتابع وردك اليومي بسهولة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: textDark.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.push('/khatma/location');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ابدأ ختمة جديدة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWirdAtStart({
    required BuildContext context,
    required KhatmaModel khatma,
  }) async {
    final SurahRepository surahRepository = Provider.of<SurahRepository>(
      context,
      listen: false,
    );
    final KhatmaProvider khatmaProvider = Provider.of<KhatmaProvider>(
      context,
      listen: false,
    );
    final WirdReadingPosition? savedPosition = khatmaProvider
        .savedWirdPositionFor(khatma);

    final int targetSurahNumber;
    final int targetAyahNumber;
    if (savedPosition != null) {
      targetSurahNumber = savedPosition.surahNumber;
      targetAyahNumber = savedPosition.ayahNumber;
    } else {
      final KhatmaAyahPosition position = await _quranLocator
          .resolvePositionFromStoredOrUnit(khatma: khatma);
      targetSurahNumber = position.surahNumber;
      targetAyahNumber = position.ayahNumber;
    }

    final List<SurahEntity> surahs = await surahRepository.getAllSurahs();
    if (surahs.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تحميل بيانات السور')));
      return;
    }

    final SurahEntity targetSurah = surahs.firstWhere(
      (surah) => surah.number == targetSurahNumber,
      orElse: () => surahs.first,
    );

    if (!context.mounted) return;

    context.push(
      '/quran/surah/${targetSurah.number}',
      extra: <String, dynamic>{
        'surah': targetSurah,
        'initialSurahNumber': targetSurahNumber,
        'initialAyahNumber': targetAyahNumber,
        'rangeTrackingUnit': khatma.trackingUnit.storageValue,
        'rangeFromUnit': khatma.todayFromUnit,
        'rangeToUnit': khatma.todayToUnit,
      },
    );
  }

  Future<_WirdPreviewData> _loadCurrentWirdPreview({
    required BuildContext context,
    required KhatmaModel khatma,
  }) async {
    final KhatmaAyahPosition position = await _quranLocator
        .resolvePositionFromStoredOrUnit(khatma: khatma);

    return _WirdPreviewData(
      ayahText: position.ayahText.isEmpty
          ? 'تعذر تحميل آية الورد'
          : position.ayahText,
      reference:
          '${position.surahName} - الآية ${position.ayahNumber} - صفحة ${position.pageNumber}',
    );
  }
}

class _KhatmaProgressBar extends StatelessWidget {
  final double progress;
  final Color fillColor;
  final Color trackColor;

  const _KhatmaProgressBar({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final double safeProgress = progress.clamp(0.0, 1.0).toDouble();

    Widget buildBar(double value) {
      return ClipRRect(
        borderRadius: AppRadius.pill,
        child: LinearProgressIndicator(
          value: value,
          minHeight: 10,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      );
    }

    if (MediaQuery.of(context).disableAnimations) {
      return buildBar(safeProgress);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: safeProgress),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => buildBar(value),
    );
  }
}

class _AnimatedWirdAyahPreview extends StatefulWidget {
  final String cacheKey;
  final Color textColor;
  final Future<_WirdPreviewData> Function() loader;

  const _AnimatedWirdAyahPreview({
    required this.cacheKey,
    required this.textColor,
    required this.loader,
  });

  @override
  State<_AnimatedWirdAyahPreview> createState() =>
      _AnimatedWirdAyahPreviewState();
}

class _AnimatedWirdAyahPreviewState extends State<_AnimatedWirdAyahPreview> {
  _WirdPreviewData? _current;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _AnimatedWirdAyahPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final _WirdPreviewData data = await widget.loader();
      if (!mounted) return;
      setState(() {
        _current = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _WirdPreviewData display =
        _current ??
        const _WirdPreviewData(
          ayahText: 'جاري تحميل آية الورد...',
          reference: '',
        );

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Column(
            key: ValueKey<String>('${display.reference}_${display.ayahText}'),
            children: [
              Text(
                display.ayahText,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (display.reference.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  display.reference,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        if (_isLoading && _current != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 48,
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: widget.textColor.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
    );
  }
}
