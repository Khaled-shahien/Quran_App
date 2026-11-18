import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/presentation/widgets/verse_share.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

void main() {
  late Directory temp;
  final shared = <({String? text, String? imagePath})>[];

  setUp(() {
    temp = Directory.systemTemp.createTempSync('sakina_share');
    shared.clear();
  });

  tearDown(() => temp.deleteSync(recursive: true));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showShareVerseSheet(
              context,
              text: 'نص الآية',
              surahName: 'البقرة',
              ayah: 255,
              share: ({text, imagePath}) async =>
                  shared.add((text: text, imagePath: imagePath)),
              imageFolder: () async => temp,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('text keeps the verse as stored and adds its reference', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('البقرة · الآية 255'), findsOneWidget);
    await tester.tap(find.byKey(const Key('verse-share-text')));
    await tester.pumpAndSettle();
    expect(shared.single.text, 'نص الآية\n[البقرة · الآية 255]');
    expect(shared.single.imagePath, isNull);
  });

  testWidgets('the image is rendered on the phone as a PNG file', (
    tester,
  ) async {
    await open(tester);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('verse-share-image')));
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    final path = shared.single.imagePath!;
    final bytes = File(path).readAsBytesSync();
    expect(bytes.sublist(1, 4), 'PNG'.codeUnits);
    expect(shared.single.text, 'البقرة · الآية 255');
  });

  testWidgets('the app name on the image can be turned off', (tester) async {
    await open(tester);
    expect(
      find.descendant(
        of: find.byType(VerseShareCard),
        matching: find.text('سكينة'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('verse-share-app-name')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(VerseShareCard),
        matching: find.text('سكينة'),
      ),
      findsNothing,
    );
  });
}
