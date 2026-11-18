import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:share_plus/share_plus.dart';

/// Hands text or a PNG file to the system share sheet; replaced in tests.
typedef VerseSharer = Future<void> Function({String? text, String? imagePath});

Future<void> _systemShare({String? text, String? imagePath}) async {
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      files: imagePath == null
          ? null
          : [XFile(imagePath, mimeType: 'image/png')],
    ),
  );
}

/// Share a verse as text (with its reference) or as an image made on the
/// phone. The verse text is used exactly as stored.
Future<void> showShareVerseSheet(
  BuildContext context, {
  required String text,
  required String surahName,
  required int ayah,
  VerseSharer share = _systemShare,
  Future<Directory> Function() imageFolder = getTemporaryDirectory,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _ShareSheet(
    text: text,
    surahName: surahName,
    ayah: ayah,
    share: share,
    imageFolder: imageFolder,
  ),
);

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.text,
    required this.surahName,
    required this.ayah,
    required this.share,
    required this.imageFolder,
  });

  final String text;
  final String surahName;
  final int ayah;
  final VerseSharer share;
  final Future<Directory> Function() imageFolder;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _card = GlobalKey();
  bool _showAppName = true;
  bool _busy = false;

  String get _reference => context.digits(
    l10nOf(context).verseShareReference(widget.surahName, '${widget.ayah}'),
  );

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = l10nOf(context).verseShareFailed;
    try {
      await action();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText() =>
      _run(() => widget.share(text: '${widget.text}\n[$_reference]'));

  Future<void> _shareImage() => _run(() async {
    final boundary =
        _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('No image data');
    final dir = await widget.imageFolder();
    final file = File(
      '${dir.path}/sakina_verse_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    await widget.share(text: _reference, imagePath: file.path);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.verseShareTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            // The preview shrinks to fit; the image keeps its full size.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _card,
                child: VerseShareCard(
                  text: widget.text,
                  reference: _reference,
                  appName: _showAppName ? l10n.appConstantsMessage1 : null,
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('verse-share-app-name'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.verseShareShowAppName),
              value: _showAppName,
              onChanged: (v) => setState(() => _showAppName = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('verse-share-image'),
              icon: const Icon(Icons.image_outlined),
              label: Text(l10n.verseShareAsImage),
              onPressed: _busy ? null : _shareImage,
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('verse-share-text'),
              icon: const Icon(Icons.short_text_rounded),
              label: Text(l10n.verseShareAsText),
              onPressed: _busy ? null : _shareText,
            ),
          ],
        ),
      ),
    );
  }
}

/// The image: the verse in the mushaf font on the app's colours, its
/// reference, and optionally the app's name.
class VerseShareCard extends StatelessWidget {
  const VerseShareCard({
    super.key,
    required this.text,
    required this.reference,
    this.appName,
  });

  static const Color _ink = Color(0xFF0D3B3B);
  static const Color _cream = Color(0xFFF4E6C8);

  final String text;
  final String reference;
  final String? appName;

  @override
  Widget build(BuildContext context) {
    // Fixed size and type so the image looks the same whatever the
    // phone's text settings.
    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_ink, Color(0xFF14504F)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: quranFontFamily,
                  fontSize: 24,
                  height: 2,
                  color: _cream,
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, width: 64, color: _cream.withAlpha(110)),
              const SizedBox(height: 12),
              Text(
                reference,
                style: const TextStyle(fontSize: 15, color: _cream),
              ),
              if (appName != null) ...[
                const SizedBox(height: 16),
                Text(
                  appName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _cream.withAlpha(170),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
