/// Prayer Times Entity
///
/// Domain entity representing prayer times for a specific date and location
class PrayerTimesEntity {
  final DateTime? fetchedAt;
  final bool isStale;
  final bool isCached;
  final String? fajr;
  final String? sunrise;
  final String? dhuhr;
  final String? asr;
  final String? maghrib;
  final String? isha;
  final String? imsak;
  final String? midnight;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final int? calculationMethod;
  final bool? lunarSighting;

  PrayerTimesEntity({
    this.fetchedAt,
    this.isStale = false,
    this.isCached = false,
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
    this.imsak,
    this.midnight,
    this.latitude,
    this.longitude,
    this.timezone,
    this.calculationMethod,
    this.lunarSighting,
  });

  /// Get all main prayer times as a map
  Map<String, String?> getMainPrayerTimes() {
    return {
      'Fajr': fajr,
      'Sunrise': sunrise,
      'Dhuhr': dhuhr,
      'Asr': asr,
      'Maghrib': maghrib,
      'Isha': isha,
    };
  }

  /// Check if all main prayer times are available
  bool get hasCompleteData {
    return fajr != null &&
        sunrise != null &&
        dhuhr != null &&
        asr != null &&
        maghrib != null &&
        isha != null;
  }

  /// Get formatted prayer times for display
  Map<String, String> getFormattedPrayerTimes() {
    return {
      'Fajr': _formatTo12Hour(fajr),
      'Sunrise': _formatTo12Hour(sunrise),
      'Dhuhr': _formatTo12Hour(dhuhr),
      'Asr': _formatTo12Hour(asr),
      'Maghrib': _formatTo12Hour(maghrib),
      'Isha': _formatTo12Hour(isha),
    };
  }

  /// Helper to format 24-hour time to 12-hour AM/PM format
  String _formatTo12Hour(String? time24) {
    if (time24 == null || time24.isEmpty) return 'N/A';
    try {
      // Remove any timezone info like "05:12 (EEST)" that the API might return
      final timePart = time24.split(' ')[0];
      final parts = timePart.split(':');
      if (parts.length < 2) return time24;

      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      final String period = hour >= 12 ? 'م' : 'ص';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      final String hourStr = hour.toString().padLeft(2, '0');
      final String minuteStr = minute.toString().padLeft(2, '0');

      return '$hourStr:$minuteStr $period';
    } catch (e) {
      return time24;
    }
  }

  @override
  String toString() {
    return 'PrayerTimesEntity('
        'fajr: $fajr, sunrise: $sunrise, dhuhr: $dhuhr, '
        'asr: $asr, maghrib: $maghrib, isha: $isha)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerTimesEntity &&
        other.fajr == fajr &&
        other.sunrise == sunrise &&
        other.dhuhr == dhuhr &&
        other.asr == asr &&
        other.maghrib == maghrib &&
        other.isha == isha;
  }

  @override
  int get hashCode {
    return Object.hash(fajr, sunrise, dhuhr, asr, maghrib, isha);
  }
}
