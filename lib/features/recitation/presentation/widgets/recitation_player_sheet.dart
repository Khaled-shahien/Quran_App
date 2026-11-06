import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../providers/recitation_controller.dart';
import '../recitation_labels.dart';

/// Opens the full recitation controls (reciter, speed, repeat).
Future<void> showRecitationPlayerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<RecitationController>(),
      child: const RecitationPlayerSheet(),
    ),
  );
}

class RecitationPlayerSheet extends StatefulWidget {
  const RecitationPlayerSheet({super.key});

  @override
  State<RecitationPlayerSheet> createState() => _RecitationPlayerSheetState();
}

class _RecitationPlayerSheetState extends State<RecitationPlayerSheet> {
  int? _from;
  int? _to;
  int _times = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<RecitationController>();
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final surah = c.surah;
    final ayahCount = c.ayahCount;
    final current = c.currentAyah ?? 1;
    final from = (_from ?? current).clamp(1, ayahCount < 1 ? 1 : ayahCount);
    final to = (_to ?? from).clamp(from, ayahCount < 1 ? 1 : ayahCount);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (surah != null) ...[
              Text(
                l10n.recitationNowPlaying(l10n.surahTitle(surah), '$current'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _Transport(controller: c),
              const Divider(height: 32),
            ],
            Text(l10n.recitationReciter, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: const Key('recitation-reciter'),
              initialValue: c.reciter?.id,
              isExpanded: true,
              items: [
                for (final r in c.reciters)
                  DropdownMenuItem(
                    value: r.id,
                    child: Text(l10n.reciterLabel(r)),
                  ),
              ],
              onChanged: (id) {
                final r = c.reciters.where((r) => r.id == id);
                if (r.isNotEmpty) c.selectReciter(r.first);
              },
            ),
            const SizedBox(height: 20),
            Text(l10n.recitationSpeed, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in RecitationController.speeds)
                  ChoiceChip(
                    label: Text(l10n.recitationSpeedValue(context.digits(s))),
                    selected: c.speed == s,
                    onSelected: (_) => c.setSpeed(s),
                  ),
              ],
            ),
            if (surah != null && ayahCount > 0) ...[
              const SizedBox(height: 20),
              Text(l10n.recitationRepeat, style: theme.textTheme.titleMedium),
              if (c.repeat case final r?) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.recitationRepeating(
                    context.digits(r.from),
                    context.digits(r.to),
                    context.digits(r.times),
                  ),
                ),
                TextButton(
                  onPressed: c.clearRepeat,
                  child: Text(l10n.recitationRepeatOff),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _AyahPicker(
                      label: l10n.recitationRepeatFrom,
                      value: from,
                      count: ayahCount,
                      onChanged: (v) => setState(() {
                        _from = v;
                        if ((_to ?? v) < v) _to = v;
                      }),
                    ),
                    _AyahPicker(
                      label: l10n.recitationRepeatTo,
                      value: to,
                      count: ayahCount,
                      min: from,
                      onChanged: (v) => setState(() => _to = v),
                    ),
                    DropdownButton<int>(
                      value: _times,
                      items: [
                        for (final n in const [2, 3, 5, 7, 10, 20])
                          DropdownMenuItem(
                            value: n,
                            child: Text(l10n.recitationRepeatTimes('$n')),
                          ),
                      ],
                      onChanged: (n) => setState(() => _times = n ?? _times),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => c.setRepeat(from, to, _times),
                  child: Text(l10n.recitationRepeatStart),
                ),
              ],
            ],
            const SizedBox(height: 16),
            Text(
              l10n.recitationSource,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahPicker extends StatelessWidget {
  const _AyahPicker({
    required this.label,
    required this.value,
    required this.count,
    required this.onChanged,
    this.min = 1,
  });

  final String label;
  final int value;
  final int count;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label),
      const SizedBox(width: 8),
      DropdownButton<int>(
        value: value,
        menuMaxHeight: 320,
        items: [
          for (var a = min; a <= count; a++)
            DropdownMenuItem(value: a, child: Text(context.digits(a))),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ],
  );
}

/// Previous ayah, play/pause, next ayah with 48dp+ targets.
class _Transport extends StatelessWidget {
  const _Transport({required this.controller});

  final RecitationController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final c = controller;
    final busy =
        c.status == RecitationStatus.loading ||
        c.status == RecitationStatus.buffering;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          tooltip: l10n.recitationPreviousAyah,
          onPressed: c.previousAyah,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        const SizedBox(width: 12),
        SizedBox.square(
          dimension: 64,
          child: busy
              ? Semantics(
                  label: l10n.recitationLoading,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              : IconButton.filled(
                  iconSize: 36,
                  tooltip: c.isPlaying
                      ? l10n.recitationPause
                      : l10n.recitationPlay,
                  onPressed: c.togglePlay,
                  icon: Icon(
                    c.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        IconButton(
          iconSize: 32,
          tooltip: l10n.recitationNextAyah,
          onPressed: c.nextAyah,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}
