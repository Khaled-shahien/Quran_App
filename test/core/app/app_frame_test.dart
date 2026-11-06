import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/app/app_frame.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_controller.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/recitation/fakes.dart';

/// The mini player lives in MaterialApp.builder, above the Navigator. Its
/// buttons have tooltips, which need an Overlay; this must work exactly as
/// the app builds it, while scrolling and long-pressing.
void main() {
  late RecitationController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    controller = RecitationController(
      repository: FakeRepository(),
      engine: FakeEngine(),
      preferences: await SharedPreferences.getInstance(),
      surahName: (s) => 'سورة $s',
    );
    await controller.initialize();
  });

  Widget app() => ChangeNotifierProvider.value(
    value: controller,
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          AppFrame(sheetContext: () => null, child: child!),
      home: Scaffold(
        body: ListView(
          children: [
            for (var i = 0; i < 60; i++) ListTile(title: Text('عنصر $i')),
          ],
        ),
      ),
    ),
  );

  testWidgets('mini player buttons work above the navigator', (tester) async {
    await controller.playSurah(1, fromAyah: 2);
    await tester.pumpWidget(app());
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Scroll down and back up while the player is showing.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Long-press shows the button's tooltip, which needs the overlay.
    await tester.longPress(find.byTooltip('إيقاف مؤقت'));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
