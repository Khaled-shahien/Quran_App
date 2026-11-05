import 'package:sakina_app/core/result/result.dart';

import '../../domain/entities/hadeath_entity.dart';
import '../../domain/repositories/hadeath_repository.dart';
import '../data_sources/local_hadeath_data_source.dart';

class HadeathRepositoryImpl implements HadeathRepository {
  final LocalHadeathDataSource localDataSource;

  HadeathRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<List<HadeathEntity>>> getAllAhadeth() => Result.guard(
    localDataSource.loadAhadeth,
    onError: (error, _) => ContentFailure(cause: error),
  );
}
