import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4D3F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _tabButton(context, l10nOf(context).tabSwitcherWidgetMessage1, 0),
          _tabButton(context, l10nOf(context).prayerTitle, 1),
        ],
      ),
    );
  }

  Widget _tabButton(BuildContext context, String text, int index) {
    bool active = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          onTabChanged(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.lightPageAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
