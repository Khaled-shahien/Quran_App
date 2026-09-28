import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_provider.dart';

class QuranSettingsDialog extends StatelessWidget {
  const QuranSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Balance close button
                Text(
                  l10nOf(context).quranSettingsDialogMessage1,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  tooltip: l10nOf(context).quranSettingsDialogMessage2,
                  icon: const Icon(Icons.close),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 30),

            // Theme Settings
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10nOf(context).quranSettingsDialogMessage3,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                );
              },
            ),

            // Here you can add more settings later, like Font Size
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
