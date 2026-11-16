import 'package:flutter/material.dart';
import 'package:sakina_app/l10n/localization.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/sakina_segmented.dart';

/// Switches the lower half of the home screen between the category grid
/// and today's prayer times.
class TabSwitcherWidget extends StatelessWidget {
  final Function(int) onTabChanged;
  final int selectedIndex;

  const TabSwitcherWidget({
    super.key,
    required this.onTabChanged,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SakinaSegmented(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.md,
      ),
      labels: [
        l10nOf(context).tabSwitcherWidgetMessage1,
        l10nOf(context).prayerTitle,
      ],
      selectedIndex: selectedIndex,
      onChanged: onTabChanged,
    );
  }
}
