import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moments in the app that may give touch or sound feedback.
enum FeedbackEvent {
  /// One tasbih count.
  tasbihCount,

  /// A tasbih phrase reached its target.
  tasbihSetComplete,

  /// One repetition of a dhikr.
  adhkarCount,

  /// A dhikr reached its repetitions, or the whole category finished.
  adhkarComplete,

  /// The phone just turned to face the qibla.
  qiblaAligned,

  /// A counter was reset.
  reset,
}

enum HapticKind { selection, light, medium, heavy, success }

/// What each event does. Kept as data so it can be reviewed and tested.
const Map<FeedbackEvent, ({HapticKind haptic, bool sound})> feedbackMap = {
  FeedbackEvent.tasbihCount: (haptic: HapticKind.selection, sound: true),
  FeedbackEvent.tasbihSetComplete: (haptic: HapticKind.success, sound: true),
  FeedbackEvent.adhkarCount: (haptic: HapticKind.light, sound: true),
  FeedbackEvent.adhkarComplete: (haptic: HapticKind.success, sound: true),
  FeedbackEvent.qiblaAligned: (haptic: HapticKind.success, sound: false),
  FeedbackEvent.reset: (haptic: HapticKind.medium, sound: false),
};

/// Device side of feedback, replaceable in tests.
abstract interface class FeedbackPlatform {
  Future<void> haptic(HapticKind kind);
  Future<void> click();
}

/// Uses the system's own haptics and click sound: no audio files or
/// extra packages, and it follows the phone's touch-feedback settings.
class SystemFeedbackPlatform implements FeedbackPlatform {
  const SystemFeedbackPlatform();

  @override
  Future<void> haptic(HapticKind kind) async {
    switch (kind) {
      case HapticKind.selection:
        await HapticFeedback.selectionClick();
      case HapticKind.light:
        await HapticFeedback.lightImpact();
      case HapticKind.medium:
        await HapticFeedback.mediumImpact();
      case HapticKind.heavy:
        await HapticFeedback.heavyImpact();
      case HapticKind.success:
        // A distinct double pulse so a finished set is felt, not just seen.
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 140));
        await HapticFeedback.heavyImpact();
    }
  }

  @override
  Future<void> click() => SystemSound.play(SystemSoundType.click);
}

/// The single place that decides whether a moment vibrates or clicks.
/// Haptics are on by default; sounds are off by default.
class FeedbackService extends ChangeNotifier {
  FeedbackService({
    required SharedPreferences preferences,
    FeedbackPlatform platform = const SystemFeedbackPlatform(),
  }) : _prefs = preferences,
       _platform = platform,
       _haptics = preferences.getBool(hapticsKey) ?? true,
       _sounds = preferences.getBool(soundsKey) ?? false;

  static const String hapticsKey = 'feedback_haptics_enabled';
  static const String soundsKey = 'feedback_sounds_enabled';

  final SharedPreferences _prefs;
  final FeedbackPlatform _platform;
  bool _haptics;
  bool _sounds;

  bool get hapticsEnabled => _haptics;
  bool get soundsEnabled => _sounds;

  Future<void> setHapticsEnabled(bool value) async {
    if (value == _haptics) return;
    _haptics = value;
    notifyListeners();
    await _prefs.setBool(hapticsKey, value);
  }

  Future<void> setSoundsEnabled(bool value) async {
    if (value == _sounds) return;
    _sounds = value;
    notifyListeners();
    await _prefs.setBool(soundsKey, value);
  }

  /// Fire-and-forget: feedback must never block or break the action.
  void play(FeedbackEvent event) {
    final spec = feedbackMap[event]!;
    if (_haptics) unawaited(_safely(() => _platform.haptic(spec.haptic)));
    if (_sounds && spec.sound) unawaited(_safely(_platform.click));
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Feedback unavailable: $error');
    }
  }
}

/// Plays [event] if the app provides a [FeedbackService]; silent otherwise.
void playFeedback(BuildContext context, FeedbackEvent event) {
  Provider.of<FeedbackService?>(context, listen: false)?.play(event);
}
