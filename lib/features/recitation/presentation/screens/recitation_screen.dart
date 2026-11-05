import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../providers/recitation_controller.dart';
import '../providers/recitation_downloads_controller.dart';
import '../recitation_labels.dart';

/// Pick a reciter, then play or download any surah. Everything plays inside
/// the app.
class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key});

  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
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
    final c = context.watch<RecitationController>();
    final reciter = c.reciter;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recitationTitle),
        actions: [
          IconButton(
            tooltip: l10n.recitationManageDownloads,
            icon: const Icon(Icons.download_done_rounded),
            onPressed: () => context.push('/recitation/downloads'),
          ),
        ],
      ),
      body: reciter == null
          ? Center(
              child: c.failure == null
                  ? const CircularProgressIndicator()
                  : Text(l10n.recitationFailure(c.failure)),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<int>(
                      key: const Key('recitation-screen-reciter'),
                      initialValue: reciter.id,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.recitationReciter,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final r in c.reciters)
                          DropdownMenuItem(
                            value: r.id,
                            child: Text(l10n.reciterLabel(r)),
                          ),
                      ],
                      onChanged: (id) {
                        final match = c.reciters.where((r) => r.id == id);
                        if (match.isNotEmpty) c.selectReciter(match.first);
                      },
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: 114,
                  itemBuilder: (context, i) =>
                      _SurahRow(surah: i + 1, reciterId: reciter.id),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.recitationSource,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.surah, required this.reciterId});

  final int surah;
  final int reciterId;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final c = context.watch<RecitationController>();
    final downloads = context.watch<RecitationDownloadsController>();
    final playingThis = c.surah == surah && c.isPlaying;
    final progress = downloads.progressOf(reciterId, surah);
    final downloaded = downloads.isDownloaded(reciterId, surah);

    Widget trailing;
    if (progress != null) {
      final fraction = progress.fraction;
      trailing = Semantics(
        label: l10n.recitationDownloading('${((fraction ?? 0) * 100).round()}'),
        child: SizedBox.square(
          dimension: 48,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CircularProgressIndicator(value: fraction, strokeWidth: 3),
          ),
        ),
      );
    } else if (downloaded) {
      trailing = Tooltip(
        message: l10n.recitationDownloaded,
        child: const SizedBox.square(
          dimension: 48,
          child: Icon(Icons.offline_pin_rounded),
        ),
      );
    } else {
      trailing = IconButton(
        tooltip: l10n.recitationDownload,
        icon: const Icon(Icons.download_rounded),
        onPressed: () => _confirmDownload(context),
      );
    }

    return ListTile(
      minTileHeight: 56,
      leading: CircleAvatar(child: Text('$surah')),
      title: Text(l10n.surahTitle(surah)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          trailing,
          IconButton(
            tooltip: playingThis ? l10n.recitationPause : l10n.recitationPlay,
            icon: Icon(
              playingThis
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded,
            ),
            iconSize: 32,
            onPressed: () => playingThis ? c.pause() : c.playSurah(surah),
          ),
        ],
      ),
      onTap: () => c.playSurah(surah),
    );
  }

  Future<void> _confirmDownload(BuildContext context) async {
    final l10n = l10nOf(context);
    final downloads = context.read<RecitationDownloadsController>();
    final messenger = ScaffoldMessenger.of(context);
    final size = await downloads.sizeOf(reciterId, surah);
    if (!context.mounted) return;
    final bytes = size.valueOrNull;
    if (bytes == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.recitationFailure(size.failureOrNull))),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.surahTitle(surah)),
        content: Text(l10n.recitationDownloadConfirm(l10n.megabytes(bytes))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.appStringsMessage9),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.recitationDownloadAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final saved = await downloads.start(reciterId, surah);
    if (!saved) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.recitationDownloadFailed)),
      );
    }
  }
}
