import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../prayers/presentation/providers/'
    'prayer_times_performance_provider.dart';

class HeaderCardWidget extends StatelessWidget {
  const HeaderCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimesPerformanceProvider>(
      builder: (context, provider, child) {
        final prayerData = provider.getCurrentAndNextPrayer();
        final currentName = prayerData['currentName'] ?? '---';
        final currentTime = prayerData['currentTime'] ?? '--:--';
        final nextName = prayerData['nextName'] ?? '---';
        final nextTime = prayerData['nextTime'] ?? '--:--';

        return Container(
          margin: const EdgeInsets.all(16),
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(50),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentName,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  currentTime,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'الصلاة التالية: $nextName',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  nextTime,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
