import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import 'app_root.dart';
import 'startup_failure_app.dart';
import '../initialization/app_initializer.dart';

/// Runs initialization, then shows the app or a screen that can retry startup.
Future<void> startApp({
  Future<void> Function() initialize = AppInitializer.initialize,
  void Function(Widget app) run = runApp,
  Widget Function() buildApp = _buildAppRoot,
}) async {
  try {
    await initialize();
  } catch (error, stackTrace) {
    developer.log(
      'Startup failed; showing recovery screen',
      name: 'sakina_app.init',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    run(
      StartupFailureApp(
        onRetry: () =>
            startApp(initialize: initialize, run: run, buildApp: buildApp),
      ),
    );
    return;
  }
  run(buildApp());
}

Widget _buildAppRoot() => const AppRoot();
