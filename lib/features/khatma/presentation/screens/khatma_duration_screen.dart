import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/khatma_provider.dart';
import '../../domain/models/khatma_model.dart';

class KhatmaDurationScreen extends StatefulWidget {
  final String startMode;
  final int? startJuz;

  const KhatmaDurationScreen({
    super.key,
    required this.startMode,
    this.startJuz,
  });

  @override
  State<KhatmaDurationScreen> createState() => _KhatmaDurationScreenState();
}

class _KhatmaDurationScreenState extends State<KhatmaDurationScreen> {
  KhatmaGoalType _goalType = KhatmaGoalType.byDuration;
  KhatmaTrackingUnit _trackingUnit = KhatmaTrackingUnit.page;
  int _durationDays = 30;
  double _dailyTarget = 20;
  int _reminderHour = 8;
  int _reminderMinute = 0;

  int get _startUnitIndex {
    final int startJuz = (widget.startJuz ?? 1).clamp(1, 30);
    switch (_trackingUnit) {
      case KhatmaTrackingUnit.page:
        return (((startJuz - 1) * 20) + 1).clamp(1, 604);
      case KhatmaTrackingUnit.hizb:
        return (((startJuz - 1) * 2) + 1).clamp(1, 60);
      case KhatmaTrackingUnit.juz:
        return startJuz;
    }
  }

  int get _totalUnits {
    switch (_trackingUnit) {
      case KhatmaTrackingUnit.page:
        return 604;
      case KhatmaTrackingUnit.hizb:
        return 60;
      case KhatmaTrackingUnit.juz:
        return 30;
    }
  }

  int get _remainingUnits => _totalUnits - _startUnitIndex + 1;

  String get _unitLabel {
    switch (_trackingUnit) {
      case KhatmaTrackingUnit.page:
        return 'صفحة';
      case KhatmaTrackingUnit.hizb:
        return 'حزب';
      case KhatmaTrackingUnit.juz:
        return 'جزء';
    }
  }

  double get _computedDailyTargetForDuration =>
      (_remainingUnits / _durationDays).clamp(1, 2000);

  String _formatDouble(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? Colors.white70 : const Color(0xFF6B6A66);
    final cardColor = isDarkMode ? AppColors.darkCardContent : Colors.white;
    final dropdownTextColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ختمة جديدة',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title text
              Text(
                'حدد نوع الخطة ووحدة المتابعة '
                'ووقت التذكير اليومي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPlanTypeCard(
                        title: 'حسب المدة',
                        subtitle:
                            'توزيع تلقائي '
                            'حتى تاريخ الإتمام',
                        active: _goalType == KhatmaGoalType.byDuration,
                        onTap: () {
                          setState(() {
                            _goalType = KhatmaGoalType.byDuration;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPlanTypeCard(
                        title: 'حسب الورد اليومي',
                        subtitle:
                            'تحدد مقدار '
                            'القراءة كل يوم',
                        active: _goalType == KhatmaGoalType.byDailyAmount,
                        onTap: () {
                          setState(() {
                            _goalType = KhatmaGoalType.byDailyAmount;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    Text(
                      'وحدة التتبع:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<KhatmaTrackingUnit>(
                            value: _trackingUnit,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isDarkMode ? Colors.white54 : Colors.grey,
                            ),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: dropdownTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: KhatmaTrackingUnit.page,
                                child: Text('صفحة (604)'),
                              ),
                              DropdownMenuItem(
                                value: KhatmaTrackingUnit.hizb,
                                child: Text('حزب (60)'),
                              ),
                              DropdownMenuItem(
                                value: KhatmaTrackingUnit.juz,
                                child: Text('جزء (30)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _trackingUnit = val;
                                  if (_goalType ==
                                      KhatmaGoalType.byDailyAmount) {
                                    _dailyTarget = _dailyTarget.clamp(
                                      1,
                                      _remainingUnits.toDouble(),
                                    );
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_goalType == KhatmaGoalType.byDuration)
                _buildDurationSection(cardColor, textColor)
              else
                _buildDailyTargetSection(cardColor, textColor),

              const SizedBox(height: 18),

              _buildReminderSection(cardColor, textColor),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _goalType == KhatmaGoalType.byDuration
                      ? 'وردك المقترح: '
                            '${_formatDouble(_computedDailyTargetForDuration)} '
                            '$_unitLabel يومياً'
                      : 'المدة المتوقعة للإتمام: '
                            '${(_remainingUnits / _dailyTarget).ceil()}'
                            ' يوماً',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Continue Button
              ElevatedButton(
                onPressed: () async {
                  final provider = Provider.of<KhatmaProvider>(
                    context,
                    listen: false,
                  );

                  final double target = _goalType == KhatmaGoalType.byDuration
                      ? _computedDailyTargetForDuration
                      : _dailyTarget;

                  final newKhatma = KhatmaModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    startMode: widget.startMode,
                    startJuz: widget.startJuz ?? 1,
                    startDate: DateTime.now(),
                    trackingUnit: _trackingUnit,
                    goalType: _goalType,
                    plannedDurationDays: _durationDays,
                    dailyTargetUnits: target,
                    completedUnits: 0,
                    reminderHour: _reminderHour,
                    reminderMinute: _reminderMinute,
                  );

                  await provider.startNewKhatma(newKhatma);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم إنشاء الختمة بنجاح!',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'الاستمرار',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanTypeCard({
    required String title,
    required String subtitle,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection(Color cardColor, Color textColor) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Text(
            'مدة الختمة:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$_durationDays يوماً',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _durationDays++),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.primary),
                  GestureDetector(
                    onTap: () {
                      if (_durationDays > 1) {
                        setState(() => _durationDays--);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.remove,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTargetSection(Color cardColor, Color textColor) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Text(
            'الورد اليومي:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${_formatDouble(_dailyTarget)} $_unitLabel',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dailyTarget = (_dailyTarget + 0.5).clamp(
                          1,
                          _remainingUnits.toDouble(),
                        );
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.primary),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dailyTarget = (_dailyTarget - 0.5).clamp(
                          1,
                          _remainingUnits.toDouble(),
                        );
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.remove,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(Color cardColor, Color textColor) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Text(
            'وقت التذكير:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _reminderHour,
                    minute: _reminderMinute,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _reminderHour = picked.hour;
                    _reminderMinute = picked.minute;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_reminderHour.toString().padLeft(2, '0')}:'
                  '${_reminderMinute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
