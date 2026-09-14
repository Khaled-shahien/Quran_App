import 'package:flutter/material.dart';
import 'package:sakina_app/core/app/app_root.dart';
import 'package:sakina_app/core/initialization/app_initializer.dart';

void main() async {
  // Ensure Flutter binding is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Orchestrate all initialization (Firebase, DI, background services)
  await AppInitializer.initialize();

  // Run the app
  runApp(const AppRoot());
}
