import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sakina_app/core/theme/app_colors.dart';
import 'package:sakina_app/core/widgets/pulse_loader.dart';
import 'package:sakina_app/features/prayers/presentation/providers/'
    'prayer_times_performance_provider.dart';

/// Performance-optimized Prayer Times Widget
///
/// Uses selective rebuilds and const constructors for maximum performance
class PrayerTimesPerformanceWidget extends StatelessWidget {
  const PrayerTimesPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with const constructor for performance
          const _PrayerTimesHeader(),
          const SizedBox(height: 16),

          // Main content with selective rebuilds
          _PrayerTimesContent(),
        ],
      ),
    );
  }
}

/// Const header widget for performance
class _PrayerTimesHeader extends StatelessWidget {
  const _PrayerTimesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'أوقات الصلاة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const Spacer(),
        const _RefreshButton(),
      ],
    );
  }
}

/// Performance-optimized refresh button
class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimesPerformanceProvider>(
      builder: (context, provider, child) {
        return IconButton(
          onPressed: provider.isLoading ? null : () => provider.refresh(),
          icon: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: PulseLoader(
                    lines: 1,
                    lineHeight: 4,
                    padding: EdgeInsets.zero,
                  ),
                )
              : Icon(
                  Icons.refresh,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
        );
      },
    );
  }
}

/// Performance-optimized content with selective rebuilds
class _PrayerTimesContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimesPerformanceProvider>(
      builder: (context, provider, child) {
        // Handle loading state
        if (provider.isLoading) {
          return const _LoadingIndicator();
        }

        // Handle error state
        if (provider.hasError) {
          return _ErrorDisplay(errorMessage: provider.errorMessage!);
        }

        // Handle empty state
        if (!provider.hasData) {
          return const _EmptyState();
        }

        // Display prayer times with const optimizations
        return _PrayerTimesList(provider: provider);
      },
    );
  }
}

/// Const loading indicator
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          PulseLoader(lines: 3),
          SizedBox(height: 16),
          Text('جاري تحميل أوقات الصلاة...'),
        ],
      ),
    );
  }
}

/// Error display widget
class _ErrorDisplay extends StatelessWidget {
  final String errorMessage;

  const _ErrorDisplay({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          'حدث خطأ في تحميل أوقات الصلاة',
          style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage,
          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Const empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.access_time_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text('لا توجد بيانات متاحة'),
      ],
    );
  }
}

/// Performance-optimized prayer times list
class _PrayerTimesList extends StatelessWidget {
  final PrayerTimesPerformanceProvider provider;

  const _PrayerTimesList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final prayerTimes = provider.getMainPrayerTimes();

    // Define Arabic names in the correct order
    final arabicNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    return Column(
      children: prayerTimes.entries.map((entry) {
        final englishName = entry.key;
        final time = entry.value;
        final arabicName = arabicNames[englishName] ?? englishName;

        return _PrayerTimeTile(prayerName: arabicName, prayerTime: time);
      }).toList(),
    );
  }
}

/// Const prayer time tile for maximum performance
class _PrayerTimeTile extends StatelessWidget {
  final String prayerName;
  final String prayerTime;

  const _PrayerTimeTile({required this.prayerName, required this.prayerTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            prayerName,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.lightOnSurface,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              prayerTime,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
