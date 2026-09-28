import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryGridWidget extends StatelessWidget {
  const CategoryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildListDelegate([
          _catCard(
            context,
            'الأدعية',
            'assets/images/الادعيه.png',
            onTap: () => context.push('/duas/all'),
          ),
          _catCard(
            context,
            'التسبيح',
            'assets/images/التسبيح_الالكتروني.png',
            onTap: () => context.push('/tasbeeh'),
          ),
          _catCard(
            context,
            'الأسماء',
            'assets/images/اسماء_الله_الحسني.png',
            onTap: () => context.push('/asma'),
          ),
          _catCard(
            context,
            'القرآن',
            'assets/images/القران.png',
            onTap: () => context.push('/quran'),
          ),
          _catCard(
            context,
            'الأذكار',
            'assets/images/الاذكار.png',
            onTap: () => context.push('/duas'),
          ),
          _catCard(
            context,
            'الأحاديث',
            'assets/images/الاحاديث.png',
            onTap: () => context.push('/hadeath'),
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
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 40, height: 40, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
