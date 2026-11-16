import '../services/notification_style.dart';

/// Navigation callback type
typedef NavigationCallback =
    void Function(String route, Map<String, dynamic>? data);

/// Notification Router for handling notification taps
///
/// Routes users to appropriate screens based on notification payload
class NotificationRouter {
  static NavigationCallback? _onNavigate;
  static bool _held = false;
  static ({String type, Map<String, dynamic>? data, String? actionId})?
  _pending;

  /// Keep taps until startup routing has finished, so it cannot replace them.
  static void hold() {
    _held = true;
  }

  /// Deliver the latest held tap, or discard it when it must not interrupt
  /// the screen startup routing chose.
  static void release({bool dropPending = false}) {
    _held = false;
    final pending = _pending;
    _pending = null;
    if (pending != null && !dropPending) {
      handleNotification(
        type: pending.type,
        data: pending.data,
        actionId: pending.actionId,
      );
    }
  }

  /// Set navigation callback
  static void setNavigationCallback(NavigationCallback callback) {
    _onNavigate = callback;
  }

  /// Handle a tap on a notification, or on one of its buttons ([actionId]),
  /// and navigate to the screen it belongs to.
  static void handleNotification({
    required String type,
    Map<String, dynamic>? data,
    String? actionId,
  }) {
    if (_held || _onNavigate == null) {
      _pending = (type: type, data: data, actionId: actionId);
      return;
    }
    // The "prayer times" button goes there from any prayer notification.
    if (actionId == NotificationActionIds.prayerTimes) {
      _onNavigate!('/prayers', null);
      return;
    }
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
        // Before the prayer, the reminder opens the times; at the prayer,
        // the alert opens the dua after the adhan.
        if (data?['reminder'] == true) {
          _onNavigate!('/prayers', null);
        } else {
          _navigateToPrayerTimes(data);
        }
        break;
      case 'daily_verse':
        final int? surah = int.tryParse('${data?['surahNumber']}');
        if (surah == null) {
          _navigateToHome(data);
        } else {
          _navigateToSurah(surah, data);
        }
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
    _held = false;
    _pending = null;
  }
}
