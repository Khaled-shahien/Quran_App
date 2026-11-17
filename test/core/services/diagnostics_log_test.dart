import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/core/services/diagnostics_log.dart';
import 'package:sakina_app/core/services/workmanager_service.dart';
import 'package:sakina_app/features/settings/presentation/widgets/diagnostics_tile.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device diagnostics, independent of crash-report consent (audit
/// OBS-01, task P1-04).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('records only the error type, never its message', () async {
    await DiagnosticsLog.record(
      StateError('lat 24.7, lon 46.7, https://example.com/?q=secret'),
      source: 'flutter',
      preferences: prefs,
    );
    final stored = prefs.getString(DiagnosticsLog.entriesKey)!;
    expect(stored, contains('StateError'));
    expect(stored, isNot(contains('24.7')));
    expect(stored, isNot(contains('example.com')));
  });

  test('keeps the newest 50 entries', () async {
    for (var i = 0; i < 60; i++) {
      await DiagnosticsLog.record(
        i.isEven ? StateError('') : const FormatException(''),
        source: 'flutter',
        preferences: prefs,
        now: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
      );
    }
    final entries = DiagnosticsLog.entries(prefs);
    expect(entries, hasLength(DiagnosticsLog.capacity));
    expect(
      entries.last.at,
      DateTime.utc(2026, 1, 1).add(const Duration(minutes: 59)),
    );
  });

  test('a background failure is kept as the last background error', () async {
    await DiagnosticsLog.record(
      StateError('x'),
      source: 'background',
      preferences: prefs,
      now: DateTime.utc(2026, 1, 2, 3),
    );
    expect(
      prefs.getString(DiagnosticsLog.backgroundErrorTypeKey),
      'StateError',
    );
    expect(
      prefs.getString(DiagnosticsLog.backgroundErrorAtKey),
      '2026-01-02T03:00:00.000Z',
    );
  });

  test(
    'malformed storage reads as empty and clear removes everything',
    () async {
      await prefs.setString(DiagnosticsLog.entriesKey, '{not a list');
      expect(DiagnosticsLog.entries(prefs), isEmpty);
      await DiagnosticsLog.record(
        StateError(''),
        source: 'background',
        preferences: prefs,
      );
      await DiagnosticsLog.clear(prefs);
      expect(DiagnosticsLog.entries(prefs), isEmpty);
      expect(prefs.containsKey(DiagnosticsLog.backgroundErrorTypeKey), isFalse);
    },
  );

  test('a failed background reschedule is recorded, then rethrown', () async {
    await expectLater(
      handleRescheduleAlarms(
        preferences: () async => prefs,
        updateReminders: (_) async {},
        replenishPrayers: (_, _) async => throw StateError('broken'),
      ),
      throwsStateError,
    );
    expect(
      prefs.getString(DiagnosticsLog.backgroundErrorTypeKey),
      'StateError',
    );
  });

  testWidgets('the dialog shows background status and recorded errors', (
    tester,
  ) async {
    await prefs.setInt(
      kLastBackgroundRescheduleAtMsKey,
      DateTime(2026, 1, 1, 8).millisecondsSinceEpoch,
    );
    await DiagnosticsLog.record(
      const FormatException(''),
      source: 'background',
      preferences: prefs,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DiagnosticsDialog(preferences: prefs)),
      ),
    );
    expect(find.textContaining('آخر تحديث ناجح'), findsOneWidget);
    expect(find.textContaining('آخر خطأ'), findsOneWidget);
    expect(find.textContaining('FormatException'), findsWidgets);

    await tester.tap(find.text('مسح السجل'));
    await tester.pump();
    expect(find.text('لا توجد أخطاء مسجلة.'), findsOneWidget);
  });
}
