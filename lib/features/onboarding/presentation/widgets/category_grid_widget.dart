import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryGridWidget extends StatelessWidget {
  const CategoryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        // Three columns normally; two taller ones when large text needs room.
        gridDelegate: textScale <= 1.15
            ? const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 70 + 45 * textScale,
              ),
        delegate: SliverChildListDelegate([
          _catCard(
            context,
            l10nOf(context).appStringsMessage30,
            'assets/images/الادعيه.png',
            onTap: () => context.push('/duas/all'),
          ),
          _catCard(
            context,
            l10nOf(context).categoryGridWidgetMessage1,
            'assets/images/التسبيح_الالكتروني.png',
            onTap: () => context.push('/tasbeeh'),
          ),
          _catCard(
            context,
            l10nOf(context).categoryGridWidgetMessage2,
            'assets/images/اسماء_الله_الحسني.png',
            onTap: () => context.push('/asma'),
          ),
          _catCard(
            context,
            l10nOf(context).appStringsMessage28,
            'assets/images/القران.png',
            onTap: () => context.push('/quran'),
          ),
          _catCard(
            context,
            l10nOf(context).mainNavigationShellMessage2,
            'assets/images/الاذكار.png',
            onTap: () => context.push('/duas'),
          ),
          _catCard(
            context,
            l10nOf(context).categoryGridWidgetMessage3,
            'assets/images/الاحاديث.png',
            onTap: () => context.push('/hadeath'),
          ),
          _iconCard(
            context,
            l10nOf(context).guideTileProphets,
            Icons.auto_stories_rounded,
            onTap: () => context.push('/guide?section=prophets'),
          ),
          _iconCard(
            context,
            l10nOf(context).guideTilePrayer,
            Icons.mosque_rounded,
            onTap: () => context.push('/guide?section=prayer'),
          ),
          _iconCard(
            context,
            l10nOf(context).guideTilePillars,
            Icons.account_balance_rounded,
            onTap: () => context.push('/guide?section=pillars'),
          ),
        ]),
      ),
    );
  }

  Widget _catCard(
    BuildContext context,
    String title,
    String imagePath, {
    VoidCallback? onTap,
  }) => Semantics(
    button: true,
    label: title,
    excludeSemantics: true,
    child: Material(
      color: Theme.of(context).colorScheme.secondary,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 40, height: 40, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _iconCard(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    label: title,
    excludeSemantics: true,
    child: Material(
      color: Theme.of(context).colorScheme.secondary,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}
