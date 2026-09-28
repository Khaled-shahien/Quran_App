import 'package:sakina_app/l10n/localization.dart';
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
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          label: l10nOf(context).appStringsMessage27,
        ),
        NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          label: l10nOf(context).appStringsMessage28,
        ),
        NavigationDestination(
          icon: const Icon(Icons.mosque_outlined),
          label: l10nOf(context).mainNavigationShellMessage1,
        ),
        NavigationDestination(
          icon: const Icon(Icons.wb_sunny_outlined),
          label: l10nOf(context).mainNavigationShellMessage2,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          label: l10nOf(context).appStringsMessage16,
        ),
      ],
    ),
  );
}
