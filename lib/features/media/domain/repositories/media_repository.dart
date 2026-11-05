import 'package:sakina_app/core/result/result.dart';

import '../entities/article.dart';
import '../entities/video.dart';

/// Articles and videos. A failure's [Failure.cause] is a MediaException
/// whose message is already friendly Arabic copy.
abstract class MediaRepository {
  Future<Result<List<Article>>> getArticles();

  Future<Result<List<Video>>> getIslamicVideos(String query);
}
