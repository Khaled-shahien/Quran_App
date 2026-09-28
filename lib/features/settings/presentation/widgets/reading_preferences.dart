import 'package:sakina_app/l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared reading preferences used by settings and the Quran reader.
class ReadingPreferences {
  static const fontKey = 'reading_font_size';
  static const heightKey = 'reading_line_height';
  static const markersKey = 'reading_verse_markers';

  static double fontSize(SharedPreferences prefs) =>
      (prefs.getDouble(fontKey) ?? 28).clamp(22, 38);
  static double lineHeight(SharedPreferences prefs) =>
      (prefs.getDouble(heightKey) ?? 1.95).clamp(1.5, 2.5);
}

class ReadingPreferencesPanel extends StatefulWidget {
  const ReadingPreferencesPanel({super.key, required this.preferences});
  final SharedPreferences preferences;

  @override
  State<ReadingPreferencesPanel> createState() =>
      _ReadingPreferencesPanelState();
}

class _ReadingPreferencesPanelState extends State<ReadingPreferencesPanel> {
  @override
  Widget build(BuildContext context) {
    final prefs = widget.preferences;
    return Column(
      children: [
        ListTile(title: Text(l10nOf(context).readingPreferencesMessage1)),
        Slider(
          value: ReadingPreferences.fontSize(prefs),
          min: 22,
          max: 38,
          divisions: 16,
          label: ReadingPreferences.fontSize(prefs).round().toString(),
          semanticFormatterCallback: (value) => l10nOf(
            context,
          ).readingPreferencesMessage2((value.round()).toString()),
          onChanged: (value) {
            prefs.setDouble(ReadingPreferences.fontKey, value);
            setState(() {});
          },
        ),
        ListTile(title: Text(l10nOf(context).readerControlsMessage7)),
        Slider(
          value: ReadingPreferences.lineHeight(prefs),
          min: 1.5,
          max: 2.5,
          divisions: 20,
          semanticFormatterCallback: (value) => l10nOf(
            context,
          ).readingPreferencesMessage3((value.toStringAsFixed(2)).toString()),
          onChanged: (value) {
            prefs.setDouble(ReadingPreferences.heightKey, value);
            setState(() {});
          },
        ),
        SwitchListTile(
          title: Text(l10nOf(context).readerControlsMessage8),
          value: prefs.getBool(ReadingPreferences.markersKey) ?? true,
          onChanged: (value) {
            prefs.setBool(ReadingPreferences.markersKey, value);
            setState(() {});
          },
        ),
      ],
    );
  }
}
