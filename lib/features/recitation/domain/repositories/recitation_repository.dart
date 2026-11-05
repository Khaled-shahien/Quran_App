import 'package:sakina_app/core/result/result.dart';

import '../entities/recitation.dart';

/// Quran recitation audio: reciters, per-surah audio with ayah timings, and
/// surahs saved for offline listening.
abstract interface class RecitationRepository {
  /// The verified reciters, bundled with the app (works offline).
  Future<Result<List<RecitationReciter>>> reciters();

  /// Audio for [surah] by [reciterId]. A downloaded copy is used first, so
  /// this works offline after download.
  Future<Result<ChapterRecitation>> chapter(int reciterId, int surah);

  /// Where the audio should be read from: a local file path when the surah
  /// was downloaded, otherwise the remote URL.
  Future<Result<String>> playableSource(int reciterId, int surah);

  /// Size in bytes of the remote file, to show before downloading.
  Future<Result<int>> downloadSize(int reciterId, int surah);

  /// Downloads the surah; emits progress and completes when saved.
  /// The partial file is removed if the download fails or is cancelled.
  Stream<DownloadProgress> download(int reciterId, int surah);

  Future<Result<List<DownloadedSurah>>> downloads();

  Future<bool> isDownloaded(int reciterId, int surah);

  Future<Result<void>> deleteDownload(int reciterId, int surah);
}
