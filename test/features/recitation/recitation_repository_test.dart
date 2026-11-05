import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sakina_app/core/result/result.dart';
import 'package:sakina_app/features/recitation/data/datasources/quran_cdn_recitation_source.dart';
import 'package:sakina_app/features/recitation/data/repositories/recitation_repository_impl.dart';
import 'package:sakina_app/features/recitation/domain/entities/recitation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixture = File(
    'test/fixtures/quran_cdn_chapter_7_1.json',
  ).readAsStringSync();
  const audioUrl =
      'https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/1.mp3';
  final audioBytes = List<int>.generate(5000, (i) => i % 251);

  late Directory dir;
  late int apiCalls;
  late bool offline;

  RecitationRepositoryImpl repository() => RecitationRepositoryImpl(
    remote: QuranCdnRecitationSource(
      client: MockClient.streaming((request, _) async {
        if (offline) throw const SocketException('offline');
        if (request.url.host == 'api.quran.com') {
          apiCalls++;
          return http.StreamedResponse(
            Stream.value(fixture.codeUnits),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.url.toString() == audioUrl) {
          return http.StreamedResponse(
            Stream.fromIterable([
              audioBytes.sublist(0, 2000),
              audioBytes.sublist(2000),
            ]),
            200,
            contentLength: audioBytes.length,
            headers: {'content-length': '${audioBytes.length}'},
          );
        }
        return http.StreamedResponse(const Stream.empty(), 404);
      }),
    ),
    downloadsDirectory: () async => dir,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('recitation_test');
    apiCalls = 0;
    offline = false;
  });
  tearDown(() => dir.delete(recursive: true));

  test(
    'bundled reciters are the ten verified ones, with Arabic names',
    () async {
      final reciters = (await repository().reciters()).valueOrNull!;
      expect(reciters.map((r) => r.id), [7, 2, 1, 6, 12, 9, 3, 10, 4, 5]);
      expect(reciters.first.name, 'مشاري راشد العفاسي');
      expect(
        reciters.map((r) => r.id),
        isNot(contains(8)),
        reason: 'Minshawi mujawwad audio returns 404',
      );
      expect(
        reciters.map((r) => r.id),
        isNot(contains(11)),
        reason: 'id 11 serves another reciter\'s files',
      );
    },
  );

  test('parses real API timings for Al-Fatiha', () async {
    final chapter = (await repository().chapter(7, 1)).valueOrNull!;
    expect(chapter.audioUrl, audioUrl);
    expect(chapter.timings.map((t) => t.ayah), [1, 2, 3, 4, 5, 6, 7]);
    expect(chapter.timings.first.from, Duration.zero);
    expect(chapter.ayahAt(const Duration(milliseconds: 6100)), 2);
  });

  test('chapters are cached in memory', () async {
    final repo = repository();
    await repo.chapter(7, 1);
    await repo.chapter(7, 1);
    expect(apiCalls, 1);
  });

  test('offline without a download is a NetworkFailure', () async {
    offline = true;
    final result = await repository().chapter(7, 1);
    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('malformed timings are rejected', () {
    expect(
      () => QuranCdnRecitationSource.parseChapter(7, 2, fixture),
      throwsFormatException,
      reason: 'timings belong to surah 1, not 2',
    );
  });

  test('download saves audio and timings, then plays offline', () async {
    final repo = repository();
    final progress = await repo.download(7, 1).toList();

    expect(progress.last.received, audioBytes.length);
    expect(progress.last.fraction, 1);
    expect(await repo.isDownloaded(7, 1), isTrue);
    expect(await File('${dir.path}/7/1.mp3').readAsBytes(), audioBytes);

    // A fresh repository with no network still has the surah.
    offline = true;
    final fresh = repository();
    final source = (await fresh.playableSource(7, 1)).valueOrNull!;
    expect(source, endsWith('1.mp3'));
    expect(File(source).existsSync(), isTrue);
    expect((await fresh.chapter(7, 1)).valueOrNull!.timings, hasLength(7));
  });

  test('downloads can be listed and deleted', () async {
    final repo = repository();
    await repo.download(7, 1).drain<void>();

    final list = (await repo.downloads()).valueOrNull!;
    expect(list.single.reciterId, 7);
    expect(list.single.surah, 1);
    expect(list.single.bytes, audioBytes.length);

    await repo.deleteDownload(7, 1);
    expect(await repo.isDownloaded(7, 1), isFalse);
    expect((await repo.downloads()).valueOrNull, isEmpty);
  });

  test('a failed download leaves no partial file', () async {
    final repo = repository();
    await repo.chapter(7, 1); // timings known, then the network drops
    offline = true;
    await expectLater(repo.download(7, 1).drain<void>(), throwsA(anything));
    expect(
      Directory('${dir.path}/7').existsSync()
          ? Directory('${dir.path}/7').listSync()
          : const <FileSystemEntity>[],
      isEmpty,
    );
    expect(await repo.isDownloaded(7, 1), isFalse);
  });

  test('download size comes from the server headers', () async {
    final client = MockClient((request) async {
      if (request.method == 'HEAD') {
        return http.Response('', 200, headers: {'content-length': '839808'});
      }
      return http.Response(
        fixture,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final repo = RecitationRepositoryImpl(
      remote: QuranCdnRecitationSource(client: client),
      downloadsDirectory: () async => dir,
    );
    expect((await repo.downloadSize(7, 1)).valueOrNull, 839808);
  });

  test('DownloadProgress handles unknown totals', () {
    expect(const DownloadProgress(received: 10).fraction, isNull);
    expect(const DownloadProgress(received: 5, total: 10).fraction, 0.5);
  });
}
