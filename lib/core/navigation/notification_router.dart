/// Navigation callback type
typedef NavigationCallback =
    void Function(String route, Map<String, dynamic>? data);

/// Notification Router for handling notification taps
///
/// Routes users to appropriate screens based on notification payload
class NotificationRouter {
  static NavigationCallback? _onNavigate;

  /// Set navigation callback
  static void setNavigationCallback(NavigationCallback callback) {
    _onNavigate = callback;
  }

  /// Handle notification tap and navigate to appropriate screen
  static void handleNotification({
    required String type,
    Map<String, dynamic>? data,
  }) {
    switch (type) {
      case 'morning_adhkar':
        _navigateToDuas('morning', data);
        break;
      case 'evening_adhkar':
        _navigateToDuas('evening', data);
        break;
      case 'mulk_surah':
        _navigateToSurah(67, data);
        break;
      case 'baqarah_surah':
        _navigateToSurah(2, data);
        break;
      case 'prayer_time':
        _navigateToPrayerTimes(data);
        break;
      case 'khatma':
        _navigateToKhatma(data);
        break;
      case 'general':
      default:
        _navigateToHome(data);
        break;
    }
  }

  /// Navigate to Duas screen
  static void _navigateToDuas(String dhikrType, Map<String, dynamic>? data) {
    if (_onNavigate != null) {
      _onNavigate!('/duas', {...?data, 'type': dhikrType});
    }
  }

  /// Navigate to specific Surah
  static void _navigateToSurah(int surahNumber, Map<String, dynamic>? data) {
    if (_onNavigate != null) {
      _onNavigate!('/quran', {...?data, 'surahNumber': surahNumber});
    }
  }

  /// Navigate to Prayer Times
  static void _navigateToPrayerTimes(Map<String, dynamic>? data) {
    if (_onNavigate != null) {
      _onNavigate!('/prayers', data);
    }
  }

  /// Navigate to the active Khatma area on the home screen.
  static void _navigateToKhatma(Map<String, dynamic>? data) {
    if (_onNavigate != null) {
      _onNavigate!('/khatma', data);
    }
  }

  /// Navigate to Home
  static void _navigateToHome(Map<String, dynamic>? data) {
    if (_onNavigate != null) {
      _onNavigate!('/', data);
    }
  }

  /// Clear navigation callback
  static void clearNavigationCallback() {
    _onNavigate = null;
  }
}
