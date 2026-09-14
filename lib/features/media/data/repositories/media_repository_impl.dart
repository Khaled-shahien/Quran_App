import 'dart:async';
import 'dart:io';

import 'package:sakina_app/features/media/data/datasources/articles_remote_datasource.dart';
import 'package:sakina_app/features/media/data/datasources/audio_remote_datasource.dart';
import 'package:sakina_app/features/media/data/datasources/video_remote_datasource.dart';
import 'package:sakina_app/features/media/data/models/surah_audio_model.dart';
import 'package:sakina_app/features/media/domain/entities/article.dart';
import 'package:sakina_app/features/media/domain/entities/reciter.dart';
import 'package:sakina_app/features/media/domain/entities/surah_audio.dart';
import 'package:sakina_app/features/media/domain/entities/video.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({
    required ArticlesRemoteDataSource articlesDataSource,
    required AudioRemoteDataSource audioDataSource,
    required VideoRemoteDataSource videoDataSource,
  }) : _articlesDataSource = articlesDataSource,
       _audioDataSource = audioDataSource,
       _videoDataSource = videoDataSource;

  final ArticlesRemoteDataSource _articlesDataSource;
  final AudioRemoteDataSource _audioDataSource;
  final VideoRemoteDataSource _videoDataSource;

  @override
  Future<List<Article>> getArticles() async {
    try {
      return await _articlesDataSource.getArticles();
    } catch (error) {
      throw _mapError(error, fallback: 'تعذر تحميل المقالات');
    }
  }

  @override
  Future<List<Reciter>> getReciters() async {
    try {
      return await _audioDataSource.getReciters();
    } catch (error) {
      throw _mapError(error, fallback: 'تعذر تحميل الصوتيات');
    }
  }

  @override
  Future<List<SurahAudio>> getSurahAudios(Reciter reciter) async {
    final surahNumbers = reciter.surahNumbers..sort();
    return surahNumbers
        .where(reciter.hasSurah)
        .map((surahNumber) => SurahAudioModel.fromReciter(reciter, surahNumber))
        .toList(growable: false);
  }

  @override
  Future<List<Video>> getIslamicVideos(String query) async {
    try {
      return await _videoDataSource.searchVideos(query);
    } catch (error) {
      throw _mapError(error, fallback: 'تعذر تحميل الفيديوهات');
    }
  }

  MediaException _mapError(Object error, {required String fallback}) {
    if (error is MissingApiKeyException) return error;
    if (error is QuotaExceededException) return error;
    if (error is MediaException) return error;
    if (error is TimeoutException) {
      return const MediaException('انتهت مهلة الاتصال، حاول مرة أخرى');
    }
    if (error is SocketException) {
      return const MediaException('تحقق من اتصالك بالإنترنت');
    }
    if (error is FormatException) {
      return const MediaException('تعذر قراءة البيانات المستلمة');
    }
    return MediaException('$fallback، حاول مرة أخرى');
  }
}
