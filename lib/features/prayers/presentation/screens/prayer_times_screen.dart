import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_ar.dart';
import '../../domain/prayer_time_zone.dart';
import 'prayer_location_dialog.dart';
import '../../domain/prayer_calculation_policy.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../core/widgets/pulse_loader.dart';
import '../providers/prayer_times_provider.dart';

/// Prayer Times Screen
///
/// Displays prayer times for the current day with loading and error states
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen>
    with WidgetsBindingObserver {
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load only the location explicitly configured by the user.
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
      if (!mounted) return;
      final provider = context.read<PrayerTimesProvider>();
      final loaded = provider.loadedDate;
      final now = context.read<PrayerTimesProvider>().locationNow;
      if (loaded != null &&
          (loaded.year != now.year ||
              loaded.month != now.month ||
              loaded.day != now.day)) {
        provider.refresh();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PrayerTimesProvider>().refresh();
    }
  }

  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsAr();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.prayerTitle,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تعديل الموقع وطريقة الحساب',
            icon: const Icon(Icons.edit_location_alt),
            onPressed: () => showPrayerLocationDialog(
              context,
              context.read<PrayerTimesProvider>(),
            ),
          ),
          IconButton(
            tooltip: 'استخدام موقع الجهاز وإرساله لحساب المواقيت',
            icon: const Icon(Icons.my_location),
            onPressed: () =>
                context.read<PrayerTimesProvider>().useDeviceLocation(),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<PrayerTimesProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: PulseLoader(lines: 6));
            }

            if (provider.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.prayerLoadError,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'خطأ في تحميل أوقات الصلاة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage ?? 'خطأ غير معروف',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'إعادة تحميل مواقيت الصلاة',
                      child: ElevatedButton(
                        onPressed: () {
                          provider.fetchTodayForCurrentLocation();
                        },
                        child: Text(
                          l10n.retry,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.hasData) {
              return _buildPrayerTimesContent(provider);
            }

            return Center(child: Text(l10n.choosePrayerLocation));
          },
        ),
      ),
    );
  }

  Widget _buildPrayerTimesContent(PrayerTimesProvider provider) {
    final prayerTimes = provider.getMainPrayerTimes();
    final now = context.read<PrayerTimesProvider>().locationNow;
    final formattedDate = '${now.day}/${now.month}/${now.year}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${provider.locationLabel} • ${PrayerCalculationPolicy.methods[provider.selectedMethod]}\n'
              '${provider.prayerTimes?.timezone ?? ""} • ${provider.selectedCoordinates?.latitude.toStringAsFixed(4)}, ${provider.selectedCoordinates?.longitude.toStringAsFixed(4)}',
              textAlign: TextAlign.center,
            ),
          ),
          if (provider.prayerTimes?.isCached == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${provider.prayerTimes!.isStale ? "مواقيت محفوظة قديمة؛ تعذر تحديثها" : "مواقيت محفوظة"} • ${provider.prayerTimes!.fetchedAt}',
                textAlign: TextAlign.center,
              ),
            ),
          TextButton(
            onPressed: provider.refresh,
            child: const Text('تحديث المواقيت'),
          ),
          // Next Prayer Card
          _buildNextPrayerCard(prayerTimes),
          const SizedBox(height: 24),
          // All Prayer Times
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todayPrayerTimes,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مواقيت الصلاة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPrayerTimesList(prayerTimes),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
      margin: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.brown.shade800,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.amber.shade600.withValues(alpha: 0.8),
              Colors.brown.shade900.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Next Prayer Label
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الصلاة القادمة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ),
              // Prayer Name and Time
              Column(
                children: [
                  Text(
                    'صلاة $nextPrayerName',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        nextPrayerTime,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'في',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            timeRemaining,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(Map<String, String> prayerTimes) {
    const arabicNames = {
      'Fajr': 'الفجر',
      'Sunrise': 'الشروق',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    final nextPrayerInfo = _getNextPrayer(prayerTimes);
    final currentPrayerName = nextPrayerInfo['name'] as String;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prayerTimes.length,
      itemBuilder: (context, index) {
        final entry = prayerTimes.entries.elementAt(index);
        final arabicName = arabicNames[entry.key] ?? entry.key;
        final isCurrentPrayer = arabicName == currentPrayerName;

        return _prayerTimeTile(
          prayerName: arabicName,
          prayerTime: entry.value,
          isNext: isCurrentPrayer,
        );
      },
    );
  }

  Widget _prayerTimeTile({
    required String prayerName,
    required String prayerTime,
    required bool isNext,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNext
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 16,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isNext
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              prayerTime,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
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
    const arabicNames = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
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
        'name': 'الفجر غداً',
        'time': '--:--',
        'remaining': 'تتوفر المواقيت عند تحديث يوم الغد',
      };
    }

    final timeRemaining = nextPrayerTime.difference(now);
    final hoursStr = timeRemaining.inHours.toString();
    final minutesStr = (timeRemaining.inMinutes % 60).toString();

    String remainingText = '';
    if (timeRemaining.inHours > 0) {
      remainingText = '$hoursStr ساعة و$minutesStr دقيقة';
    } else {
      remainingText = '$minutesStr دقيقة';
    }

    return {
      'name': nextPrayerName ?? 'الفجر',
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

      // Check if it's PM (after 12:00 already converted form)
      // Since the display format already handles AM/PM, we need to preserve the logic
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
