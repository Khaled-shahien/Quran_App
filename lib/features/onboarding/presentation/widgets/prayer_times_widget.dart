import 'package:sakina_app/l10n/localization.dart';
import '../../../prayers/domain/prayer_time_zone.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/widgets/pulse_loader.dart';
import '../../../prayers/presentation/providers/prayer_times_provider.dart';

class PrayerTimesWidget extends StatefulWidget {
  const PrayerTimesWidget({super.key});

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget> {
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Initialize with a default location (Cairo coordinates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prayerProvider = Provider.of<PrayerTimesProvider>(
        context,
        listen: false,
      );
      prayerProvider.fetchTodayForCurrentLocation();
    });

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: PulseLoader(lines: 4),
            ),
          );
        }

        if (provider.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  l10nOf(context).prayerTimesWidgetMessage1,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/prayers'),
                  child: Text(l10nOf(context).prayerTimesWidgetMessage2),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage ??
                      l10nOf(context).prayerTimesWidgetMessage3,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (provider.hasData) {
          return _buildPrayerTimesContent(provider);
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10nOf(context).prayerTimesWidgetMessage4,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrayerTimesContent(PrayerTimesProvider provider) {
    final prayerTimes = provider.getMainPrayerTimes();
    // Filter out Sunrise as it's not a prayer
    final mainPrayers = Map<String, String>.fromEntries(
      prayerTimes.entries.where((e) => e.key != 'Sunrise'),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Next Prayer Card
          _buildNextPrayerCard(mainPrayers),
          const SizedBox(height: 20),
          // Prayer Times List Header
          Text(
            appL10n.prayerTimesWidgetMessage5,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          // Prayer Times List
          _buildPrayerTimesList(mainPrayers),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(Map<String, String> prayerTimes) {
    final nextPrayerInfo = _getNextPrayer(prayerTimes);
    final nextPrayerName = nextPrayerInfo['name'] as String;
    final nextPrayerTime = nextPrayerInfo['time'] as String;
    final timeRemaining = nextPrayerInfo['remaining'] as String;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.brown.shade800,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade600.withValues(alpha: 0.8),
              Colors.brown.shade900.withValues(alpha: 0.95),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Next Prayer Label
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                appL10n.prayerTimesWidgetMessage6,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Prayer Name
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                nextPrayerName,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Prayer Time and Remaining Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appL10n.prayerTimesWidgetMessage7,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeRemaining,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  nextPrayerTime,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(Map<String, String> prayerTimes) {
    final arabicNames = {
      'Fajr': appL10n.prayerTimesWidgetMessage8,
      'Dhuhr': appL10n.prayerTimesWidgetMessage9,
      'Asr': appL10n.prayerTimesWidgetMessage10,
      'Maghrib': appL10n.prayerTimesWidgetMessage11,
      'Isha': appL10n.prayerTimesWidgetMessage12,
    };

    final nextPrayerInfo = _getNextPrayer(prayerTimes);
    final currentPrayerName = nextPrayerInfo['name'] as String;

    return Column(
      children: prayerTimes.entries.map((entry) {
        final arabicName = arabicNames[entry.key] ?? entry.key;
        final isCurrentPrayer = arabicName == currentPrayerName;

        return _prayerTimeTile(
          prayerName: arabicName,
          prayerTime: entry.value,
          isNext: isCurrentPrayer,
        );
      }).toList(),
    );
  }

  Widget _prayerTimeTile({
    required String prayerName,
    required String prayerTime,
    required bool isNext,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isNext
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNext
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: isNext ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            prayerName,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isNext
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              prayerTime,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isNext
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get next prayer information
  Map<String, dynamic> _getNextPrayer(Map<String, String> prayerTimes) {
    const englishOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final arabicNames = {
      'Fajr': appL10n.prayerTimesWidgetMessage8,
      'Dhuhr': appL10n.prayerTimesWidgetMessage9,
      'Asr': appL10n.prayerTimesWidgetMessage10,
      'Maghrib': appL10n.prayerTimesWidgetMessage11,
      'Isha': appL10n.prayerTimesWidgetMessage12,
    };

    final now = context.read<PrayerTimesProvider>().locationNow;
    DateTime? nextPrayerTime;
    String? nextPrayerName;

    for (int i = 0; i < englishOrder.length; i++) {
      final prayerName = englishOrder[i];
      final timeStr = prayerTimes[prayerName];

      if (timeStr != null && timeStr != 'N/A') {
        final prayerDateTime = _parseTime(timeStr);
        if (prayerDateTime != null && prayerDateTime.isAfter(now)) {
          nextPrayerTime = prayerDateTime;
          nextPrayerName = arabicNames[prayerName];
          break;
        }
      }
    }

    if (nextPrayerTime == null) {
      return {
        'name': appL10n.prayerTimesWidgetMessage13,
        'time': '--:--',
        'remaining': appL10n.prayerTimesWidgetMessage14,
      };
    }

    final timeRemaining = nextPrayerTime.difference(now);
    final hoursStr = timeRemaining.inHours.toString();
    final minutesStr = (timeRemaining.inMinutes % 60).toString();

    String remainingText = '';
    if (timeRemaining.inHours > 0) {
      remainingText = appL10n.prayerTimesWidgetMessage15(
        (hoursStr).toString(),
        (minutesStr).toString(),
      );
    } else {
      remainingText = appL10n.prayerTimesWidgetMessage16(
        (minutesStr).toString(),
      );
    }

    return {
      'name': nextPrayerName ?? appL10n.prayerTimesWidgetMessage8,
      'time': _formatTimeForDisplay(nextPrayerTime),
      'remaining': remainingText,
    };
  }

  /// Parse time string to DateTime
  DateTime? _parseTime(String timeStr) {
    try {
      // Remove AM/PM markers from the formatted time
      final cleanTime = timeStr.replaceAll('ص', '').replaceAll('م', '').trim();
      final parts = cleanTime.split(':');

      if (parts.length < 2) return null;

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Check if it's PM
      if (timeStr.contains('م')) {
        if (hour != 12) hour += 12;
      } else {
        if (hour == 12) hour = 0;
      }

      final now = context.read<PrayerTimesProvider>().locationNow;
      return prayerInstant(
        now,
        hour,
        minute,
        context.read<PrayerTimesProvider>().prayerTimes?.timezone,
      );
    } catch (e) {
      return null;
    }
  }

  /// Format time for display
  String _formatTimeForDisplay(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
