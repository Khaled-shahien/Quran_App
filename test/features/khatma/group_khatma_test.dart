import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/features/khatma/domain/group_khatma.dart';
import 'package:sakina_app/features/khatma/presentation/screens/group_khatma_screen.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('30 juz are split evenly, earlier members taking the rest', () {
    final g = GroupKhatma.create(
      name: 'ختمة العائلة',
      members: 4,
      names: ['أحمد', 'مريم'],
      random: Random(1),
    );
    expect(
      [for (final p in g.parts) (p.fromJuz, p.toJuz)],
      [(1, 8), (9, 16), (17, 23), (24, 30)],
    );
    expect(g.parts[0].label, 'أحمد');
    expect(g.parts[2].label, isNull);
    expect(g.id, matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(
      () => GroupKhatma.create(name: 'x', members: 31),
      throwsArgumentError,
    );
  });

  test('the invite code carries the plan, not the progress', () {
    final g = GroupKhatma.create(
      name: 'حلقة المسجد',
      members: 30,
      random: Random(2),
    ).copyWith(mine: 3, done: {1, 2});
    final message = 'انضم إلينا\n${g.inviteCode()}\nشكرًا';
    final joined = GroupKhatma.fromInvite(message)!;
    expect(joined.id, g.id);
    expect(joined.name, 'حلقة المسجد');
    expect(joined.parts, hasLength(30));
    expect(joined.mine, isNull);
    expect(joined.done, isEmpty);
  });

  test('broken or doctored codes are refused', () {
    final good = GroupKhatma.create(name: 'x', members: 2, random: Random(3));
    final code = good.inviteCode();
    expect(GroupKhatma.fromInvite('no code here'), isNull);
    expect(
      GroupKhatma.fromInvite('${code.substring(0, code.length - 6)}!!'),
      isNull,
    );
    // A plan that skips juz 30.
    final bad = GroupKhatma(
      id: good.id,
      name: 'x',
      parts: const [GroupPart(fromJuz: 1, toJuz: 29)],
    );
    expect(GroupKhatma.fromInvite(bad.inviteCode()), isNull);
  });

  test('completion codes of this khatma only, within its parts', () {
    final g = GroupKhatma.create(name: 'x', members: 3, random: Random(4));
    final other = GroupKhatma.create(name: 'y', members: 3, random: Random(5));
    final text =
        '${g.doneCode(0)} ${g.doneCode(2)} ${other.doneCode(1)} '
        '${GroupKhatma.donePrefix}${g.id}:9';
    expect(g.partsDoneIn(text), {0, 2});
  });

  test('stored groups survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final g = GroupKhatma.create(
      name: 'x',
      members: 5,
      random: Random(6),
    ).copyWith(mine: 1, done: {1, 4});
    await GroupKhatmaStore(prefs).write([g]);
    final read = GroupKhatmaStore(prefs).read().single;
    expect(read.id, g.id);
    expect(read.mine, 1);
    expect(read.done, {1, 4});
  });

  testWidgets('create, share, choose a part and send its completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final shared = <String>[];
    await tester.pumpWidget(
      Provider<SharedPreferences>.value(
        value: prefs,
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GroupKhatmaScreen(share: (t) async => shared.add(t)),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('group-create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('group-name')), 'العائلة');
    await tester.tap(find.byKey(const Key('group-create-ok')));
    await tester.pumpAndSettle();
    final invite = GroupKhatma.fromInvite(shared.single)!;
    expect(invite.parts, hasLength(3));

    final id = invite.id;
    await tester.tap(find.byKey(Key('group-$id-part-1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(Key('group-$id-finish')));
    await tester.tap(find.byKey(Key('group-$id-finish')));
    await tester.pumpAndSettle();
    expect(invite.partsDoneIn(shared.last), {1});
    final stored = GroupKhatmaStore(prefs).read().single;
    expect(stored.mine, 1);
    expect(stored.done, {1});

    // Another member's completion arrives.
    await tester.ensureVisible(find.byKey(Key('group-$id-add-done')));
    await tester.tap(find.byKey(Key('group-$id-add-done')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('group-code')),
      invite.doneCode(0),
    );
    await tester.tap(find.byKey(const Key('group-code-ok')));
    await tester.pumpAndSettle();
    expect(GroupKhatmaStore(prefs).read().single.done, {0, 1});
  });
}
