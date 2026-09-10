import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:cull/features/triage/deletion_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_mark_store.dart';
import '../support/paths.dart';

void main() {
  late FakeFileSource fs;

  Future<ProviderContainer> container() async {
    final c = ProviderContainer(
      overrides: [
        fileSourceProvider.overrideWithValue(fs),
        markStoreProvider.overrideWith((ref) async => InMemoryMarkStore()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(marksControllerProvider.future);
    return c;
  }

  setUp(() {
    fs = FakeFileSource()
      ..addDir(tp('root'))
      ..addDir(tp('root/sub'))
      ..addFile(tp('root/a.txt'), size: 100)
      ..addFile(tp('root/b.mp4'), size: 500)
      ..addFile(tp('root/sub/c.mp4'), size: 50);
  });

  test('sums marked file sizes and counts folders separately', () async {
    final c = await container();
    final marks = c.read(marksControllerProvider.notifier);

    await marks.setMark(tp('root/a.txt'), Mark.delete);
    await marks.markAllUnder(tp('root/sub'), Mark.delete, includeRoot: true);

    final stats = await c.read(deletionStatsControllerProvider.future);
    expect(stats.fileCount, 2); // a.txt + sub/c.mp4
    expect(stats.folderCount, 1); // sub
    expect(stats.bytes, 150); // 100 + 50
    expect(stats.archiveEntryCount, 0);
  });

  test('archive members are counted but contribute no bytes', () async {
    final c = await container();
    final marks = c.read(marksControllerProvider.notifier);

    await marks.setMark(tp('root/a.txt'), Mark.delete);
    await marks.setMark('${tp('root/pics.zip')}!/x.jpg', Mark.delete);

    final stats = await c.read(deletionStatsControllerProvider.future);
    expect(stats.fileCount, 1);
    expect(stats.archiveEntryCount, 1);
    expect(stats.bytes, 100);
  });

  test('a mark on a vanished path is ignored', () async {
    final c = await container();
    await c
        .read(marksControllerProvider.notifier)
        .setMark(tp('root/ghost.txt'), Mark.delete);

    final stats = await c.read(deletionStatsControllerProvider.future);
    expect(stats.isEmpty, isTrue);
  });

  test('recomputes when a mark is cleared', () async {
    final c = await container();
    final marks = c.read(marksControllerProvider.notifier);
    await marks.setMark(tp('root/b.mp4'), Mark.delete);

    expect((await c.read(deletionStatsControllerProvider.future)).bytes, 500);

    await marks.setMark(tp('root/b.mp4'), Mark.safe);
    expect(
      (await c.read(deletionStatsControllerProvider.future)).isEmpty,
      isTrue,
    );
  });
}
