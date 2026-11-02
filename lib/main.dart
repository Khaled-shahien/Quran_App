import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sakina_app/core/app/app_startup.dart';

void main() async {
  // Ensure Flutter binding is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Cairo', 'Amiri']) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('fonts/$family-OFL.txt'));
    }
  });

  // Initialize (Firebase, DI, background services), then show the app or a
  // recovery screen if a required phase failed.
  await startApp();
}
