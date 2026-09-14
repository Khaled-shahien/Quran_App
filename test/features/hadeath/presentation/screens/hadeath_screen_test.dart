import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/features/hadeath/domain/entities/hadeath_entity.dart';
import 'package:sakina_app/features/hadeath/domain/repositories/hadeath_repository.dart';
import 'package:sakina_app/features/hadeath/presentation/providers/hadeath_provider.dart';
import 'package:sakina_app/features/hadeath/presentation/screens/hadeath_screen.dart';

import '../../../../helpers/router_test_helper.dart';

class FakeHadeathRepository implements HadeathRepository {
  FakeHadeathRepository({this.onGetAll});

  final Future<List<HadeathEntity>> Function()? onGetAll;

  @override
  Future<List<HadeathEntity>> getAllAhadeth() async {
    if (onGetAll != null) {
      return onGetAll!();
    }
    return <HadeathEntity>[];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildScreen(HadeathRepository repository) {
    final provider = HadeathProvider(repository: repository);

    return ChangeNotifierProvider<HadeathProvider>.value(
      value: provider,
      child: buildRouterTestApp(
        home: const HadeathScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: '/hadeath/details/:index',
            builder: (context, state) {
              final int index = int.parse(state.pathParameters['index']!);
              final hadeath = provider.ahadethList[index];
              return Scaffold(
                body: Column(
                  children: [
                    const Text('بِسْمِ اللَّهِ الرَّحْمَِٰ الرَّحِيمِ'),
                    Text(hadeath.content.join(' ')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  testWidgets('shows loader then renders ahadeth list', (tester) async {
    final completer = Completer<List<HadeathEntity>>();
    final repo = FakeHadeathRepository(onGetAll: () => completer.future);

    await tester.pumpWidget(buildScreen(repo));
    await tester.pump();

    expect(find.byType(PulseLoader), findsOneWidget);

    completer.complete(const <HadeathEntity>[
      HadeathEntity(title: 'حديث عن الصدق', content: <String>['نص الحديث']),
    ]);

    await tester.pumpAndSettle();

    expect(find.byType(PulseLoader), findsNothing);
    expect(find.text('حديث عن الصدق'), findsOneWidget);
  });

  testWidgets('shows error message when loading ahadeth fails', (tester) async {
    final repo = FakeHadeathRepository(
      onGetAll: () async {
        throw Exception('network');
      },
    );

    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('حدث خطأ أثناء تحميل الأحاديث'), findsOneWidget);
  });

  testWidgets('shows empty state when no ahadeth are available', (
    tester,
  ) async {
    final repo = FakeHadeathRepository(onGetAll: () async => <HadeathEntity>[]);

    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد أحاديث لعرضها'), findsOneWidget);
  });

  testWidgets('uses fallback title and navigates to details on tap', (
    tester,
  ) async {
    final repo = FakeHadeathRepository(
      onGetAll: () async {
        return const <HadeathEntity>[
          HadeathEntity(title: '', content: <String>['سطر أول', 'سطر ثان']),
        ];
      },
    );

    await tester.pumpWidget(buildScreen(repo));
    await tester.pumpAndSettle();

    expect(find.text('الحديث 1'), findsOneWidget);

    await tester.tap(find.text('الحديث 1'));
    await tester.pumpAndSettle();

    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَِٰ الرَّحِيمِ'), findsOneWidget);
    expect(find.text('سطر أول سطر ثان'), findsOneWidget);
  });
}
