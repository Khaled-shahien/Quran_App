import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الفيديوهات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Consumer<VideoProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) return const MediaLoadingView();

              if (provider.hasError) {
                return MediaErrorView(
                  message: provider.errorMessage!,
                  onRetry: provider.loadVideos,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CategoryChips(provider: provider),
                  if (provider.fallbackMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        provider.fallbackMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Expanded(
                    child: provider.channels.isNotEmpty
                        ? _FallbackChannels(provider: provider)
                        : provider.videos.isEmpty
                        ? const MediaEmptyView(
                            message: 'لا توجد فيديوهات متاحة حالياً',
                            icon: Icons.video_library_outlined,
                          )
                        : _VideoResults(provider: provider),
                  ),
                ],
              );
            },
          ),
        ),
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
              style: GoogleFonts.cairo(
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return RefreshIndicator(
            onRefresh: provider.loadVideos,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
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

        return RefreshIndicator(
          onRefresh: provider.loadVideos,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
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
    return RefreshIndicator(
      onRefresh: provider.loadVideos,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: provider.channels.length,
        itemBuilder: (context, index) {
          return VideoChannelCard(channel: provider.channels[index]);
        },
      ),
    );
  }
}
