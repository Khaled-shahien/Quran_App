import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sakina_app/core/result/result.dart';

import '../../domain/entities/recitation.dart';
import '../../domain/repositories/recitation_repository.dart';
import '../datasources/quran_cdn_recitation_source.dart';

/// Directory that holds downloaded surahs (one folder per reciter).
typedef DownloadsDirectory = Future<Directory> Function();

class RecitationRepositoryImpl implements RecitationRepository {
  RecitationRepositoryImpl({
    required QuranCdnRecitationSource remote,
    required DownloadsDirectory downloadsDirectory,
    AssetBundle? bundle,
  }) : _remote = remote,
       _downloadsDirectory = downloadsDirectory,
       _bundle = bundle ?? rootBundle;

  static const String recitersAsset = 'assets/recitation_reciters.json';

  final QuranCdnRecitationSource _remote;
  final DownloadsDirectory _downloadsDirectory;
  final AssetBundle _bundle;
  final Map<(int, int), ChapterRecitation> _chapters = {};
  List<RecitationReciter>? _reciters;

  static Failure _map(Object error) => switch (error) {
    SocketException() ||
    TimeoutException() ||
    HttpException() => NetworkFailure(cause: error),
    RecitationHttpException(:final statusCode) => ServerFailure(
      statusCode: statusCode,
      cause: error,
    ),
    FormatException() => ServerFailure(cause: error),
    FileSystemException() => StorageFailure(cause: error),
    _ => UnexpectedFailure(cause: error),
  };

  Future<File> _audioFile(int reciterId, int surah) async =>
      File('${(await _downloadsDirectory()).path}/$reciterId/$surah.mp3');

  Future<File> _timingsFile(int reciterId, int surah) async =>
      File('${(await _downloadsDirectory()).path}/$reciterId/$surah.json');

  @override
  Future<Result<List<RecitationReciter>>> reciters() async {
    final cached = _reciters;
    if (cached != null) return Success(cached);
    return Result.guard(() async {
      final list = jsonDecode(await _bundle.loadString(recitersAsset)) as List;
      return _reciters = List.unmodifiable([
        for (final r in list.cast<Map<String, dynamic>>())
          RecitationReciter(
            id: r['id'] as int,
            name: r['name'] as String,
            style: RecitationStyle.parse(r['style']),
          ),
      ]);
    }, onError: (e, _) => ContentFailure(cause: e));
  }

  @override
  Future<Result<ChapterRecitation>> chapter(int reciterId, int surah) async {
    final key = (reciterId, surah);
    final cached = _chapters[key];
    if (cached != null) return Success(cached);
    return Result.guard(() async {
      final local = await _timingsFile(reciterId, surah);
      final chapter = await local.exists()
          ? QuranCdnRecitationSource.parseChapter(
              reciterId,
              surah,
              await local.readAsString(),
            )
          : await _remote.fetchChapter(reciterId, surah);
      return _chapters[key] = chapter;
    }, onError: (e, _) => _map(e));
  }

  @override
  Future<Result<String>> playableSource(int reciterId, int surah) async {
    if (await isDownloaded(reciterId, surah)) {
      return Success((await _audioFile(reciterId, surah)).path);
    }
    final result = await chapter(reciterId, surah);
    return switch (result) {
      Success(:final value) => Success(value.audioUrl),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<int>> downloadSize(int reciterId, int surah) async {
    final result = await chapter(reciterId, surah);
    return switch (result) {
      Success(:final value) => Result.guard(
        () => _remote.fileSize(value.audioUrl),
        onError: (e, _) => _map(e),
      ),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Stream<DownloadProgress> download(int reciterId, int surah) async* {
    final chapterResult = await chapter(reciterId, surah);
    final ChapterRecitation info = switch (chapterResult) {
      Success(:final value) => value,
      Err(:final failure) => throw failure,
    };
    final audio = await _audioFile(reciterId, surah);
    final partial = File('${audio.path}.part');
    await audio.parent.create(recursive: true);
    IOSink? sink;
    var completed = false;
    try {
      final response = await _remote.openStream(info.audioUrl);
      final total = response.contentLength;
      sink = partial.openWrite();
      var received = 0;
      yield DownloadProgress(received: 0, total: total);
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        yield DownloadProgress(received: received, total: total);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (total != null && received != total) {
        throw HttpException('Incomplete download ($received of $total)');
      }
      await (await _timingsFile(
        reciterId,
        surah,
      )).writeAsString(QuranCdnRecitationSource.encodeChapter(info));
      await partial.rename(audio.path);
      completed = true;
    } finally {
      // A failed or cancelled download never leaves a half file behind.
      await sink?.close();
      if (!completed) {
        if (await partial.exists()) await partial.delete();
      }
    }
  }

  @override
  Future<bool> isDownloaded(int reciterId, int surah) async {
    try {
      return await (await _audioFile(reciterId, surah)).exists() &&
          await (await _timingsFile(reciterId, surah)).exists();
    } on FileSystemException {
      return false;
    }
  }

  @override
  Future<Result<List<DownloadedSurah>>> downloads() => Result.guard(() async {
    final root = await _downloadsDirectory();
    if (!await root.exists()) return const <DownloadedSurah>[];
    final found = <DownloadedSurah>[];
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.mp3')) continue;
      final segments = entity.uri.pathSegments;
      final reciterId = int.tryParse(segments[segments.length - 2]);
      final surah = int.tryParse(segments.last.replaceAll('.mp3', ''));
      if (reciterId == null || surah == null) continue;
      if (!await isDownloaded(reciterId, surah)) continue;
      found.add(
        DownloadedSurah(
          reciterId: reciterId,
          surah: surah,
          bytes: await entity.length(),
        ),
      );
    }
    found.sort(
      (a, b) => a.reciterId != b.reciterId
          ? a.reciterId.compareTo(b.reciterId)
          : a.surah.compareTo(b.surah),
    );
    return found;
  }, onError: (e, _) => _map(e));

  @override
  Future<Result<void>> deleteDownload(int reciterId, int surah) =>
      Result.guard(() async {
        for (final f in [
          await _audioFile(reciterId, surah),
          await _timingsFile(reciterId, surah),
        ]) {
          if (await f.exists()) await f.delete();
        }
      }, onError: (e, _) => _map(e));
}
