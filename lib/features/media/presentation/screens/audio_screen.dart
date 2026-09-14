import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/features/media/domain/entities/reciter.dart';
import 'package:sakina_app/features/media/presentation/providers/audio_provider.dart';
import 'package:sakina_app/features/media/presentation/widgets/audio_player_sheet.dart';
import 'package:sakina_app/features/media/presentation/widgets/media_state_views.dart';
import 'package:sakina_app/features/media/presentation/widgets/reciter_card.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AudioProvider>();
      if (!provider.isLoading && provider.reciters.isEmpty) {
        provider.loadReciters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الصوتيات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Consumer<AudioProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) return const MediaLoadingView();

              if (provider.hasError) {
                return MediaErrorView(
                  message: provider.errorMessage!,
                  onRetry: provider.loadReciters,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchField(
                    controller: _searchController,
                    onChanged: provider.search,
                  ),
                  if (provider.featuredReciters.isNotEmpty &&
                      provider.searchQuery.isEmpty)
                    _FeaturedReciters(
                      reciters: provider.featuredReciters,
                      onTap: (reciter) => _showSurahs(context, reciter),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      provider.searchQuery.isEmpty
                          ? 'كل القراء'
                          : 'نتائج البحث',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: provider.filteredReciters.isEmpty
                        ? const MediaEmptyView(
                            message: 'لا توجد نتائج مطابقة',
                            icon: Icons.graphic_eq_rounded,
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadReciters,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              itemCount: provider.filteredReciters.length,
                              itemBuilder: (context, index) {
                                final reciter =
                                    provider.filteredReciters[index];
                                return ReciterCard(
                                  reciter: reciter,
                                  onTap: () => _showSurahs(context, reciter),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showSurahs(BuildContext context, Reciter reciter) async {
    final provider = context.read<AudioProvider>();
    final surahs = await provider.getSurahAudios(reciter);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => AudioPlayerSheet(reciter: reciter, surahs: surahs),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث باسم القارئ',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'مسح البحث',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}

class _FeaturedReciters extends StatelessWidget {
  const _FeaturedReciters({required this.reciters, required this.onTap});

  final List<Reciter> reciters;
  final ValueChanged<Reciter> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: reciters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final reciter = reciters[index];
          return SizedBox(
            width: 250,
            child: ReciterCard(
              compact: true,
              reciter: reciter,
              onTap: () => onTap(reciter),
            ),
          );
        },
      ),
    );
  }
}
