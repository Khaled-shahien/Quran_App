import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

class OnboardingPageContent {
  const OnboardingPageContent({
    required this.title,
    required this.description,
    required this.caption,
    required this.icon,
    required this.features,
    this.imagePath,
    this.showBasmalah = false,
  });

  final String title;
  final String description;
  final String caption;
  final IconData icon;
  final List<String> features;
  final String? imagePath;
  final bool showBasmalah;
}

final onboardingPages = [
  OnboardingPageContent(
    title: appL10n.onboardingPageMessage1,
    description: appL10n.onboardingPageMessage2,
    caption: appL10n.onboardingPageMessage3,
    icon: Icons.auto_stories_rounded,
    imagePath: 'assets/images/المصحف.png',
    showBasmalah: true,
    features: [
      appL10n.onboardingPageMessage4,
      appL10n.onboardingPageMessage5,
      appL10n.onboardingPageMessage6,
    ],
  ),
  OnboardingPageContent(
    title: appL10n.onboardingPageMessage7,
    description: appL10n.onboardingPageMessage8,
    caption: appL10n.onboardingPageMessage9,
    icon: Icons.menu_book_rounded,
    features: [
      appL10n.onboardingPageMessage10,
      appL10n.onboardingPageMessage11,
      appL10n.onboardingPageMessage12,
    ],
  ),
  OnboardingPageContent(
    title: appL10n.onboardingPageMessage13,
    description: appL10n.onboardingPageMessage14,
    caption: appL10n.onboardingPageMessage15,
    icon: Icons.wb_twilight_rounded,
    features: [
      appL10n.onboardingPageMessage16,
      appL10n.onboardingPageMessage17,
      appL10n.onboardingPageMessage18,
    ],
  ),
  OnboardingPageContent(
    title: appL10n.onboardingPageMessage19,
    description: appL10n.onboardingPageMessage20,
    caption: appL10n.onboardingPageMessage21,
    icon: Icons.mosque_rounded,
    features: [
      appL10n.notificationServiceMessage5,
      appL10n.onboardingPageMessage22,
      appL10n.onboardingPageMessage23,
    ],
  ),
];

/// Scrollable content keeps navigation reachable on short screens and with
/// accessibility text scaling enabled.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.content});

  final OnboardingPageContent content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final illustration = _Illustration(
          content: content,
          height: (constraints.maxHeight * (wide ? 0.85 : 0.56)).clamp(
            180.0,
            360.0,
          ),
        );
        final copy = _PageCopy(content: content);

        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 32).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: wide
                ? Row(
                    children: [
                      Expanded(child: illustration),
                      const SizedBox(width: 40),
                      Expanded(child: copy),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [illustration, const SizedBox(height: 28), copy],
                  ),
          ),
        );
      },
    );
  }
}

class _PageCopy extends StatelessWidget {
  const _PageCopy({required this.content});

  final OnboardingPageContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            content.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: content.features
              .map(
                (feature) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    feature,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.content, required this.height});

  final OnboardingPageContent content;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          height: height,
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.secondary.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(180),
              bottom: Radius.circular(28),
            ),
            border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              if (content.showBasmalah)
                Image.asset(
                  'assets/images/بسم الله الرحمن الرحيم.png',
                  height: 32,
                  width: 220,
                  fit: BoxFit.contain,
                  color: colors.primary,
                  semanticLabel: AppStrings.basmalah,
                ),
              Expanded(
                child: ExcludeSemantics(
                  child: content.imagePath != null
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            content.imagePath!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              content.icon,
                              size: 96,
                              color: colors.primary,
                            ),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Icon(
                            content.icon,
                            size: 150,
                            color: colors.primary,
                          ),
                        ),
                ),
              ),
              // Scale only the decorative caption; explanatory text below
              // follows the user's text scaling preference.
              ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    content.caption,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
