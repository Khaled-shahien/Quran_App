import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../quran/presentation/providers/bookmark_provider.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key});
  @override
  Widget build(BuildContext context) {
    final bookmark = context.watch<BookmarkProvider>();
    if (!bookmark.hasBookmark) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ListTile(
        leading: const Icon(Icons.bookmark),
        title: Text(l10nOf(context).continueReadingCardMessage1),
        subtitle: Text(
          bookmark.surahName ?? l10nOf(context).continueReadingCardMessage2,
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context.push('/quran/surah/${bookmark.surahNumber}'),
      ),
    );
  }
}
