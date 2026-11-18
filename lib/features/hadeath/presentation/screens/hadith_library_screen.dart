import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/hadith_library.dart';
import 'hadeath_details_screen.dart';

/// The hadith encyclopedia: topics to browse, and a search over every
/// hadith's title and text. Each hadith opens with its grade, explanation
/// and references as published.
class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({super.key, this.load = HadithLibrary.load});

  final Future<HadithLibrary> Function() load;

  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> {
  HadithLibrary? _library;
  bool _failed = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final library = await widget.load();
      if (mounted) setState(() => _library = library);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final library = _library;
    final Widget body;
    if (_failed) {
      body = Center(child: Text(l10n.hadithLibraryFailed));
    } else if (library == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.hadithLibraryLoading),
          ],
        ),
      );
    } else if (_query.trim().isNotEmpty) {
      final hits = library.search(_query);
      body = hits.isEmpty
          ? Center(child: Text(l10n.searchEmpty))
          : HadithItemList(items: hits);
    } else {
      body = HadithTopicList(library: library, parent: null);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithLibraryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              key: const Key('hadith-library-search'),
              enabled: library != null,
              decoration: InputDecoration(
                labelText: l10n.hadithLibrarySearch,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (library != null && _query.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                context.digits(
                  l10n.hadithLibraryIntro('${library.items.length}'),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Topics under [parent] (the top level when null), with their counts.
class HadithTopicList extends StatelessWidget {
  const HadithTopicList({super.key, required this.library, this.parent});

  final HadithLibrary library;
  final int? parent;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final topics = library.childrenOf(parent);
    final int? here = parent;
    return ListView(
      children: [
        // A topic can hold hadith of its own as well as subtopics.
        if (here != null)
          ListTile(
            key: const Key('hadith-topic-all'),
            leading: const Icon(Icons.list_rounded),
            title: Text(
              context.digits(
                l10n.hadithLibraryAllIn('${library.countIn(here)}'),
              ),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(l10n.hadithLibraryTitle)),
                  body: HadithItemList(items: library.itemsIn(here)),
                ),
              ),
            ),
          ),
        for (final t in topics)
          ListTile(
            key: Key('hadith-topic-${t.id}'),
            leading: const Icon(Icons.folder_outlined),
            title: Text(t.title),
            trailing: Text(context.digits('${library.countIn(t.id)}')),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _TopicScreen(library: library, topic: t),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopicScreen extends StatelessWidget {
  const _TopicScreen({required this.library, required this.topic});

  final HadithLibrary library;
  final HadithTopic topic;

  @override
  Widget build(BuildContext context) {
    final children = library.childrenOf(topic.id);
    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: children.isNotEmpty
          ? HadithTopicList(library: library, parent: topic.id)
          : HadithItemList(items: library.itemsIn(topic.id)),
    );
  }
}

/// Hadith titles with their grade; each opens the details screen.
class HadithItemList extends StatelessWidget {
  const HadithItemList({super.key, required this.items});

  final List<HadithLibraryItem> items;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, i) {
      final item = items[i];
      return ListTile(
        key: Key('hadith-item-${item.id}'),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.fade),
        subtitle: Text(item.grade),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HadeathDetailsScreen(hadeath: item.toEntity()),
          ),
        ),
      );
    },
  );
}
