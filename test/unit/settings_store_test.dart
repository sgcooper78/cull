import 'dart:convert';
import 'dart:io';

import 'package:cull/data/settings/scrub_settings.dart';
import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/data/settings/sort_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late JsonFileSettingsStore store;
  late File file;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cull_settings_test');
    file = File(p.join(tmp.path, 'settings.json'));
    store = JsonFileSettingsStore(file);
  });

  tearDown(() => tmp.delete(recursive: true));

  test('missing file -> null', () async {
    expect(await store.loadScrub(), isNull);
  });

  test('save then load round-trips', () async {
    const s = MediaScrubSettings(playSeconds: 7, skipPercent: 20);
    await store.saveScrub(s);
    expect(await store.loadScrub(), s);
  });

  test('corrupt file -> null', () async {
    await file.writeAsString('{ nope');
    expect(await store.loadScrub(), isNull);
  });

  test('sort round-trips', () async {
    expect(await store.loadSort(), isNull);
    const s = SortSettings(
      key: SortKey.size,
      ascending: false,
      foldersFirst: false,
    );
    await store.saveSort(s);
    expect(await store.loadSort(), s);
  });

  test('scrub and sort coexist in one file', () async {
    await store.saveScrub(
      const MediaScrubSettings(playSeconds: 3, skipPercent: 10),
    );
    await store.saveSort(SortSettings.defaults);

    expect((await store.loadScrub())?.playSeconds, 3);
    expect(await store.loadSort(), SortSettings.defaults);
  });

  test('recent folders round-trip', () async {
    expect(await store.loadRecentFolders(), isEmpty);
    await store.saveRecentFolders([r'C:\b', r'C:\a']);
    expect(await store.loadRecentFolders(), [r'C:\b', r'C:\a']);
  });

  test('saveScrub leaves unrelated keys intact', () async {
    await file.writeAsString(jsonEncode({'other': 42}));
    await store.saveScrub(
      const MediaScrubSettings(playSeconds: 3, skipPercent: 10),
    );

    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(raw['other'], 42);
    expect(raw['scrub'], {'playSeconds': 3, 'skipPercent': 10});
  });

  test('comicScrub missing -> null', () async {
    expect(await store.loadComicScrub(), isNull);
  });

  test('comicScrub save then load round-trips', () async {
    const s = ComicScrubSettings(pageSeconds: 6, pageSkip: 12);
    await store.saveComicScrub(s);
    expect(await store.loadComicScrub(), s);
  });

  test('comicScrub corrupt file -> null', () async {
    await file.writeAsString('{ nope');
    expect(await store.loadComicScrub(), isNull);
  });

  test('saveComicScrub leaves unrelated keys intact', () async {
    await file.writeAsString(jsonEncode({'other': 42}));
    await store.saveComicScrub(
      const ComicScrubSettings(pageSeconds: 6, pageSkip: 12),
    );

    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(raw['other'], 42);
    expect(raw['comicScrub'], {'pageSeconds': 6, 'pageSkip': 12});
  });

  test('comicPages missing -> empty map', () async {
    expect(await store.loadComicPages(), isEmpty);
  });

  test('comicPages save then load round-trips', () async {
    final pages = {r'C:\comics\a.cbz': 'page-003.jpg', r'C:\b.cbz': '01.png'};
    await store.saveComicPages(pages);
    expect(await store.loadComicPages(), pages);
  });

  test('comicPages corrupt file -> empty map', () async {
    await file.writeAsString('{ nope');
    expect(await store.loadComicPages(), isEmpty);
  });

  test('saveComicPages leaves unrelated keys intact', () async {
    await file.writeAsString(jsonEncode({'other': 42}));
    await store.saveComicPages({r'C:\a.cbz': 'p1.png'});

    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(raw['other'], 42);
    expect(raw['comicPages'], {r'C:\a.cbz': 'p1.png'});
  });
}
