import 'dart:io';

import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/mark_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late JsonFileMarkStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cull_marks_test');
    store = JsonFileMarkStore(File(p.join(tmp.path, 'marks.json')));
  });

  tearDown(() => tmp.delete(recursive: true));

  test('missing file loads as empty', () async {
    expect(await store.load(), isEmpty);
  });

  test('round-trips delete marks, omitting safe ones', () async {
    await store.save({
      r'C:\a\keep.mp4': Mark.safe,
      r'C:\a\junk.mp4': Mark.delete,
    });

    final loaded = await store.load();
    expect(loaded, {r'C:\a\junk.mp4': Mark.delete});
    expect(loaded.containsKey(r'C:\a\keep.mp4'), isFalse);
  });

  test('corrupt file loads as empty rather than throwing', () async {
    await File(p.join(tmp.path, 'marks.json')).writeAsString('{not json');
    expect(await store.load(), isEmpty);
  });
}
