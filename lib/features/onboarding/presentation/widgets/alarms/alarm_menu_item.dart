import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/settings_provider.dart';
import 'alarm_time_picker_dialog.dart';

/// A clickable alarm menu item with time display
class AlarmMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String alarmType;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const AlarmMenuItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.alarmType,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return FutureBuilder<Map<String, int>>(
      future: Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).getAlarmTime(alarmType),
      builder: (context, snapshot) {
        String timeText = '--:--';

        if (snapshot.hasData) {
          final data = snapshot.data;
          final hour = data?['hour'] ?? 0;
          final minute = data?['minute'] ?? 0;
          timeText = _formatTime(hour, minute);
        }

        return ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(title),
          subtitle: Text('$subtitle • $timeText'),
          trailing: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () => _showTimePicker(context),
            tooltip: 'تعديل وقت $title',
          ),
          onTap: () => _showTimePicker(context),
        );
      },
    );
  }

  /// Show time picker dialog
  void _showTimePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlarmTimePickerDialog(alarmType: alarmType, title: title);
      },
    );
  }

  /// Format time for display
  String _formatTime(int hour, int minute) {
    final String minuteStr = minute.toString().padLeft(2, '0');
    final String period = hour >= 12 ? 'م' : 'ص';

    int displayHour = hour;
    if (displayHour > 12) {
      displayHour -= 12;
    } else if (displayHour == 0) {
      displayHour = 12;
    }

    return '${displayHour.toString().padLeft(2, '0')}:$minuteStr $period';
  }
}
