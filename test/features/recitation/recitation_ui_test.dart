import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_controller.dart';
import 'package:sakina_app/features/recitation/presentation/providers/recitation_downloads_controller.dart';
import 'package:sakina_app/features/recitation/presentation/screens/recitation_screen.dart';
import 'package:sakina_app/features/recitation/presentation/widgets/recitation_mini_player.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late FakeEngine engine;
  late FakeRepository repository;
  late RecitationController controller;
  late RecitationDownloadsController downloads;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    engine = FakeEngine();
    repository = FakeRepository();
    controller = RecitationController(
      repository: repository,
      engine: engine,
      preferences: await SharedPreferences.getInstance(),
      surahName: (s) => 'سورة $s',
    );
    await controller.initialize();
    downloads = RecitationDownloadsController(repository: repository);
  });

  tearDown(() {
    controller.dispose();
    downloads.dispose();
  });

  Widget app(Widget home) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: controller),
      ChangeNotifierProvider.value(value: downloads),
    ],
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  Widget miniPlayerHost() => app(
    Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: RecitationMiniPlayer(sheetContext: () => null),
    ),
  );

  testWidgets('mini player is hidden until something plays', (tester) async {
    await tester.pumpWidget(miniPlayerHost());
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('mini player shows the surah and ayah and can pause', (
    tester,
  ) async {
    await controller.playSurah(1, fromAyah: 2);
    await tester.pumpWidget(miniPlayerHost());

    expect(find.text('سورة الفاتحة • الآية 2'), findsOneWidget);
    expect(find.byTooltip('إيقاف مؤقت'), findsOneWidget);
    await tester.tap(find.byTooltip('إيقاف مؤقت'));
    await tester.pump();
    expect(engine.playing, isFalse);
    expect(find.byTooltip('تشغيل التلاوة'), findsOneWidget);
  });

  testWidgets('mini player explains offline errors and offers retry', (
    tester,
  ) async {
    repository.offline = true;
    await controller.playSurah(1);
    controller.selectReciter(controller.reciters.first);
    await tester.pumpWidget(miniPlayerHost());
    // No chapter loaded offline, so the bar stays hidden; a loaded surah
    // that then loses the network shows the message instead.
    expect(find.text('سورة الفاتحة • الآية 1'), findsNothing);

    repository.offline = false;
    await controller.playSurah(1);
    engine.errors.add(Exception('SocketException: network unreachable'));
    await tester.pump();
    expect(find.textContaining('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.byTooltip('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('every control in the mini player is at least 48dp', (
    tester,
  ) async {
    await controller.playSurah(1);
    await tester.pumpWidget(miniPlayerHost());
    for (final button in tester.widgetList(find.byType(IconButton))) {
      final size = tester.getSize(find.byWidget(button));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('recitation screen lists 114 surahs and plays in the app', (
    tester,
  ) async {
    await tester.pumpWidget(app(const RecitationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('سورة الفاتحة'), findsOneWidget);
    await tester.tap(find.text('سورة الفاتحة'));
    await tester.pump();
    expect(engine.loadedSource, 'https://example.org/1.mp3');
    expect(engine.playing, isTrue);
  });

  testWidgets('downloading asks first and shows the file size', (tester) async {
    await tester.pumpWidget(app(const RecitationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('تحميل للاستماع بدون إنترنت').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('حجم الملف'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
