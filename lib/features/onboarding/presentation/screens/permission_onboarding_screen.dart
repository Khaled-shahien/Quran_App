import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/theme/app_radius.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/location_access_service.dart';
import '../../../../core/services/notification_permission_service.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';
import '../../../prayers/presentation/screens/prayer_location_dialog.dart';
import '../providers/permission_onboarding_controller.dart';
import '../widgets/onboarding_page.dart';

/// The two optional permission steps after the onboarding pages, in the
/// same layout as those pages. Neither blocks the app: "not now" always
/// continues, and a refusal is explained with the way to change it later.
class PermissionOnboardingScreen extends StatefulWidget {
  const PermissionOnboardingScreen({
    super.key,
    this.notifications,
    this.location,
  });

  /// Injected in tests; the app uses the platform services.
  final NotificationPermissionService? notifications;
  final LocationAccessService? location;

  @override
  State<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen>
    with WidgetsBindingObserver {
  PermissionOnboardingController? _controller;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final controller = PermissionOnboardingController(
      prefs: prefs,
      notifications:
          widget.notifications ?? NotificationPermissionService(prefs: prefs),
      location: widget.location ?? LocationAccessService(prefs: prefs),
      prayer: context.read<PrayerTimesProvider>(),
    )..addListener(_onChanged);
    setState(() => _controller = controller);
    await controller.load();
  }

  void _onChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    if (controller.finished && !_leaving) {
      _leaving = true;
      context.go('/home');
      return;
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from system settings, or from the system permission dialog.
    if (state == AppLifecycleState.resumed) _controller?.recheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _chooseCity() async {
    final controller = _controller;
    if (controller == null) return;
    await showPrayerLocationDialog(
      context,
      controller.prayer,
      // The notification step has just been answered; nothing else is
      // asked during first-run setup.
      promptForReminders: false,
    );
    if (mounted) controller.manualLocationChosen();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = l10nOf(context);
    final step = controller?.step;
    if (controller == null || !controller.loaded || step == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final content = step == PermissionIntroStep.notifications
        ? _notificationContent(l10n)
        : _locationContent(l10n);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: colors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            AppStrings.appName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (controller.steps.length > 1)
                          // Wraps rather than overflowing with large text.
                          Flexible(
                            child: Text(
                              l10n.permissionIntroStepLabel(
                                '${controller.index + 1}',
                                '${controller.steps.length}',
                              ),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: OnboardingPage(
                      key: ValueKey(step),
                      content: content,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 480,
                      // Large text scrolls here instead of overflowing.
                      maxHeight: constraints.maxHeight * 0.5,
                    ),
                    child: SingleChildScrollView(
                      primary: false,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.ms,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: step == PermissionIntroStep.notifications
                          ? _notificationActions(controller, l10n)
                          : _locationActions(controller, l10n),
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

  OnboardingPageContent _notificationContent(AppLocalizations l10n) =>
      OnboardingPageContent(
        title: l10n.permissionIntroNotificationsTitle,
        description: l10n.permissionIntroNotificationsBody,
        caption: l10n.onboardingPageMessage21,
        icon: Icons.notifications_active_rounded,
        features: const [],
        permissionNotes: [
          (
            icon: Icons.mosque_rounded,
            text: l10n.permissionIntroNotificationsBenefit1,
          ),
          (
            icon: Icons.volume_up_rounded,
            text: l10n.permissionIntroNotificationsBenefit2,
          ),
          (
            icon: Icons.menu_book_rounded,
            text: l10n.permissionIntroNotificationsBenefit3,
          ),
          (
            icon: Icons.tune_rounded,
            text: l10n.permissionIntroNotificationsBenefit4,
          ),
        ],
      );

  OnboardingPageContent _locationContent(AppLocalizations l10n) =>
      OnboardingPageContent(
        title: l10n.permissionIntroLocationTitle,
        description: l10n.permissionIntroLocationBody,
        caption: l10n.permissionIntroLocationBenefit2,
        icon: Icons.location_on_rounded,
        features: const [],
        permissionNotes: [
          (
            icon: Icons.location_city_rounded,
            text: l10n.permissionIntroLocationBenefit1,
          ),
          (
            icon: Icons.schedule_rounded,
            text: l10n.permissionIntroLocationBenefit2,
          ),
          (
            icon: Icons.explore_rounded,
            text: l10n.permissionIntroLocationBenefit3,
          ),
          (
            icon: Icons.travel_explore_rounded,
            text: l10n.permissionIntroLocationBenefit4,
          ),
        ],
      );

  Widget _notificationActions(
    PermissionOnboardingController controller,
    AppLocalizations l10n,
  ) {
    final status = controller.notificationStatus;
    final busy = controller.busy;
    if (status == NotificationPermissionStatus.permanentlyDenied) {
      return _Actions(
        message: l10n.permissionIntroNotificationsSettings,
        primary: _action(
          l10n.permissionIntroOpenSettings,
          busy ? null : controller.openNotificationSettings,
        ),
        tertiary: _action(l10n.permissionIntroNotNow, controller.next),
      );
    }
    if (controller.notificationAsked &&
        status != NotificationPermissionStatus.granted) {
      return _Actions(
        message: l10n.permissionIntroNotificationsDenied,
        primary: _action(l10n.permissionIntroContinue, controller.next),
      );
    }
    return _Actions(
      busy: busy,
      primary: _action(
        l10n.permissionIntroEnableNotifications,
        busy ? null : controller.enableNotifications,
      ),
      tertiary: _action(
        l10n.permissionIntroNotNow,
        busy ? null : controller.next,
      ),
    );
  }

  Widget _locationActions(
    PermissionOnboardingController controller,
    AppLocalizations l10n,
  ) {
    final busy = controller.busy;
    final prayer = controller.prayer;
    final chooseCity = _action(
      l10n.permissionIntroChooseCity,
      busy ? null : _chooseCity,
    );
    final notNow = _action(
      l10n.permissionIntroNotNow,
      busy ? null : controller.next,
    );
    switch (controller.locationPhase) {
      case LocationIntroPhase.locating:
        return _Actions(
          busy: true,
          message: l10n.permissionIntroLocating,
          primary: _action(l10n.permissionIntroEnableLocation, null),
        );
      case LocationIntroPhase.located:
        return _Actions(
          message: [
            l10n.permissionIntroLocationSet(prayer.locationLabel),
            if (prayer.lastFixWasStale) l10n.staleLocationNotice,
          ].join('\n'),
          positive: true,
          primary: _action(l10n.permissionIntroContinue, controller.next),
          secondary: chooseCity,
        );
      case LocationIntroPhase.idle:
      case LocationIntroPhase.failed:
        break;
    }
    final failed = controller.locationPhase == LocationIntroPhase.failed;
    switch (controller.locationStatus) {
      case LocationAccessStatus.permanentlyDenied:
        return _Actions(
          message: l10n.permissionIntroLocationSettings,
          primary: _action(
            l10n.permissionIntroOpenSettings,
            busy ? null : controller.openLocationSettings,
          ),
          secondary: chooseCity,
          tertiary: notNow,
        );
      case LocationAccessStatus.servicesDisabled:
        return _Actions(
          message: l10n.permissionIntroLocationServicesOff,
          primary: _action(
            l10n.permissionIntroOpenLocationSettings,
            busy ? null : controller.openLocationSettings,
          ),
          secondary: chooseCity,
          tertiary: notNow,
        );
      case LocationAccessStatus.denied when failed:
        return _Actions(
          message: l10n.permissionIntroLocationDenied,
          primary: chooseCity,
          secondary: _action(
            l10n.permissionIntroEnableLocation,
            busy ? null : controller.enableLocation,
          ),
          tertiary: notNow,
        );
      default:
        return _Actions(
          busy: busy,
          // Access was granted but no usable fix came back.
          message: failed ? prayer.lastLocationError?.message : null,
          primary: _action(
            l10n.permissionIntroEnableLocation,
            busy ? null : controller.enableLocation,
          ),
          secondary: chooseCity,
          tertiary: notNow,
        );
    }
  }

  static ({String label, VoidCallback? onPressed}) _action(
    String label,
    Future<void> Function()? onPressed,
  ) => (label: label, onPressed: onPressed == null ? null : () => onPressed());
}

/// The message and buttons under a step: one filled primary action, an
/// optional outlined alternative and an optional quiet "not now".
class _Actions extends StatelessWidget {
  const _Actions({
    required this.primary,
    this.secondary,
    this.tertiary,
    this.message,
    this.busy = false,
    this.positive = false,
  });

  final ({String label, VoidCallback? onPressed}) primary;
  final ({String label, VoidCallback? onPressed})? secondary;
  final ({String label, VoidCallback? onPressed})? tertiary;
  final String? message;
  final bool busy;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = message;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (text != null && text.isNotEmpty) ...[
          Semantics(
            liveRegion: true,
            child: Container(
              key: const Key('permission-step-message'),
              padding: const EdgeInsets.all(AppSpacing.ms),
              decoration: BoxDecoration(
                color: positive
                    ? colors.primary.withValues(alpha: 0.08)
                    : colors.secondary,
                borderRadius: AppRadius.card,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: busy
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : Icon(
                            positive
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 20,
                            color: colors.primary,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: positive ? colors.onSurface : colors.onSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton(
          onPressed: primary.onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.ms,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: busy && (text == null || text.isEmpty)
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                  ),
                )
              : Text(primary.label, textAlign: TextAlign.center),
        ),
        if (secondary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: secondary!.onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Text(secondary!.label, textAlign: TextAlign.center),
          ),
        ],
        if (tertiary != null) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: tertiary!.onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
            ),
            child: Text(tertiary!.label, textAlign: TextAlign.center),
          ),
        ],
      ],
    );
  }
}
