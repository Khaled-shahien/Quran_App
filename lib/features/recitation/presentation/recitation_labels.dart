import 'package:sakina_app/core/result/failure_messages.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/core/utils/surah_names.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

import '../domain/entities/recitation.dart';

/// Arabic labels shared by the recitation screens.
extension RecitationLabels on AppLocalizations {
  String reciterLabel(RecitationReciter r) => switch (r.style) {
    RecitationStyle.murattal => '${r.name} • $recitationStyleMurattal',
    RecitationStyle.mujawwad => '${r.name} • $recitationStyleMujawwad',
    RecitationStyle.muallim => '${r.name} • $recitationStyleMuallim',
    RecitationStyle.unspecified => r.name,
  };

  String surahTitle(int surah) =>
      surahAudioModelMessage1(surahNameAr(surah) ?? '$surah');

  String recitationFailure(Failure? failure) => switch (failure) {
    NetworkFailure() => recitationOffline,
    null => recitationError,
    _ => '$recitationError. ${failureMessage(failure, this)}',
  };

  String megabytes(int bytes) =>
      recitationSizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));
}
