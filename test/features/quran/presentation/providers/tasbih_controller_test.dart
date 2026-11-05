import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/data/repositories/tasbih_repository_impl.dart';
import 'package:sakina_app/features/quran/domain/entities/tasbih_phrase.dart';
import 'package:sakina_app/features/quran/presentation/providers/tasbih_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  Future<TasbihController> build([
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    return TasbihController(
      repository: SharedPreferencesTasbihRepository(prefs),
    );
  }

  TasbihController reopen() =>
      TasbihController(repository: SharedPreferencesTasbihRepository(prefs));

  test('first run starts with the four built-in phrases at zero', () async {
    final c = await build();

    expect(c.phrases.map((p) => p.id), builtInTasbihIds);
    expect(c.phrases.every((p) => p.count == 0 && p.isBuiltIn), isTrue);
    expect(c.selectedIndex, 0);
    expect(c.count, 0);
  });

  test('increment counts the selected phrase only', () async {
    final c = await build();
    c.select(2);
    c.increment();
    c.increment();

    expect(c.count, 2);
    expect(c.phrases[2].count, 2);
    expect(c.phrases[0].count, 0);
  });

  test(
    'increment reports completion exactly once, on the target tap',
    () async {
      final c = await build();
      final completions = <bool>[
        for (var i = 0; i < TasbihPhrase.defaultTarget + 1; i++) c.increment(),
      ];

      expect(completions.where((done) => done), hasLength(1));
      expect(completions[TasbihPhrase.defaultTarget - 1], isTrue);
      expect(c.phrases.first.isComplete, isTrue);
      expect(c.count, TasbihPhrase.defaultTarget + 1, reason: 'keeps counting');
    },
  );

  test(
    'counts, custom phrases and selection persist across restarts',
    () async {
      final c = await build();
      c.add('  أستغفر الله  ');
      c.select(4);
      c.increment();
      await c.saved;

      final restored = reopen();
      expect(restored.phrases, hasLength(5));
      expect(restored.selectedIndex, 4);
      expect(restored.selected!.customText, 'أستغفر الله');
      expect(restored.count, 1);
    },
  );

  test('blank custom phrases are ignored', () async {
    final c = await build();
    c.add('   ');
    expect(c.phrases, hasLength(4));
  });

  test('reset zeroes every count and undo restores them', () async {
    final c = await build();
    c.increment();
    c.select(1);
    c.increment();
    c.increment();

    final before = c.reset();
    expect(c.phrases.every((p) => p.count == 0), isTrue);

    c.undoReset(before);
    expect(c.phrases[0].count, 1);
    expect(c.phrases[1].count, 2);
    expect(c.selectedIndex, 1);
    await c.saved;
    expect(reopen().phrases[1].count, 2, reason: 'undo is persisted too');
  });

  group('remove and restore', () {
    test('removing the selected phrase selects the previous one', () async {
      final c = await build();
      c.select(2);
      c.removeAt(2);
      expect(c.selectedIndex, 1);
    });

    test(
      'removing before the selection keeps the same phrase selected',
      () async {
        final c = await build();
        c.select(3);
        final id = c.selected!.id;
        c.removeAt(0);
        expect(c.selected!.id, id);
      },
    );

    test('restore puts the phrase and its count back in place', () async {
      final c = await build();
      c.select(1);
      c.increment();
      final removed = c.removeAt(1)!;
      c.restore(removed);

      expect(c.phrases[1].id, builtInTasbihIds[1]);
      expect(c.phrases[1].count, 1);
      expect(c.selectedIndex, 1);
    });

    test('removing the last phrase leaves a safe empty state', () async {
      final c = await build();
      for (var i = 0; i < 4; i++) {
        c.removeAt(0);
      }
      expect(c.phrases, isEmpty);
      expect(c.selected, isNull);
      expect(c.increment(), isFalse);
      expect(c.count, 0);
    });
  });

  test(
    'corrupt stored data falls back to defaults instead of crashing',
    () async {
      final c = await build({
        SharedPreferencesTasbihRepository.storageKey: '{x',
      });
      expect(c.phrases.map((p) => p.id), builtInTasbihIds);
    },
  );

  test('one malformed phrase does not drop the others', () async {
    final c = await build({
      SharedPreferencesTasbihRepository.storageKey:
          '{"selected":0,"phrases":[{"id":"builtin_subhan_allah","count":5},'
          '{"count":"oops"},{"id":"custom_1","text":"x","count":2}]}',
    });
    expect(c.phrases.map((p) => p.id), ['builtin_subhan_allah', 'custom_1']);
    expect(c.phrases.first.count, 5);
  });
}
