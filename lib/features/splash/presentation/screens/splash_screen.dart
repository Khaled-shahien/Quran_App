import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/navigation/notification_router.dart';
import '../../../onboarding/domain/first_run_state.dart';

/// Animated splash screen that displays the Sakina logo
/// before navigating to onboarding or home screen.
class SplashScreen extends StatefulWidget {
  /// Long enough for the logo not to flash, no fixed wait beyond that.
  static const Duration minimumDisplay = Duration(milliseconds: 500);

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    final ready = await Future.wait<Object?>([
      SharedPreferences.getInstance(),
      Future<void>.delayed(SplashScreen.minimumDisplay),
    ]);
    if (!mounted) return;
    final prefs = ready.first! as SharedPreferences;

    final destination = firstRunDestination(prefs);
    context.go(destination);
    // A tap that launched the app opens over home, never over first-run setup.
    NotificationRouter.release(dropPending: destination != '/home');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: show the logo in place, without the scale bounce.
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Matched to the artwork in assets/images/logo.png, not to a theme: the
    // splash looks the same in every design.
    const backgroundColor = Color(0xFF5E3B29);
    const logoGold = Color(0xFFE7C37A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          SafeArea(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      const Spacer(flex: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10nOf(context).splashScreenMessage1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: logoGold,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          color: logoGold,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
