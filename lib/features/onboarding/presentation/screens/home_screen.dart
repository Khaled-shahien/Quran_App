import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../khatma/domain/models/khatma_model.dart';
import '../../../khatma/domain/services/khatma_quran_locator.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';
import '../../../quran/domain/entities/surah_entity.dart';
import '../../../quran/domain/repositories/surah_repository.dart';
import '../../../quran/presentation/providers/bookmark_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/current_wird_widget.dart';
import '../widgets/daily_verse_section_widget.dart';
import '../widgets/tab_switcher_widget.dart';
import '../widgets/category_grid_widget.dart';
import '../widgets/prayer_times_widget.dart';
import '../../../prayers/presentation/providers/'
    'prayer_times_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTabIndex = 0; // 0: جميع التصنيفات
  int drawerSubTab = 0; // 0 للمزيد، 1 للمفضلة
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final KhatmaQuranLocator _quranLocator = KhatmaQuranLocator();
  OverlayEntry? _messageEntry;

  @override
  void dispose() {
    final messageEntry = _messageEntry;
    _messageEntry = null;
    messageEntry?.remove();
    messageEntry?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prayerProvider = Provider.of<PrayerTimesProvider>(
        context,
        listen: false,
      );
      // Use the same saved configuration as the prayer screen.
      prayerProvider.fetchTodayForCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildNavigationDrawer(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            const SliverToBoxAdapter(
              child: AnimatedEntrance(
                delay: Duration(milliseconds: 100),
                child: CurrentWirdWidget(),
              ),
            ),
            const SliverToBoxAdapter(
              child: AnimatedEntrance(
                delay: Duration(milliseconds: 180),
                child: DailyVerseSectionWidget(),
              ),
            ),
            SliverToBoxAdapter(
              child: AnimatedEntrance(
                delay: const Duration(milliseconds: 260),
                child: TabSwitcherWidget(
                  onTabChanged: (index) {
                    setState(() {
                      selectedTabIndex = index;
                    });
                  },
                  selectedIndex: selectedTabIndex,
                ),
              ),
            ),

            // المحتوى المتغير
            _buildDynamicContent(),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'بحث',
        icon: const Icon(Icons.search, size: 26),
        onPressed: () => context.push('/quran/search'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        centerTitle: true,
        titlePadding: const EdgeInsetsDirectional.only(
          start: AppSpacing.xl,
          end: AppSpacing.xl,
          bottom: AppSpacing.md,
        ),
        title: Text(
          AppStrings.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: const _PrayerTimeHeader(),
      ),
      actions: [
        Semantics(
          button: true,
          label: 'فتح القائمة الجانبية',
          child: IconButton(
            icon: const Icon(Icons.segment, size: 30),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ),
      ],
    );
  }

  // --- 2. القائمة الجانبية المطورة ---
  Widget _buildNavigationDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // رأس القائمة الداكن
            Container(
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 20,
                right: 20,
                left: 20,
              ),
              color: AppColors.darkCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    button: true,
                    label: 'إغلاق القائمة الجانبية',
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.menu_book, color: Colors.white),
                  ),
                ],
              ),
            ),

            // مفتاح التبديل.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF634D43).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _drawerTabItem('المزيد', 0),
                    _drawerTabItem('المفضلة', 1),
                  ],
                ),
              ),
            ),

            // محتوى القائمة المتغير.
            Expanded(
              child: drawerSubTab == 0
                  ? _buildSettingsList()
                  : _buildFavoritesList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- مكونات واجهة المستخدم المساعدة ---

  Widget _drawerTabItem(String label, int index) {
    bool active = drawerSubTab == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: 'تبويب $label',
        child: GestureDetector(
          onTap: () => setState(() => drawerSubTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: active ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for the More (المزيد) Menu ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, right: 20, left: 20),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildMoreMenuItem({
    required String title,
    Widget? leadingIcon,
    Widget? trailingWidget,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon,
                const SizedBox(width: 16),
              ],
              if (leadingIcon == null) const SizedBox(width: 40),

              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 16),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenuSwitch({
    required String title,
    required String subtitle,
    required Widget leadingIcon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? rightSubtitle,
  }) {
    return Semantics(
      label: title,
      toggled: value,
      value: value ? 'مفعل' : 'معطل',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // Right Side: Icon
            leadingIcon,
            const SizedBox(width: 16),

            // Middle: Text
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // start in RTL is right
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Left Side: Switch & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.end, // end in RTL is left
              children: [
                SizedBox(
                  height: 30,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                if (rightSubtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    rightSubtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureMessage(String message) {
    _showOverlayMessage(message);
  }

  void _showOverlayMessage(
    String message, {
    Color backgroundColor = AppColors.primary,
  }) {
    _messageEntry?.remove();
    _messageEntry?.dispose();

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Positioned(
          left: 16,
          right: 16,
          bottom: bottomPadding + 16,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: GoogleFonts.cairo(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
    _messageEntry = entry;
    overlay.insert(entry);

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (_messageEntry == entry) {
        entry.remove();
        entry.dispose();
        _messageEntry = null;
      }
    });
  }

  void _showKhatmaWirdSheet({required bool showCompleted}) {
    final khatmaProvider = Provider.of<KhatmaProvider>(context, listen: false);
    final activeKhatma = khatmaProvider.activeKhatma;

    if (activeKhatma == null) {
      _showFeatureMessage('لا توجد ختمة نشطة حالياً');
      return;
    }

    final int duration = activeKhatma.durationDays;
    final int completed = activeKhatma.completedDays.clamp(0, duration);
    final int remaining = (duration - completed).clamp(0, duration);
    final List<KhatmaCompletedWird> completedWirds = activeKhatma
        .completedWirds
        .reversed
        .toList();
    final int count = showCompleted ? completedWirds.length : remaining;
    final String title;
    if (showCompleted) {
      title = 'الأوراد السابقة';
    } else {
      title = 'الأوراد القادمة';
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showCompleted
                      ? 'عدد الأوراد المكتملة: $completed'
                      : 'عدد الأوراد المتبقية: $remaining',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                if (count == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      showCompleted
                          ? 'لم يتم إكمال أي ورد بعد.'
                          : 'لا توجد أوراد قادمة. '
                                'تم إنجاز الختمة بالكامل.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: count,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (showCompleted) {
                          final KhatmaCompletedWird wird =
                              completedWirds[index];
                          final DateTime at = wird.completedAt;
                          final String dateLabel =
                              '${at.year}/${at.month.toString().padLeft(2, '0')}/'
                              '${at.day.toString().padLeft(2, '0')}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'من ${wird.fromUnit} إلى ${wird.toUnit} (${activeKhatma.amountType})',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            subtitle: Text(
                              'مكتمل في $dateLabel',
                              style: GoogleFonts.cairo(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.65),
                              ),
                              textAlign: TextAlign.right,
                            ),
                            leading: Icon(
                              Icons.open_in_new,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _openWirdFromUnit(
                                khatma: activeKhatma,
                                unitIndex: wird.fromUnit,
                              );
                            },
                          );
                        }

                        final int wirdDay = completed + index + 1;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'ورد اليوم $wirdDay',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            'قادم',
                            style: GoogleFonts.cairo(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.65),
                            ),
                            textAlign: TextAlign.right,
                          ),
                          leading: Icon(
                            Icons.schedule,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWirdFromUnit({
    required KhatmaModel khatma,
    required int unitIndex,
  }) async {
    final SurahRepository surahRepository = Provider.of<SurahRepository>(
      context,
      listen: false,
    );
    final position = await _quranLocator.resolveStartPosition(
      trackingUnit: khatma.trackingUnit,
      unitIndex: unitIndex,
    );

    final List<SurahEntity> surahs = await surahRepository.getAllSurahs();
    if (surahs.isEmpty) {
      if (!mounted) return;
      _showFeatureMessage('تعذر تحميل بيانات السور');
      return;
    }

    final SurahEntity targetSurah = surahs.firstWhere(
      (surah) => surah.number == position.surahNumber,
      orElse: () => surahs.first,
    );

    if (!mounted) return;

    context.push(
      '/quran/surah/${targetSurah.number}',
      extra: <String, dynamic>{
        'surah': targetSurah,
        'initialSurahNumber': position.surahNumber,
        'initialAyahNumber': position.ayahNumber,
        'rangeTrackingUnit': khatma.trackingUnit.storageValue,
        'rangeFromUnit': unitIndex,
        'rangeToUnit': khatma.todayToUnit < unitIndex
            ? unitIndex
            : khatma.todayToUnit,
      },
    );
  }

  Future<void> _openSavedBookmark() async {
    final bookmarkProvider = Provider.of<BookmarkProvider>(
      context,
      listen: false,
    );

    if (!bookmarkProvider.hasBookmark) {
      _showFeatureMessage('لا يوجد فاصل محفوظ حالياً');
      context.push('/quran');
      return;
    }

    final int? surahNumber = bookmarkProvider.surahNumber;
    if (surahNumber == null) {
      _showFeatureMessage('تعذر فتح الفاصل المحفوظ');
      return;
    }

    try {
      final SurahRepository surahRepository = Provider.of<SurahRepository>(
        context,
        listen: false,
      );
      final List<SurahEntity> surahs = await surahRepository.getAllSurahs();

      final SurahEntity? targetSurah = surahs
          .where((surah) => surah.number == surahNumber)
          .cast<SurahEntity?>()
          .firstWhere((surah) => surah != null, orElse: () => null);

      if (!mounted) return;

      if (targetSurah == null) {
        _showFeatureMessage(
          'تعذر إيجاد السورة المرتبطة '
          'بالفاصل',
        );
        context.push('/quran');
        return;
      }

      context.push(
        '/quran/surah/$surahNumber',
        extra: <String, dynamic>{'surah': targetSurah},
      );
    } catch (_) {
      if (!mounted) return;
      _showFeatureMessage('حدث خطأ أثناء فتح الفاصل');
    }
  }

  Widget _buildSettingsList() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = themeProvider.isDarkMode;

    void showComingSoon() {
      _showOverlayMessage(
        'هذه الميزة ستتوفر '
        'قريباً إن شاء الله',
      );
    }

    Future<void> launchMyUrl(String url) async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showComingSoon(); // Fallback
      }
    }

    final Color iconColor = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _buildMoreMenuItem(
          title: 'الخصوصية ومصادر المحتوى',
          leadingIcon: Icon(Icons.privacy_tip_outlined, color: iconColor),
          onTap: () {
            Navigator.pop(context);
            context.push('/settings/data-sources');
          },
        ),
        // 2. الختمة الحالية
        _buildSectionHeader('الختمة الحالية'),
        _buildMoreMenuItem(
          title: 'الأوراد السابقة',
          leadingIcon: Icon(Icons.history, color: iconColor),
          onTap: () => _showKhatmaWirdSheet(showCompleted: true),
        ),
        _buildMoreMenuItem(
          title: 'الأوراد القادمة',
          leadingIcon: Icon(Icons.next_plan_outlined, color: iconColor),
          onTap: () => _showKhatmaWirdSheet(showCompleted: false),
        ),
        _buildMoreMenuItem(
          title: 'الفاصل',
          leadingIcon: Icon(Icons.bookmark_border, color: iconColor),
          onTap: _openSavedBookmark,
        ),
        const Divider(height: 1),

        // 3. كل الوسائط
        _buildSectionHeader('المكتبة'),
        _buildMoreMenuItem(
          title: 'كل الوسائط',
          leadingIcon: Icon(Icons.video_library, color: iconColor),
          onTap: () => context.push('/media'),
        ),
        const Divider(height: 1),

        // 4. سنن قرآنية
        _buildSectionHeader('سنن قرآنية'),
        _buildMoreMenuItem(
          title: 'سورة الكهف',
          leadingIcon: Icon(Icons.book, color: iconColor),
          onTap: () {
            context.push(
              '/quran/surah/18',
              extra: <String, dynamic>{
                'surah': SurahEntity(
                  number: 18,
                  name: 'سورة الكهف',
                  englishName: 'Al-Kahf',
                  englishNameTranslation: 'The Cave',
                  revelationType: 'Meccan',
                  totalAyah: 110,
                ),
              },
            );
          },
        ),
        _buildMoreMenuItem(
          title: 'سورة الملك',
          leadingIcon: Icon(Icons.menu_book, color: iconColor),
          onTap: () {
            context.push(
              '/quran/surah/67',
              extra: <String, dynamic>{
                'surah': SurahEntity(
                  number: 67,
                  name: 'سورة الملك',
                  englishName: 'Al-Mulk',
                  englishNameTranslation: 'The Sovereignty',
                  revelationType: 'Meccan',
                  totalAyah: 30,
                ),
              },
            );
          },
        ),
        _buildMoreMenuItem(
          title: 'سورة البقرة',
          leadingIcon: Icon(Icons.auto_stories, color: iconColor),
          onTap: () {
            context.push(
              '/quran/surah/2',
              extra: <String, dynamic>{
                'surah': SurahEntity(
                  number: 2,
                  name: 'سورة البقرة',
                  englishName: 'Al-Baqarah',
                  englishNameTranslation: 'The Cow',
                  revelationType: 'Medinan',
                  totalAyah: 286,
                ),
              },
            );
          },
        ),
        const Divider(height: 1),

        // 5. الإعدادات
        _buildSectionHeader('الإعدادات'),
        _buildMoreMenuSwitch(
          title: 'تفعيل الوضع الليلي',
          subtitle: 'تغيير مظهر التطبيق',
          leadingIcon: Icon(Icons.dark_mode_outlined, color: iconColor),
          value: isDark,
          onChanged: (v) {
            themeProvider.toggleTheme(v);
          },
        ),
        _buildMoreMenuItem(
          title: 'بدء ختمة جديدة',
          leadingIcon: Icon(Icons.add, color: iconColor),
          onTap: () => context.push('/khatma/location'),
        ),
        const Divider(height: 1),

        // 6. مواقيت الصلاة
        _buildSectionHeader('مواقيت الصلاة'),
        _buildMoreMenuItem(
          title: 'إعدادات مواقيت الصلاة',
          leadingIcon: Icon(Icons.mosque, color: iconColor),
          onTap: () => context.push('/prayers'),
        ),
        _buildMoreMenuItem(
          title: 'اتجاه القبلة',
          leadingIcon: Image.asset(
            'assets/images/kaaba.png',
            width: 24,
            height: 24,
            color: isDark ? Colors.white : null,
            errorBuilder: (c, e, s) => Icon(Icons.explore, color: iconColor),
          ),
          onTap: () {
            Navigator.pop(context);
            context.push('/qibla');
          },
        ),
        const Divider(height: 1),

        // 7. منبهات الأذكار
        _buildSectionHeader('منبهات الأذكار'),
        _buildMoreMenuSwitch(
          title: 'منبه أذكار الصباح',
          subtitle: 'وقت منبه أذكار الصباح',
          rightSubtitle: 'AM 07:00',
          leadingIcon: Icon(Icons.wb_sunny, color: iconColor),
          value: settingsProvider.isMorningAlarmEnabled,
          onChanged: (val) => settingsProvider.toggleMorningAlarm(val),
        ),
        _buildMoreMenuSwitch(
          title: 'منبه أذكار المساء',
          subtitle: 'وقت منبه أذكار المساء',
          rightSubtitle: 'PM 05:30',
          leadingIcon: Icon(Icons.nightlight_round, color: iconColor),
          value: settingsProvider.isEveningAlarmEnabled,
          onChanged: (val) => settingsProvider.toggleEveningAlarm(val),
        ),
        const Divider(height: 1),

        // 8. منبهات السنن
        _buildSectionHeader('منبهات السنن'),
        _buildMoreMenuSwitch(
          title: 'منبه سورة الملك',
          subtitle: 'وقت منبه سورة الملك',
          rightSubtitle: 'PM 09:00',
          leadingIcon: Icon(Icons.notifications, color: iconColor),
          value: settingsProvider.isMulkAlarmEnabled,
          onChanged: (val) => settingsProvider.toggleMulkAlarm(val),
        ),
        _buildMoreMenuSwitch(
          title: 'منبه سورة البقرة',
          subtitle: 'وقت منبه سورة البقرة',
          rightSubtitle: 'PM 08:30',
          leadingIcon: Icon(Icons.notifications, color: iconColor),
          value: settingsProvider.isBaqarahAlarmEnabled,
          onChanged: (val) => settingsProvider.toggleBaqarahAlarm(val),
        ),
        const Divider(height: 1),

        // 9. تطبيق ختمة
        _buildSectionHeader('تطبيق ختمة'),
        _buildMoreMenuItem(
          title: 'الصفحة الرئيسية',
          leadingIcon: Icon(Icons.home_outlined, color: iconColor),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        _buildMoreMenuItem(
          title: 'اللغة',
          leadingIcon: Icon(Icons.settings, color: iconColor),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(
                'إعدادات اللغة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              content: Text(
                'اللغة الحالية للتطبيق هي العربية. '
                'سيتم دعم لغات إضافية '
                'لاحقاً بإذن الله.',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.right,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('حسناً', style: GoogleFonts.cairo()),
                ),
              ],
            ),
          ),
        ),
        _buildMoreMenuItem(
          title: 'الإتصال بنا',
          leadingIcon: Icon(Icons.info_outline, color: iconColor),
          onTap: () => launchMyUrl(
            'mailto:contact@quranapp.com'
            '?subject=تطبيق ختمة - تواصل',
          ),
        ),
        _buildMoreMenuItem(
          title: 'تابعنا على تويتر',
          leadingIcon: const Icon(
            Icons.flutter_dash,
            color: Colors.lightBlue,
          ), // Placeholder for Twitter
          onTap: () => launchMyUrl('https://twitter.com/quranapp'),
        ),
        _buildMoreMenuItem(
          title: 'تابعنا على انستقرام',
          leadingIcon: const Icon(
            Icons.camera_alt,
            color: Colors.purple,
          ), // Placeholder for Instagram
          onTap: () => launchMyUrl('https://instagram.com/quranapp'),
        ),
        _buildMoreMenuItem(
          title: 'انشر التطبيق',
          leadingIcon: Icon(Icons.share, color: iconColor),
          onTap: () {
            SharePlus.instance.share(
              ShareParams(
                text:
                    'تطبيق سكينة - '
                    'تطبيق إسلامي شامل. '
                    'حمل الآن! \n(رابط التطبيق قريباً)',
              ),
            );
          },
        ),
        _buildMoreMenuItem(
          title: 'قيم تطبيق سكينة',
          leadingIcon: Icon(Icons.thumb_up_alt_outlined, color: iconColor),
          onTap: () => launchMyUrl(
            'https://play.google.com/store/apps/details?id=com.quranapp',
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesList() {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, child) {
        final favorites = favoritesProvider.favoriteVerses;

        if (favorites.isEmpty) {
          return Center(
            child: Text(
              'لا توجد آيات مفضلة',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final verse = favorites[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Semantics(
                        button: true,
                        label: 'إزالة الآية من المفضلة',
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.cancel,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            favoritesProvider.removeFavorite(verse);
                          },
                        ),
                      ),
                      Expanded(
                        child: Text(
                          verse['arabic'] ?? '',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse['surah'] ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  if (verse['english'] != null)
                    Text(
                      verse['english']!,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.left,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicContent() {
    if (selectedTabIndex == 0) {
      return const CategoryGridWidget();
    } else {
      return const SliverToBoxAdapter(child: PrayerTimesWidget());
    }
  }
}

class _PrayerTimeHeader extends StatelessWidget {
  const _PrayerTimeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, child) {
        final prayerData = provider.getCurrentAndNextPrayer();
        final currentName = prayerData['currentName'] ?? '---';
        final currentTime = prayerData['currentTime'] ?? '--:--';
        final nextName = prayerData['nextName'] ?? '---';
        final nextTime = prayerData['nextTime'] ?? '--:--';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.72),
                theme.colorScheme.tertiary.withValues(alpha: 0.58),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PositionedDirectional(
                top: -50,
                end: -20,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 170,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.08),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 52),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        currentName,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.78,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        currentTime,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onPrimary,
                          height: 1.05,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.18,
                            ),
                          ),
                          boxShadow: AppShadows.subtle,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.84,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'الصلاة التالية: $nextName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.82,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              nextTime,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
