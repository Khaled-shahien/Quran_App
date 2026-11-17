import 'entities/adhan_settings.dart';

/// One bundled adhan recording. Every recording is offered for all five
/// prayers, Fajr included; each prayer keeps its own choice.
///
/// The audio lives in `android/app/src/main/res/raw/<resource>.mp3`, where
/// Android can use it as a notification channel sound. The files are the
/// owner-supplied MP3s, copied unchanged; their source and rights status
/// are in `ADHAN_AUDIO_LIBRARY.md`.
class AdhanVoice {
  const AdhanVoice({
    required this.id,
    required this.originalFilename,
    required this.duration,
    required this.sizeBytes,
  });

  /// Stable id, stored in preferences. Never rename one.
  final String id;

  /// The file name the owner supplied, kept for traceability.
  final String originalFilename;

  /// Length of the recording (measured with ffprobe).
  final Duration duration;

  /// Size of the bundled file in bytes; the tests check the file matches.
  final int sizeBytes;

  /// Container and codec of the bundled file.
  String get format => 'mp3';

  /// Android raw resource name (no extension).
  String get resource => 'adhan_$id';

  /// Path of the bundled file inside the project.
  String get assetPath => 'android/app/src/main/res/raw/$resource.$format';

  /// Android fixes a channel's sound when it is created, so every recording
  /// has its own channel. Bump the version if a recording is replaced.
  String get channelId => 'prayer_adhan_${id}_v1';

  /// The same file for in-app preview, through the player's raw-resource
  /// support (empty host = this app's own package).
  Uri get previewUri => Uri.parse('android.resource:///raw/$resource');
}

/// The bundled recordings and how a prayer picks one.
abstract final class AdhanVoices {
  static const List<AdhanVoice> all = [
    AdhanVoice(
      id: 'ali_mulla',
      originalFilename: 'الاذان بصوت ( علي احمد ملا ) .mp3',
      duration: Duration(milliseconds: 205125),
      sizeBytes: 4348364,
    ),
    AdhanVoice(
      id: 'nasser_alqatami',
      originalFilename: 'الاذان بصوت ( ناصر القطامى ) .mp3',
      duration: Duration(milliseconds: 135233),
      sizeBytes: 2898360,
    ),
    AdhanVoice(
      id: 'naqshbandi',
      originalFilename: 'الاذان بصوت ( النقشبندي ) .mp3',
      duration: Duration(milliseconds: 163074),
      sizeBytes: 2779557,
    ),
    AdhanVoice(
      id: 'islam_sobhi',
      originalFilename: 'الاذان بصوت ( اسلام صبحي ) .mp3',
      duration: Duration(milliseconds: 171828),
      sizeBytes: 3302243,
    ),
  ];

  /// Android channels of recordings that were bundled before and removed.
  /// They are deleted at start-up so the system settings do not list
  /// channels whose sound no longer exists.
  static const List<String> retiredChannelIds = [
    'prayer_adhan_asim_javed_v1',
    'prayer_adhan_moazzam_mirza_v1',
    'prayer_adhan_shalqar_v1',
    'prayer_adhan_nigeria_v1',
    'prayer_adhan_fajr_gocek_v1',
  ];

  static AdhanVoice? byId(String? id) {
    for (final v in all) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// The stored choice when it is a bundled recording, otherwise the first
  /// one. Unknown or removed ids (e.g. an earlier recording) never fail.
  static AdhanVoice resolve(String? id) => byId(id) ?? all.first;
}

extension AdhanSettingsVoices on AdhanSettings {
  /// The recording [prayer] plays in adhan mode.
  AdhanVoice voiceFor(DailyPrayer prayer) =>
      AdhanVoices.resolve(voices[prayer]);
}
