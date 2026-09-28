import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/settings_provider.dart';

/// Loads the saved time before presenting editable controls.
class AlarmTimePickerDialog extends StatefulWidget {
  const AlarmTimePickerDialog({
    super.key,
    required this.alarmType,
    required this.title,
  });
  final String alarmType;
  final String title;
  @override
  State<AlarmTimePickerDialog> createState() => _AlarmTimePickerDialogState();
}

class _AlarmTimePickerDialogState extends State<AlarmTimePickerDialog> {
  TimeOfDay? _time;
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<SettingsProvider>().getAlarmTime(
        widget.alarmType,
      );
      if (mounted) {
        setState(
          () => _time = TimeOfDay(
            hour: data['hour'] ?? 7,
            minute: data['minute'] ?? 0,
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل وقت التذكير');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<SettingsProvider>().setAlarmTime(
        type: widget.alarmType,
        hour: _time!.hour,
        minute: _time!.minute,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('تم حفظ وقت ${widget.title}')),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'تعذر حفظ الوقت. أعد المحاولة.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: _error != null
        ? Text(_error!)
        : _time == null
        ? const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          )
        : TextButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text(_time!.format(context)),
            onPressed: _saving
                ? null
                : () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _time!,
                      helpText: widget.title,
                    );
                    if (mounted && time != null) setState(() => _time = time);
                  },
          ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: _time == null || _saving ? null : _save,
        child: const Text('حفظ'),
      ),
    ],
  );
}
