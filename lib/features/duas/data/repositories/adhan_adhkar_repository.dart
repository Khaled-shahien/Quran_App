import 'package:flutter/services.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/azkar_repository.dart'
    show parseAzkarCategories;
import 'package:sakina_app/features/duas/domain/repositories/adhan_adhkar_repository.dart';

export 'package:sakina_app/features/duas/domain/repositories/adhan_adhkar_repository.dart';

class AdhanAdhkarRepositoryImpl implements AdhanAdhkarRepository {
  AdhanAdhkarRepositoryImpl({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const String asset = 'assets/adhan_adhkar.json';
  final AssetBundle _bundle;

  /// Text is returned exactly as bundled.
  @override
  Future<Result<List<AzkarItemModel>>> getAdhanAdhkar() => Result.guard(
    () async => parseAzkarCategories(
      await _bundle.loadString(asset),
    ).expand((c) => c.items).toList(),
    onError: (error, _) => ContentFailure(cause: error),
  );
}
