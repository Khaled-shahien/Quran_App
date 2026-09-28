import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/features/media/presentation/providers/articles_provider.dart';
import 'package:sakina_app/features/media/presentation/widgets/article_card.dart';
import 'package:sakina_app/features/media/presentation/widgets/media_state_views.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key});

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ArticlesProvider>();
      if (!provider.isLoading && provider.articles.isEmpty) {
        provider.loadArticles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المقالات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Consumer<ArticlesProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) return const MediaLoadingView();

              if (provider.hasError) {
                return MediaErrorView(
                  message: provider.errorMessage!,
                  onRetry: provider.loadArticles,
                );
              }

              return Column(
                children: [
                  _SourceChips(provider: provider),
                  Expanded(
                    child: provider.articles.isEmpty
                        ? const MediaEmptyView(
                            message: 'لا توجد مقالات متاحة حالياً',
                            icon: Icons.article_outlined,
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadArticles,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              itemCount: provider.articles.length,
                              itemBuilder: (context, index) {
                                return ArticleCard(
                                  article: provider.articles[index],
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
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({required this.provider});

  final ArticlesProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sources = provider.sourceNames;

    if (sources.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: sources.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final source = isAll ? null : sources[index - 1];
          final selected = provider.selectedSource == source;

          return ChoiceChip(
            label: Text(
              isAll ? 'كل المصادر' : source!,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: selected ? theme.colorScheme.onPrimary : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            selected: selected,
            selectedColor: theme.colorScheme.primary,
            onSelected: (_) => provider.filterBySource(source),
          );
        },
      ),
    );
  }
}
