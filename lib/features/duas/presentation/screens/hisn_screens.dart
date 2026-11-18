import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/feedback/feedback_service.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/theme/app_typography.dart';
import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/core/widgets/sakina_card.dart';
import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/widgets/status_view.dart';
import 'package:sakina_app/features/quran/domain/services/quran_search.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../data/hisn_almuslim.dart';

/// All chapters of Hisn al-Muslim, searchable by title.
class HisnChaptersScreen extends StatefulWidget {
  const HisnChaptersScreen({super.key, this.source});

  final HisnAlMuslim? source;

  @override
  State<HisnChaptersScreen> createState() => _HisnChaptersScreenState();
}

class _HisnChaptersScreenState extends State<HisnChaptersScreen> {
  late HisnAlMuslim _source = widget.source ?? HisnAlMuslim.bundled;
  late Future<List<HisnChapter>> _chapters = _source.chapters();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    return SakinaHeroScaffold(
      title: l10n.hisnTitle,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: TextField(
              decoration: InputDecoration(
                labelText: l10n.hisnSearch,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
        FutureBuilder<List<HisnChapter>>(
          future: _chapters,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: StatusView.error(
                  message: l10n.hisnLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: () => setState(() {
                    _source = widget.source ?? HisnAlMuslim();
                    _chapters = _source.chapters();
                  }),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: PulseLoader(lines: 6)),
              );
            }
            final String needle = normalizeArabicSearch(_query.trim());
            final List<HisnChapter> shown = [
              for (final c in snapshot.data!)
                if (needle.isEmpty ||
                    normalizeArabicSearch(c.title).contains(needle))
                  c,
            ];
            return SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList.builder(
                itemCount: shown.length + 1,
                itemBuilder: (context, index) {
                  if (index == shown.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        l10n.hisnSource,
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }
                  final HisnChapter c = shown[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SakinaCard(
                      onTap: () => context.push(
                        '/duas/hisn/${c.id}',
                        extra: widget.source,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            l10n.hisnEntryCount(
                              context.digits(c.entries.length),
                            ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// One chapter: every entry with a tap counter up to its repeat count.
class HisnChapterScreen extends StatefulWidget {
  const HisnChapterScreen({super.key, required this.chapterId, this.source});

  final int chapterId;
  final HisnAlMuslim? source;

  @override
  State<HisnChapterScreen> createState() => _HisnChapterScreenState();
}

class _HisnChapterScreenState extends State<HisnChapterScreen> {
  late final Future<HisnChapter?> _chapter =
      (widget.source ?? HisnAlMuslim.bundled).chapter(widget.chapterId);
  final Map<int, int> _counts = {};

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final ThemeData theme = Theme.of(context);
    return FutureBuilder<HisnChapter?>(
      future: _chapter,
      builder: (context, snapshot) {
        final HisnChapter? chapter = snapshot.data;
        return SakinaHeroScaffold(
          title: chapter?.title ?? l10n.hisnTitle,
          slivers: [
            if (snapshot.connectionState != ConnectionState.done)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: PulseLoader(lines: 6)),
              )
            else if (chapter == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: StatusView.error(message: l10n.hisnLoadFailed),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList.builder(
                  itemCount: chapter.entries.length,
                  itemBuilder: (context, index) {
                    final HisnEntry e = chapter.entries[index];
                    final int done = _counts[e.id] ?? 0;
                    final bool finished = done >= e.repeat;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SakinaCard(
                        onTap: finished
                            ? null
                            : () {
                                playFeedback(
                                  context,
                                  done + 1 >= e.repeat
                                      ? FeedbackEvent.adhkarComplete
                                      : FeedbackEvent.adhkarCount,
                                );
                                setState(() => _counts[e.id] = done + 1);
                              },
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              e.text.trim(),
                              style: AppTypography.script.copyWith(
                                fontSize: 20,
                                height: 1.9,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Icon(
                                  finished
                                      ? Icons.check_circle_rounded
                                      : Icons.touch_app_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  finished
                                      ? l10n.hisnDone
                                      : l10n.hisnProgress(
                                          context.digits(done),
                                          context.digits(e.repeat),
                                        ),
                                  style: theme.textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
