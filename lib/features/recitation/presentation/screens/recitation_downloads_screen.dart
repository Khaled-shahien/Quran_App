import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../providers/recitation_controller.dart';
import '../providers/recitation_downloads_controller.dart';
import '../recitation_labels.dart';

/// Lists downloaded surahs with their size; delete offers undo.
class RecitationDownloadsScreen extends StatefulWidget {
  const RecitationDownloadsScreen({super.key});

  @override
  State<RecitationDownloadsScreen> createState() =>
      _RecitationDownloadsScreenState();
}

class _RecitationDownloadsScreenState extends State<RecitationDownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecitationDownloadsController>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final downloads = context.watch<RecitationDownloadsController>();
    final reciters = {
      for (final r in context.watch<RecitationController>().reciters) r.id: r,
    };
    final items = downloads.downloads;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recitationDownloadsTitle)),
      body: !downloads.loaded
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.recitationDownloadsEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final d = items[i];
                final reciter = reciters[d.reciterId];
                return ListTile(
                  minTileHeight: 56,
                  title: Text(l10n.surahTitle(d.surah)),
                  subtitle: Text(
                    [
                      if (reciter != null) l10n.reciterLabel(reciter),
                      context.digits(l10n.megabytes(d.bytes)),
                    ].join(' • '),
                  ),
                  trailing: IconButton(
                    tooltip: l10n.recitationDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () {
                      downloads.deleteWithUndo(d.reciterId, d.surah);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.recitationDeleted(l10n.surahTitle(d.surah)),
                            ),
                            action: SnackBarAction(
                              label: l10n.currentWirdWidgetMessage13,
                              onPressed: () =>
                                  downloads.undoDelete(d.reciterId, d.surah),
                            ),
                          ),
                        );
                    },
                  ),
                );
              },
            ),
    );
  }
}
