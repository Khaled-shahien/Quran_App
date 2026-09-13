import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_strings.dart';
import '../widgets/notification_permission_dialog.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _completing = false;
  bool _changingPage = false;

  bool get _isLastPage => _currentPage == onboardingPages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _changePage(int page) async {
    if (_changingPage || _completing) return;
    _changingPage = true;
    try {
      if (MediaQuery.disableAnimationsOf(context)) {
        _pageController.jumpToPage(page);
      } else {
        await _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
        );
      }
    } finally {
      _changingPage = false;
    }
  }

  Future<void> _finishOnboarding() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (!(prefs.getBool('has_seen_notification_permission') ?? false)) {
        final finished = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: NotificationPermissionDialog(
              onFinish: () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
            ),
          ),
        );
        if (finished != true) return;
      }
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر بدء التطبيق، حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.appName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: !_isLastPage,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: TextButton(
                            onPressed: _completing ? null : _finishOnboarding,
                            child: const Text('تخطي'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      allowImplicitScrolling: true,
                      itemCount: onboardingPages.length,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      itemBuilder: (context, index) =>
                          OnboardingPage(content: onboardingPages[index]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label:
                                'الصفحة ${_currentPage + 1} من '
                                '${onboardingPages.length}',
                            liveRegion: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(onboardingPages.length, (
                                index,
                              ) {
                                final selected = index == _currentPage;
                                return AnimatedContainer(
                                  duration: animationDuration,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  height: 7,
                                  width: selected ? 28 : 7,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? colors.primary
                                        : colors.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              if (_currentPage > 0) ...[
                                IconButton.outlined(
                                  tooltip: 'السابق',
                                  onPressed: _completing
                                      ? null
                                      : () => _changePage(_currentPage - 1),
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(56, 56),
                                    side: BorderSide(
                                      color: colors.outlineVariant,
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: FilledButton(
                                  onPressed: _completing
                                      ? null
                                      : _isLastPage
                                      ? _finishOnboarding
                                      : () => _changePage(_currentPage + 1),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  child: Text(
                                    _isLastPage
                                        ? AppStrings.getStartedButton
                                        : 'التالي',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
