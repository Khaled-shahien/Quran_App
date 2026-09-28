import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الأذكار',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'الرجوع للشاشة السابقة',
          child: IconButton(
            tooltip: 'رجوع',
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DefaultTabController(
              length: 1, // Placeholder until full implementation
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Top Row (Morning / Evening)
                        _buildHeaderCard(
                          context,
                          title: 'أذكار الصباح',
                          icon: Icons.wb_sunny_outlined,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0288D1), Color(0xFF01579B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildHeaderCard(
                          context,
                          title: 'أذكار المساء',
                          icon: Icons.nightlight_round_outlined,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8E24AA), Color(0xFF4A148C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.2,
                        ),
                    delegate: SliverChildListDelegate([
                      _buildGridCard(
                        context,
                        title: 'أذكار النوم',
                        icon: Icons.nights_stay_outlined,
                        color: const Color(0xFFAD1457), // Pink/Purple
                      ),
                      _buildGridCard(
                        context,
                        title: 'بعد الصلاة',
                        icon: Icons.accessibility_new,
                        color: const Color(0xFF2E7D32), // Green
                      ),
                      _buildGridCard(
                        context,
                        title: 'الاستيقاظ',
                        icon: Icons.wb_twilight,
                        color: const Color(0xFF0097A7), // Teal/Blue
                      ),
                      _buildGridCard(
                        context,
                        title: 'أذكار المسجد',
                        icon: Icons.mosque_outlined,
                        color: const Color(0xFFD84315), // Deep Orange
                      ),
                      _buildGridCard(
                        context,
                        title: 'أدعية مأثورة',
                        icon: Icons.star_border_outlined,
                        color: const Color(0xFF827717), // Lime/Olive
                      ),
                      _buildGridCard(
                        context,
                        title: 'أدعية قرآنية',
                        icon: Icons.menu_book_outlined,
                        color: const Color(0xFFF57F17), // Yellow/Orange
                      ),
                      _buildGridCard(
                        context,
                        title: 'دعاء السفر',
                        icon: Icons.flight_takeoff_outlined,
                        color: const Color(0xFF9C27B0), // Purple
                      ),
                      _buildGridCard(
                        context,
                        title: 'الرقية الشرعية',
                        icon: Icons.back_hand_outlined,
                        color: const Color(0xFF00838F), // Cyan
                      ),
                    ]),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildHeaderCard(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Gradient gradient,
}) {
  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
  return Semantics(
    button: true,
    label: 'فتح قسم $title',
    child: InkWell(
      onTap: () {
        context.push('/azkar/details', extra: {'categoryName': title});
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.2,
              child: Icon(icon, size: 56, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: textScale > 1.2 ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildGridCard(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color color,
}) {
  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
  return Semantics(
    button: true,
    label: 'فتح قسم $title',
    child: InkWell(
      onTap: () {
        context.push('/azkar/details', extra: {'categoryName': title});
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Opacity(
                opacity: 0.2,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Icon(icon, size: 48, color: Colors.white),
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: textScale > 1.2 ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
