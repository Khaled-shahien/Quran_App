import 'package:sakina_app/core/result/result.dart';
import '../entities/video.dart';
import '../repositories/media_repository.dart';

class GetIslamicVideos {
  const GetIslamicVideos(this._repository);

  final MediaRepository _repository;

  Future<Result<List<Video>>> call(String query) {
    return _repository.getIslamicVideos(query);
  }
}
