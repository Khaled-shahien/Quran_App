import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina_app/core/initialization/app_initializer.dart';
import 'package:sakina_app/core/app/app_root.dart';
import 'package:sakina_app/core/navigation/app_router.dart';
import 'package:sakina_app/features/quran/presentation/screens/quran_search_screen.dart';
import 'package:sakina_app/features/quran/presentation/screens/surah_details_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real app opens settings, searches offline, and opens the reader',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_notification_permission', true);
      await AppInitializer.initialize();
      await tester.pumpWidget(const AppRoot());
      appRouter.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('المظهر والقراءة'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('داكن').last);
      await tester.pumpAndSettle();
      expect(prefs.getString('theme_mode'), 'dark');
      appRouter.push('/quran/search');
      await tester.pumpAndSettle();
      expect(find.byType(QuranSearchScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'الفاتحة');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.byType(SurahDetailsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
