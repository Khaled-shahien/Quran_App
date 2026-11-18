import 'dart:convert';
import 'dart:math';

/// A khatma shared by a family or circle without any server: the plan
/// travels as a short text code, each member reads their part, and the
/// completion of a part travels back as another code.
class GroupKhatma {
  const GroupKhatma({
    required this.id,
    required this.name,
    required this.parts,
    this.mine,
    this.done = const {},
  });

  /// Random id shared by everyone holding the same plan.
  final String id;
  final String name;

  /// Juz ranges in order; together they cover juz 1-30 exactly once.
  final List<GroupPart> parts;

  /// The part this phone's user reads, once chosen.
  final int? mine;

  /// Parts known to be finished.
  final Set<int> done;

  static const int maxParts = 30;
  static const int maxName = 60;
  static const String invitePrefix = 'SAKINA-KHATMA:';
  static const String donePrefix = 'SAKINA-KHATMA-DONE:';

  bool get complete => done.length == parts.length;

  /// Splits the 30 juz among [members] as evenly as possible (earlier
  /// members take any remainder), labelled with [names] where given.
  factory GroupKhatma.create({
    required String name,
    required int members,
    List<String> names = const [],
    Random? random,
  }) {
    if (members < 1 || members > maxParts) {
      throw ArgumentError('1-$maxParts members');
    }
    final r = random ?? Random.secure();
    final id = List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
    final base = 30 ~/ members, extra = 30 % members;
    final parts = <GroupPart>[];
    var next = 1;
    for (var i = 0; i < members; i++) {
      final size = base + (i < extra ? 1 : 0);
      parts.add(
        GroupPart(
          fromJuz: next,
          toJuz: next + size - 1,
          label: i < names.length ? _clean(names[i], 40) : null,
        ),
      );
      next += size;
    }
    return GroupKhatma(id: id, name: _clean(name, maxName), parts: parts);
  }

  static String _clean(String s, int max) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.length > max ? t.substring(0, max) : t;
  }

  GroupKhatma copyWith({int? mine, Set<int>? done}) => GroupKhatma(
    id: id,
    name: name,
    parts: parts,
    mine: mine ?? this.mine,
    done: done ?? this.done,
  );

  /// The code that invites others: the plan only, no progress.
  String inviteCode() =>
      invitePrefix +
      base64Url.encode(
        utf8.encode(
          jsonEncode({
            'v': 1,
            'id': id,
            'n': name,
            'p': [
              for (final p in parts) [p.fromJuz, p.toJuz, ?p.label],
            ],
          }),
        ),
      );

  /// The code saying part [index] is finished.
  String doneCode(int index) => '$donePrefix$id:${index + 1}';

  /// Reads an invite code from pasted text (other words around it are
  /// fine). Null when there is no valid code.
  static GroupKhatma? fromInvite(String text) {
    final m = RegExp(
      '${RegExp.escape(invitePrefix)}([A-Za-z0-9_=-]+)',
    ).firstMatch(text);
    if (m == null) return null;
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(m[1]!)));
      if (decoded is! Map || decoded['v'] != 1) return null;
      final id = decoded['id'], name = decoded['n'], raw = decoded['p'];
      if (id is! String || !RegExp(r'^[0-9a-f]{8}$').hasMatch(id)) {
        return null;
      }
      if (name is! String || raw is! List || raw.isEmpty) return null;
      if (raw.length > maxParts) return null;
      final parts = <GroupPart>[];
      var expected = 1;
      for (final p in raw) {
        if (p is! List || p.length < 2) return null;
        final from = p[0], to = p[1];
        if (from is! int || to is! int || from != expected || to < from) {
          return null;
        }
        final label = p.length > 2 && p[2] is String
            ? _clean(p[2] as String, 40)
            : null;
        parts.add(GroupPart(fromJuz: from, toJuz: to, label: label));
        expected = to + 1;
      }
      if (expected != 31) return null;
      return GroupKhatma(id: id, name: _clean(name, maxName), parts: parts);
    } catch (_) {
      return null;
    }
  }

  /// Reads completion codes for this khatma from pasted text; returns the
  /// part indexes found (codes of other khatmas are ignored).
  Set<int> partsDoneIn(String text) => {
    for (final m in RegExp(
      '${RegExp.escape(donePrefix)}([0-9a-f]{8}):([0-9]{1,2})',
    ).allMatches(text))
      if (m[1] == id &&
          int.parse(m[2]!) >= 1 &&
          int.parse(m[2]!) <= parts.length)
        int.parse(m[2]!) - 1,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'parts': [for (final p in parts) p.toJson()],
    'mine': mine,
    'done': done.toList()..sort(),
  };

  static GroupKhatma? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], name = json['name'], parts = json['parts'];
    if (id is! String || name is! String || parts is! List) return null;
    final list = [for (final p in parts) ?GroupPart.fromJson(p)];
    if (list.length != parts.length || list.isEmpty) return null;
    final mine = json['mine'];
    final done = json['done'];
    return GroupKhatma(
      id: id,
      name: name,
      parts: list,
      mine: mine is int && mine >= 0 && mine < list.length ? mine : null,
      done: {
        if (done is List)
          for (final d in done)
            if (d is int && d >= 0 && d < list.length) d,
      },
    );
  }
}

class GroupPart {
  const GroupPart({required this.fromJuz, required this.toJuz, this.label});

  final int fromJuz;
  final int toJuz;
  final String? label;

  Map<String, Object?> toJson() => {
    'from': fromJuz,
    'to': toJuz,
    'label': label,
  };

  static GroupPart? fromJson(Object? json) {
    if (json is! Map) return null;
    final from = json['from'], to = json['to'], label = json['label'];
    if (from is! int || to is! int || from < 1 || to > 30 || to < from) {
      return null;
    }
    return GroupPart(
      fromJuz: from,
      toJuz: to,
      label: label is String && label.isNotEmpty ? label : null,
    );
  }
}
