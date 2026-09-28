import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/media/domain/entities/article.dart';
import 'package:sakina_app/features/media/domain/errors/media_exception.dart';
import 'package:sakina_app/features/media/domain/repositories/media_repository.dart';
import 'package:sakina_app/features/media/domain/usecases/get_articles.dart';
import 'package:sakina_app/features/media/presentation/providers/articles_provider.dart';

class _ArticlesRepository implements MediaRepository {
  Future<List<Article>> Function() response = () async => [];

  @override
  Future<List<Article>> getArticles() => response();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('network failure ends loading and retry restores articles', () async {
    final repository = _ArticlesRepository();
    final provider = ArticlesProvider(getArticles: GetArticles(repository));
    addTearDown(provider.dispose);
    repository.response = () async => throw const MediaException('offline');

    await provider.loadArticles();
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, 'offline');
    expect(provider.articles, isEmpty);

    final pending = Completer<List<Article>>();
    repository.response = () => pending.future;
    final retry = provider.loadArticles();
    expect(provider.isLoading, isTrue);
    expect(provider.hasError, isFalse);
    final article = Article(
      title: 'Article',
      description: 'Description',
      link: 'https://example.com/article',
      pubDate: DateTime(2026),
      sourceName: 'Source',
      category: 'General',
    );
    pending.complete([article]);
    await retry;
    expect(provider.isLoading, isFalse);
    expect(provider.hasError, isFalse);
    expect(provider.articles, [article]);
  });
}
