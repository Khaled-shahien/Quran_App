import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => child;
}
