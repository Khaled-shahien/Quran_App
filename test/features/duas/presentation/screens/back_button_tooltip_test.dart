import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart';
import 'package:sakina_app/features/duas/data/repositories/duas_repository.dart';
import 'package:sakina_app/features/duas/presentation/providers/azkar_provider.dart';
import 'package:sakina_app/features/duas/presentation/providers/duas_provider.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_details_screen.dart';
import 'package:sakina_app/features/duas/presentation/screens/azkar_screen.dart';
import 'package:sakina_app/features/duas/presentation/screens/duas_screen.dart';

void main() {
  const screens = <String, Widget>{
    'duas': DuasScreen(),
    'azkar': AzkarScreen(),
    'azkar details': AzkarDetailsScreen(categoryName: 'أذكار الصباح'),
  };
  for (final entry in screens.entries) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '${entry.key} back hover, semantics and navigation $brightness RTL',
        (tester) async {
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => DuasProvider(repository: DuasRepositoryImpl()),
                ),
                ChangeNotifierProvider(
                  create: (_) =>
                      AzkarProvider(repository: AzkarRepositoryImpl()),
                ),
              ],
              child: MaterialApp(
                theme: ThemeData(brightness: brightness),
                builder: (_, child) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => entry.value),
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          final back = find.byTooltip('الرجوع');
          expect(back, findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('الرجوع للشاشة السابقة')),
            findsOneWidget,
          );
          expect(find.text('الرجوع'), findsNothing);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(tester.getCenter(back));
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(find.text('الرجوع'), findsOneWidget);
          await mouse.removePointer();
          await tester.tap(back);
          await tester.pumpAndSettle();
          expect(find.text('open'), findsOneWidget);
          expect(find.byType(entry.value.runtimeType), findsNothing);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }
}
