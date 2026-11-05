import 'package:sakina_app/core/result/result.dart';

import '../entities/hadeath_entity.dart';

abstract class HadeathRepository {
  /// All bundled ahadith in file order, or a [ContentFailure].
  Future<Result<List<HadeathEntity>>> getAllAhadeth();
}
