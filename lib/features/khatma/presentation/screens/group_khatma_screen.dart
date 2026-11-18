import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/group_khatma.dart';

/// Group khatmas on this phone (one preference, JSON).
class GroupKhatmaStore {
  const GroupKhatmaStore(this._prefs);

  final SharedPreferences _prefs;
  static const String key = 'group_khatmas_v1';

  List<GroupKhatma> read() {
    try {
      final Object? decoded = jsonDecode(_prefs.getString(key) ?? '[]');
      if (decoded is! List) return [];
      return [for (final g in decoded) ?GroupKhatma.fromJson(g)];
    } on FormatException {
      return [];
    }
  }

  Future<void> write(List<GroupKhatma> groups) =>
      _prefs.setString(key, jsonEncode([for (final g in groups) g.toJson()]));
}

/// Sends text through the system share sheet; replaced in tests.
typedef TextSharer = Future<void> Function(String text);

Future<void> _shareText(String text) async {
  await SharePlus.instance.share(ShareParams(text: text));
}

/// Create a khatma for a family or circle, join one from a code, mark
/// your part, and collect the others' completion codes. Codes travel by
/// any messenger; there is no server and no account.
class GroupKhatmaScreen extends StatefulWidget {
  const GroupKhatmaScreen({super.key, this.share = _shareText});

  final TextSharer share;

  @override
  State<GroupKhatmaScreen> createState() => _GroupKhatmaScreenState();
}

class _GroupKhatmaScreenState extends State<GroupKhatmaScreen> {
  late final GroupKhatmaStore _store = GroupKhatmaStore(
    context.read<SharedPreferences>(),
  );
  late List<GroupKhatma> _groups = _store.read();

  Future<void> _save(List<GroupKhatma> groups) async {
    setState(() => _groups = groups);
    await _store.write(groups);
  }

  Future<void> _replace(GroupKhatma g) =>
      _save([for (final x in _groups) x.id == g.id ? g : x]);

  void _snack(String text) => ScaffoldMessenger.maybeOf(context)
    ?..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  String _partTitle(GroupPart p) {
    final l10n = l10nOf(context);
    final range = p.fromJuz == p.toJuz
        ? l10n.groupJuzOne('${p.fromJuz}')
        : l10n.groupJuzRange('${p.fromJuz}', '${p.toJuz}');
    return context.digits(p.label == null ? range : '${p.label} · $range');
  }

  Future<void> _create() async {
    final result = await showDialog<GroupKhatma>(
      context: context,
      builder: (_) => const _CreateDialog(),
    );
    if (result == null) return;
    await _save([..._groups, result]);
    await widget.share(_invite(result));
  }

  String _invite(GroupKhatma g) =>
      l10nOf(context).groupInviteMessage(g.name, g.inviteCode());

  Future<void> _join() async {
    final l10n = l10nOf(context);
    final text = await _askText(l10n.groupJoinTitle, l10n.groupJoinHint);
    if (text == null) return;
    final g = GroupKhatma.fromInvite(text);
    if (g == null) {
      _snack(l10n.groupInvalidCode);
      return;
    }
    if (_groups.any((x) => x.id == g.id)) {
      _snack(l10n.groupAlreadyHere);
      return;
    }
    await _save([..._groups, g]);
  }

  Future<String?> _askText(String title, String hint) => showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(title: title, hint: hint),
  );

  Future<void> _addDoneCodes(GroupKhatma g) async {
    final l10n = l10nOf(context);
    final text = await _askText(l10n.groupAddDoneTitle, l10n.groupAddDoneHint);
    if (text == null) return;
    final found = g.partsDoneIn(text);
    if (found.isEmpty) {
      _snack(l10n.groupInvalidCode);
      return;
    }
    await _replace(g.copyWith(done: {...g.done, ...found}));
    if (!mounted) return;
    _snack(context.digits(l10n.groupDoneAdded('${found.length}')));
  }

  Future<void> _finishMine(GroupKhatma g) async {
    final mine = g.mine;
    if (mine == null) return;
    await _replace(g.copyWith(done: {...g.done, mine}));
    if (!mounted) return;
    await widget.share(
      l10nOf(context).groupDoneMessage(g.name, g.doneCode(mine)),
    );
  }

  Future<void> _delete(GroupKhatma g) async {
    final l10n = l10nOf(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.groupDeleteTitle(g.name)),
        content: Text(l10n.groupDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.groupDelete),
          ),
        ],
      ),
    );
    if (ok == true) await _save([..._groups.where((x) => x.id != g.id)]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.groupIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                key: const Key('group-create'),
                icon: const Icon(Icons.group_add_outlined),
                label: Text(l10n.groupCreate),
                onPressed: _create,
              ),
              OutlinedButton.icon(
                key: const Key('group-join'),
                icon: const Icon(Icons.input_rounded),
                label: Text(l10n.groupJoin),
                onPressed: _join,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final g in _groups) ...[
            SakinaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(g.name, style: theme.textTheme.titleMedium),
                  Text(
                    context.digits(
                      g.complete
                          ? l10n.groupComplete
                          : l10n.groupProgress(
                              '${g.done.length}',
                              '${g.parts.length}',
                            ),
                    ),
                  ),
                  if (g.mine == null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        l10n.groupChooseMine,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  // Rows paint their tap feedback on this, not under the card.
                  for (final (i, p) in g.parts.indexed)
                    Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        key: Key('group-${g.id}-part-$i'),
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          g.done.contains(i)
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                        ),
                        title: Text(_partTitle(p)),
                        subtitle: g.done.contains(i)
                            ? Text(l10n.groupPartDone)
                            : null,
                        trailing: g.mine == i
                            ? Chip(label: Text(l10n.groupMine))
                            : null,
                        onTap: g.mine == null
                            ? () => _replace(g.copyWith(mine: i))
                            : null,
                      ),
                    ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (g.mine != null && !g.done.contains(g.mine))
                        FilledButton(
                          key: Key('group-${g.id}-finish'),
                          onPressed: () => _finishMine(g),
                          child: Text(l10n.groupFinishMine),
                        ),
                      OutlinedButton(
                        onPressed: () => widget.share(_invite(g)),
                        child: Text(l10n.groupShareInvite),
                      ),
                      OutlinedButton(
                        key: Key('group-${g.id}-add-done'),
                        onPressed: () => _addDoneCodes(g),
                        child: Text(l10n.groupAddDone),
                      ),
                      TextButton(
                        onPressed: () => _delete(g),
                        child: Text(l10n.groupDelete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog();

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _name = TextEditingController();
  final _names = TextEditingController();
  int _members = 3;

  @override
  void dispose() {
    _name.dispose();
    _names.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return AlertDialog(
      title: Text(l10n.groupCreate),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('group-name'),
              controller: _name,
              maxLength: GroupKhatma.maxName,
              decoration: InputDecoration(labelText: l10n.groupName),
            ),
            DropdownButtonFormField<int>(
              key: const Key('group-members'),
              initialValue: _members,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.groupMembers),
              items: [
                for (var n = 2; n <= GroupKhatma.maxParts; n++)
                  DropdownMenuItem(value: n, child: Text(context.digits('$n'))),
              ],
              onChanged: (n) => setState(() => _members = n ?? _members),
            ),
            TextField(
              controller: _names,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.groupMemberNames,
                helperText: l10n.groupMemberNamesHelp,
                helperMaxLines: 2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('group-create-ok'),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              GroupKhatma.create(
                name: name,
                members: _members,
                names: [
                  for (final n in _names.text.split('\n'))
                    if (n.trim().isNotEmpty) n,
                ],
              ),
            );
          },
          child: Text(l10n.groupCreateAndShare),
        ),
      ],
    );
  }
}

/// A dialog that owns its text field, so the field outlives the closing
/// animation.
class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('group-code'),
      controller: _controller,
      maxLines: 4,
      decoration: InputDecoration(hintText: widget.hint),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton(
        key: const Key('group-code-ok'),
        onPressed: () => Navigator.pop(context, _controller.text),
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}
