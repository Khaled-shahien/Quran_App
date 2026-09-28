import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({
    super.key,
    required this.child,
    required this.location,
  });
  final Widget child;
  final String location;
  static const paths = ['/home', '/quran', '/prayers', '/duas', '/settings'];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: paths.indexOf(location).clamp(0, paths.length - 1),
      onDestinationSelected: (index) {
        if (paths[index] != location) context.go(paths[index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'الرئيسية',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: 'القرآن',
        ),
        NavigationDestination(
          icon: Icon(Icons.mosque_outlined),
          label: 'الصلاة',
        ),
        NavigationDestination(
          icon: Icon(Icons.wb_sunny_outlined),
          label: 'الأذكار',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'الإعدادات',
        ),
      ],
    ),
  );
}
