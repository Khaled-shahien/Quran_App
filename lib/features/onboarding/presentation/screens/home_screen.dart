import 'package:sakina_app/features/practice_log/presentation/weekly_reflection_card.dart';
import 'package:sakina_app/features/settings/presentation/providers/simple_mode_controller.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/simple_home.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/ramadan_card.dart';
import 'package:sakina_app/features/onboarding/presentation/widgets/now_card.dart';
import 'package:sakina_app/core/widgets/empty_state.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/widgets/geometric_pattern.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'dart:async';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/sakina_segmented.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/feedback/feedback_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/sakina_card.dart';
import '../../../khatma/domain/models/khatma_model.dart';
import '../../../khatma/domain/services/khatma_quran_locator.dart';
import '../../../khatma/presentation/providers/khatma_provider.dart';
import '../../../quran/domain/entities/surah_entity.dart';
import '../../../quran/domain/repositories/surah_repository.dart';
import '../../../quran/presentation/providers/bookmark_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/current_wird_widget.dart';
import '../widgets/date_card_widget.dart';
import '../widgets/daily_verse_section_widget.dart';
import '../widgets/tab_switcher_widget.dart';
import '../widgets/category_grid_widget.dart';
import '../widgets/prayer_times_widget.dart';
import '../../../prayers/presentation/providers/'
    'prayer_times_provider.dart';

part 'home/home_wird_sheet.dart';
part 'home/home_drawer_lists.dart';
part 'home/home_prayer_time_header.dart';

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
    final bool simple =
        context.watch<SimpleModeController?>()?.enabled ?? false;
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildNavigationDrawer(),
      body: Directionality(
        textDirection: Directionality.of(context),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            const SliverToBoxAdapter(
              child: AnimatedEntrance(
                delay: Duration(milliseconds: 60),
                child: DateCardWidget(),
              ),
            ),
            if (simple)
              const SliverToBoxAdapter(child: SimpleHomeTiles())
            else ...[
              const SliverToBoxAdapter(child: RamadanCard()),
              const SliverToBoxAdapter(child: WeeklyReflectionCard()),
              const SliverToBoxAdapter(child: NowCard()),
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
            ],

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    final theme = Theme.of(context);
    final decor = SakinaDecor.of(context);

    return SliverAppBar(
      // Grows with large text so the next-prayer details never clip.
      expandedHeight:
          220 +
          250 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2),
      pinned: true,
      stretch: true,
      backgroundColor: decor.heroColors.last,
      foregroundColor: decor.onFeature,
      // Light status icons: this header is dark in every design.
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: decor.onFeature),
      actionsIconTheme: IconThemeData(color: decor.onFeature),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: appL10n.appStringsMessage15,
        icon: const Icon(Icons.search_rounded, size: 26),
        onPressed: () => context.push('/search'),
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
            color: decor.onFeature,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: const _PrayerTimeHeader(),
      ),
      actions: [
        IconButton(
          tooltip: appL10n.homeScreenMessage1,
          icon: const Icon(Icons.segment, size: 30),
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
        ),
      ],
    );
  }

  // --- 2. القائمة الجانبية المطورة ---
  Widget _buildNavigationDrawer() {
    return Drawer(
      width: (MediaQuery.sizeOf(context).width * 0.85).clamp(0.0, 380.0),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Column(
          children: [
            _DrawerHeader(onClose: () => Navigator.pop(context)),
            SakinaSegmented(
              margin: const EdgeInsets.all(AppSpacing.md),
              labels: [appL10n.homeScreenMessage3, appL10n.homeScreenMessage4],
              semanticLabelFor: (label) => appL10n.homeScreenMessage5(label),
              selectedIndex: drawerSubTab,
              onChanged: (index) => setState(() => drawerSubTab = index),
            ),

            // محتوى القائمة المتغير.
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.base),
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.leave,
                child: KeyedSubtree(
                  key: ValueKey<int>(drawerSubTab),
                  child: drawerSubTab == 0
                      ? _buildSettingsList()
                      : _buildFavoritesList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- مكونات واجهة المستخدم المساعدة ---

  // --- Helper Widgets for the More (المزيد) Menu ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        scale: false,
        borderRadius: AppRadius.controls,
        semanticLabel: title,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.ms,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: leadingIcon == null
                      ? null
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: AppRadius.chip,
                          ),
                          child: IconTheme.merge(
                            data: const IconThemeData(size: 20),
                            child: Center(child: leadingIcon),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.ms),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (trailingWidget != null) ...[
                  const SizedBox(width: AppSpacing.ms),
                  trailingWidget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeatureMessage(String message) {
    _showOverlayMessage(message);
  }

  void _showOverlayMessage(String message, {Color? backgroundColor}) {
    _messageEntry?.remove();
    _messageEntry?.dispose();

    // Shown above the drawer, which a snackbar would sit behind.
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final decor = SakinaDecor.of(context);
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: bottomPadding + AppSpacing.md,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: AppMotion.of(context, AppMotion.base),
              curve: AppMotion.enter,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - t)),
                  child: child,
                ),
              ),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.ms,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? decor.featureCard,
                      borderRadius: AppRadius.controls,
                      boxShadow: AppShadows.floating,
                    ),
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: decor.onFeature,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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

  Widget _buildDynamicContent() {
    if (selectedTabIndex == 0) {
      return const CategoryGridWidget();
    } else {
      return const SliverToBoxAdapter(child: PrayerTimesWidget());
    }
  }
}

/// The side menu's header: the app name on the design's feature gradient.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final decor = SakinaDecor.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: decor.heroColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GeometricPattern(
              pattern: decor.pattern,
              color: decor.onFeature.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: decor.onFeature.withValues(alpha: 0.14),
                      borderRadius: AppRadius.controls,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: decor.onFeature,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.ms),
                  Expanded(
                    child: Text(
                      AppStrings.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: decor.onFeature,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: appL10n.homeScreenMessage2,
                    child: IconButton(
                      tooltip: l10nOf(context).appStringsMessage13,
                      icon: Icon(Icons.close_rounded, color: decor.onFeature),
                      onPressed: onClose,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
