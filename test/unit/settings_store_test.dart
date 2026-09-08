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
    const s = ScrubSettings(playSeconds: 7, skipPercent: 20);
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
    await store.saveScrub(const ScrubSettings(playSeconds: 3, skipPercent: 10));
    await store.saveSort(SortSettings.defaults);

    expect((await store.loadScrub())?.playSeconds, 3);
    expect(await store.loadSort(), SortSettings.defaults);
  });

  test('saveScrub leaves unrelated keys intact', () async {
    await file.writeAsString(jsonEncode({'other': 42}));
    await store.saveScrub(const ScrubSettings(playSeconds: 3, skipPercent: 10));

    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(raw['other'], 42);
    expect(raw['scrub'], {'playSeconds': 3, 'skipPercent': 10});
  });
}
