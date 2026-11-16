import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/features/media/presentation/providers/video_provider.dart';
import 'package:sakina_app/features/media/presentation/widgets/media_state_views.dart';
import 'package:sakina_app/features/media/presentation/widgets/video_card.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoProvider>();
      if (!provider.isLoading &&
          provider.videos.isEmpty &&
          provider.channels.isEmpty) {
        provider.loadVideos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SakinaHeroScaffold(
        title: l10nOf(context).videoScreenMessage1,
        onRefresh: context.read<VideoProvider>().loadVideos,
        slivers: [
          Consumer<VideoProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: MediaLoadingView(),
                );
              }

              if (provider.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: MediaErrorView(
                    message: provider.errorMessage!,
                    onRetry: provider.loadVideos,
                  ),
                );
              }

              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(child: _CategoryChips(provider: provider)),
                  if (provider.fallbackMessage != null)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          provider.fallbackMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (provider.channels.isNotEmpty)
                    _FallbackChannels(provider: provider)
                  else if (provider.videos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: MediaEmptyView(
                        message: l10nOf(context).videoScreenMessage2,
                        icon: Icons.video_library_outlined,
                      ),
                    )
                  else
                    _VideoResults(provider: provider),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.provider});

  final VideoProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = VideoProvider.categories.entries.toList();

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final entry = categories[index];
          final selected = provider.selectedQuery == entry.value;

          return ChoiceChip(
            label: Text(
              entry.key,
              style: TextStyle(
                color: selected ? theme.colorScheme.onPrimary : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            selected: selected,
            selectedColor: theme.colorScheme.primary,
            onSelected: (_) => provider.loadVideos(entry.value),
          );
        },
      ),
    );
  }
}

class _VideoResults extends StatelessWidget {
  const _VideoResults({required this.provider});

  final VideoProvider provider;

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.sm,
    AppSpacing.md,
    AppSpacing.lg,
  );

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        // One column on phones, a grid on wider screens.
        if (constraints.crossAxisExtent < 640) {
          return SliverPadding(
            padding: _padding,
            sliver: SliverList.builder(
              itemCount: provider.videos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: VideoCard(video: provider.videos[index]),
                );
              },
            ),
          );
        }

        return SliverPadding(
          padding: _padding,
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.08,
            ),
            itemCount: provider.videos.length,
            itemBuilder: (context, index) {
              return VideoCard(video: provider.videos[index]);
            },
          ),
        );
      },
    );
  }
}

class _FallbackChannels extends StatelessWidget {
  const _FallbackChannels({required this.provider});

  final VideoProvider provider;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      sliver: SliverList.builder(
        itemCount: provider.channels.length,
        itemBuilder: (context, index) {
          return VideoChannelCard(channel: provider.channels[index]);
        },
      ),
    );
  }
}
