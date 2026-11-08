import 'package:sakina_app/core/widgets/empty_state.dart';
import 'package:sakina_app/core/theme/app_design.dart';
import 'package:sakina_app/core/widgets/geometric_pattern.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'dart:async';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/animated_entrance.dart';
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
                delay: Duration(milliseconds: 60),
                child: DateCardWidget(),
              ),
            ),
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
      // Grows with large text so the next-prayer details never clip.
      expandedHeight:
          220 +
          230 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2),
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: appL10n.appStringsMessage15,
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
              color: SakinaDecor.of(context).featureCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    button: true,
                    label: appL10n.homeScreenMessage2,
                    child: IconButton(
                      tooltip: l10nOf(context).appStringsMessage13,
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
                      style: const TextStyle(
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _drawerTabItem(appL10n.homeScreenMessage3, 0),
                    _drawerTabItem(appL10n.homeScreenMessage4, 1),
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
        label: appL10n.homeScreenMessage5((label).toString()),
        child: GestureDetector(
          onTap: () => setState(() => drawerSubTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? SakinaDecor.of(context).accent
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active
                    ? SakinaDecor.of(context).onAccent
                    : Theme.of(context).colorScheme.primary,
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
        style: TextStyle(
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
                  style: TextStyle(
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

  void _showFeatureMessage(String message) {
    _showOverlayMessage(message);
  }

  void _showOverlayMessage(String message, {Color? backgroundColor}) {
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
                  color: backgroundColor ?? SakinaDecor.of(context).featureCard,
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
                  style: const TextStyle(color: Colors.white),
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

  Widget _buildDynamicContent() {
    if (selectedTabIndex == 0) {
      return const CategoryGridWidget();
    } else {
      return const SliverToBoxAdapter(child: PrayerTimesWidget());
    }
  }
}
