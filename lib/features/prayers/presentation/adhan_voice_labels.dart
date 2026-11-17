import 'package:sakina_app/l10n/app_localizations.dart';

import '../domain/adhan_voices.dart';

extension AdhanVoiceLabels on AppLocalizations {
  /// The name shown for a recording. Ids without a name of their own fall
  /// back to the section title, so a new recording never shows a raw id.
  String adhanVoiceName(AdhanVoice voice) => switch (voice.id) {
    'ali_mulla' => adhanVoiceAliMulla,
    'nasser_alqatami' => adhanVoiceNasserAlqatami,
    'naqshbandi' => adhanVoiceNaqshbandi,
    'islam_sobhi' => adhanVoiceIslamSobhi,
    _ => adhanVoiceTitle,
  };
}
