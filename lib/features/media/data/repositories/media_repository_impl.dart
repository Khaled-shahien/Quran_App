import 'package:sakina_app/l10n/localization.dart';
import 'dart:async';
import 'dart:io';

import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/media/data/datasources/articles_remote_datasource.dart';
import 'package:sakina_app/features/media/data/datasources/video_remote_datasource.dart';
import 'package:sakina_app/features/media/domain/entities/article.dart';
import 'package:sakina_app/features/media/domain/entities/video.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({
    required ArticlesRemoteDataSource articlesDataSource,
    required VideoRemoteDataSource videoDataSource,
  }) : _articlesDataSource = articlesDataSource,
       _videoDataSource = videoDataSource;

  final ArticlesRemoteDataSource _articlesDataSource;
  final VideoRemoteDataSource _videoDataSource;

  @override
  Future<Result<List<Article>>> getArticles() => Result.guard(
    _articlesDataSource.getArticles,
    onError: (error, _) =>
        _failure(error, fallback: appL10n.mediaRepositoryImplMessage1),
  );

  @override
  Future<Result<List<Video>>> getIslamicVideos(String query) => Result.guard(
    () => _videoDataSource.searchVideos(query),
    onError: (error, _) =>
        _failure(error, fallback: appL10n.mediaRepositoryImplMessage3),
  );

  /// Wraps a friendly [MediaException] as the failure's cause.
  static Failure _failure(Object error, {required String fallback}) {
    final media = _mapError(error, fallback: fallback);
    return switch (error) {
      SocketException() || TimeoutException() => NetworkFailure(cause: media),
      _ => ServerFailure(cause: media),
    };
  }

  static MediaException _mapError(Object error, {required String fallback}) {
    if (error is MediaException) return error;
    if (error is TimeoutException) {
      return MediaException(appL10n.mediaRepositoryImplMessage4);
    }
    if (error is SocketException) {
      return MediaException(appL10n.mediaRepositoryImplMessage5);
    }
    if (error is FormatException) {
      return MediaException(appL10n.mediaRepositoryImplMessage6);
    }
    return MediaException(
      appL10n.mediaRepositoryImplMessage7((fallback).toString()),
    );
  }
}
