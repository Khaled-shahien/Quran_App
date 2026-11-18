import 'package:flutter/material.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/data_sources/tafsir_asset.dart';

/// Shows al-Tafsir al-Muyassar for one verse, offline, with its source.
/// [loader] is injected in tests.
Future<void> showTafsirSheet(
  BuildContext context, {
  required int surah,
  required int ayah,
  required String surahName,
  required String verseText,
  Future<String?> Function(int surah, int ayah) loader = TafsirAsset.of,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    minChildSize: 0.3,
    maxChildSize: 0.95,
    builder: (context, controller) => _TafsirBody(
      controller: controller,
      surah: surah,
      ayah: ayah,
      surahName: surahName,
      verseText: verseText,
      loader: loader,
    ),
  ),
);

class _TafsirBody extends StatefulWidget {
  const _TafsirBody({
    required this.controller,
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.verseText,
    required this.loader,
  });

  final ScrollController controller;
  final int surah;
  final int ayah;
  final String surahName;
  final String verseText;
  final Future<String?> Function(int surah, int ayah) loader;

  @override
  State<_TafsirBody> createState() => _TafsirBodyState();
}

class _TafsirBodyState extends State<_TafsirBody> {
  late Future<String?> _tafsir = widget.loader(widget.surah, widget.ayah);

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Text(
          l10n.tafsirTitle(widget.surahName, context.digits(widget.ayah)),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.verseText,
          textAlign: TextAlign.justify,
          style: AppTypography.script.copyWith(fontSize: 22, height: 1.9),
        ),
        const Divider(height: AppSpacing.xl),
        FutureBuilder<String?>(
          future: _tafsir,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const PulseLoader(lines: 4);
            }
            final String? text = snapshot.data;
            if (snapshot.hasError || text == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tafsirUnavailable),
                  TextButton(
                    onPressed: () => setState(() {
                      _tafsir = widget.loader(widget.surah, widget.ayah);
                    }),
                    child: Text(l10n.retry),
                  ),
                ],
              );
            }
            return SelectableText(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.tafsirSource, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
