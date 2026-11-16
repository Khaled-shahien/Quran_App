import 'package:sakina_app/core/widgets/sakina_hero_app_bar.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import '../widgets/media_tiles_widget.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SakinaHeroScaffold(
      title: l10nOf(context).homeScreenMessage28,
      slivers: const [
        Directionality(
          textDirection: TextDirection.rtl,
          child: SliverPadding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            sliver: MediaTilesWidget(),
          ),
        ),
      ],
    );
  }
}
