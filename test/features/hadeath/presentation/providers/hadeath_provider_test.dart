import 'package:flutter_test/flutter_test.dart';

import 'package:sakina_app/features/hadeath/domain/entities/hadeath_entity.dart';
import 'package:sakina_app/features/hadeath/domain/repositories/hadeath_repository.dart';
import 'package:sakina_app/features/hadeath/presentation/providers/hadeath_provider.dart';

class FakeHadeathRepository implements HadeathRepository {
  final List<HadeathEntity> data;
  final bool shouldThrow;

  FakeHadeathRepository({required this.data, this.shouldThrow = false});

  @override
  Future<List<HadeathEntity>> getAllAhadeth() async {
    if (shouldThrow) {
      throw Exception('network error');
    }
    return data;
  }
}

void main() {
  test('HadeathProvider loads ahadeth list', () async {
    final provider = HadeathProvider(
      repository: FakeHadeathRepository(
        data: const <HadeathEntity>[
          HadeathEntity(title: 'الحديث الأول', content: <String>['النص']),
        ],
      ),
    );

    await provider.loadAhadeth();

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.ahadethList, hasLength(1));
  });

  test('HadeathProvider sets localized error on failure', () async {
    final provider = HadeathProvider(
      repository: FakeHadeathRepository(
        data: const <HadeathEntity>[],
        shouldThrow: true,
      ),
    );

    await provider.loadAhadeth();

    expect(provider.isLoading, isFalse);
    expect(provider.ahadethList, isEmpty);
    expect(provider.errorMessage, contains('حدث خطأ أثناء تحميل الأحاديث'));
  });
}
