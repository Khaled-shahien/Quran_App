import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/duas/data/models/azkar_model.dart';
import 'package:sakina_app/features/duas/data/repositories/duas_repository.dart';
import 'package:sakina_app/features/duas/presentation/providers/duas_provider.dart';

class FakeDuasRepository implements DuasRepository {
  final List<AzkarCategoryModel> data;
  final bool shouldThrow;

  FakeDuasRepository({required this.data, this.shouldThrow = false});

  @override
  Future<List<AzkarCategoryModel>> getAllDuas() async {
    if (shouldThrow) {
      throw Exception('failed');
    }
    return data;
  }
}

void main() {
  test('DuasProvider loads categories successfully', () async {
    final fakeCategory = AzkarCategoryModel(
      id: 1,
      category: 'أدعية القرآن',
      items: <AzkarItemModel>[
        AzkarItemModel(
          id: 1,
          title: 'دعاء',
          text: 'ربنا آتنا',
          repeat: 1,
          reference: 'البقرة',
        ),
      ],
    );

    final provider = DuasProvider(
      repository: FakeDuasRepository(data: <AzkarCategoryModel>[fakeCategory]),
    );

    await provider.loadDuas();

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.categories, hasLength(1));
    expect(provider.getCategoryByName('أدعية القرآن')?.id, 1);
  });

  test('DuasProvider exposes error when repository fails', () async {
    final provider = DuasProvider(
      repository: FakeDuasRepository(
        data: <AzkarCategoryModel>[],
        shouldThrow: true,
      ),
    );

    await provider.loadDuas();

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNotNull);
    expect(provider.categories, isEmpty);
  });
}
