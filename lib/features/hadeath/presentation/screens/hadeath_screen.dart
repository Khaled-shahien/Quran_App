import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../../../../core/widgets/pulse_loader.dart';
import '../providers/hadeath_provider.dart';
import '../widgets/hadeath_card.dart';

class HadeathScreen extends StatefulWidget {
  const HadeathScreen({super.key});

  @override
  State<HadeathScreen> createState() => _HadeathScreenState();
}

class _HadeathScreenState extends State<HadeathScreen> {
  @override
  void initState() {
    super.initState();
    // Load Ahadeth when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HadeathProvider>().loadAhadeth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SakinaHeroScaffold(
      title: l10nOf(context).hadeathScreenMessage1,
      slivers: [
        Consumer<HadeathProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: PulseLoader(lines: 6)),
              );
            }

            if (provider.errorMessage != null) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    provider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (provider.ahadethList.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l10nOf(context).hadeathScreenMessage2,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList.builder(
                itemCount: provider.ahadethList.length,
                itemBuilder: (context, index) {
                  final hadeath = provider.ahadethList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.ms),
                    child: HadeathCard(
                      title: hadeath.title.isEmpty
                          ? l10nOf(
                              context,
                            ).hadeathScreenMessage3(context.digits(index + 1))
                          : hadeath.title,
                      onTap: () {
                        context.push('/hadeath/details/$index', extra: hadeath);
                      },
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
