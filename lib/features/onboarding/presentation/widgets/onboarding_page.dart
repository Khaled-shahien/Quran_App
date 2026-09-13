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

const onboardingPages = [
  OnboardingPageContent(
    title: 'أهلًا بك في سكينة',
    description:
        'مساحة يطمئن فيها قلبك؛ تجمع لك القرآن والذكر '
        'ومواقيت الصلاة، لترافقك في يومك.',
    caption: 'رفيقك في كل يوم',
    icon: Icons.auto_stories_rounded,
    imagePath: 'assets/images/المصحف.png',
    showBasmalah: true,
    features: ['قرآن', 'ذكر', 'صلاة'],
  ),
  OnboardingPageContent(
    title: 'مع القرآن، آيةً بآية',
    description:
        'اقرأ القرآن واحفظ موضع قراءتك، وحدّد هدف ختمتك '
        'وتابع وردك اليومي بالوتيرة التي تناسبك.',
    caption: 'وردٌ تقرؤه، وقربٌ تجده',
    icon: Icons.menu_book_rounded,
    features: ['قراءة القرآن', 'حفظ الموضع', 'متابعة الختمة'],
  ),
  OnboardingPageContent(
    title: 'ليكن يومك عامرًا بالذكر',
    description:
        'أذكار الصباح والمساء، وأدعية ترافق يومك، '
        'ومسبحة إلكترونية تعينك على متابعة تسبيحك.',
    caption: 'لحظات ذكر، وأثرٌ يبقى',
    icon: Icons.wb_twilight_rounded,
    features: ['أذكار يومية', 'أدعية', 'تسبيح'],
  ),
  OnboardingPageContent(
    title: 'صلاتك ووردك في موعدهما',
    description:
        'تابع مواقيت الصلاة، واضبط تذكيرات الأذكار '
        'والورد اليومي لتجد وقتًا لما يطمئن به قلبك.',
    caption: 'تذكيرٌ يعينك على المداومة',
    icon: Icons.mosque_rounded,
    features: ['مواقيت الصلاة', 'تذكيرات الأذكار', 'الورد اليومي'],
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
