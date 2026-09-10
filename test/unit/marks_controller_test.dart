import 'package:cull/data/archives/archive_providers.dart';
import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_archive.dart';
import '../support/in_memory_mark_store.dart';
import '../support/paths.dart';

void main() {
  late FakeFileSource fs;
  late InMemoryMarkStore markStore;
  late FakeArchiveStore archives;

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [
        fileSourceProvider.overrideWithValue(fs),
        markStoreProvider.overrideWith((ref) async => markStore),
        archiveReaderProvider.overrideWithValue(
          InMemoryArchiveReader(archives),
        ),
        archiveWriterProvider.overrideWithValue(
          InMemoryArchiveWriter(archives),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(marksControllerProvider.future);
    return container;
  }

  setUp(() {
    markStore = InMemoryMarkStore();
    archives = FakeArchiveStore();
    fs = FakeFileSource()
      ..addDir(tp('root'))
      ..addDir(tp('root/sub'))
      ..addFile(tp('root/a.txt'))
      ..addFile(tp('root/sub/b.mp4'))
      ..addFile(tp('root/sub/c.mp4'));
  });

  test('setMark and toggle change a single path', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    expect(ctrl.markFor(tp('root/a.txt')), Mark.safe);

    await ctrl.setMark(tp('root/a.txt'), Mark.delete);
    expect(ctrl.markFor(tp('root/a.txt')), Mark.delete);

    await ctrl.toggle(tp('root/a.txt'));
    expect(ctrl.markFor(tp('root/a.txt')), Mark.safe);
  });

  test('markAllUnder recurses into files and subfolders', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    await ctrl.markAllUnder(tp('root'), Mark.delete);

    expect(ctrl.deletePaths..sort(), [
      tp('root/a.txt'),
      tp('root/sub'),
      tp('root/sub/b.mp4'),
      tp('root/sub/c.mp4'),
    ]);

    await ctrl.markAllUnder(tp('root'), Mark.safe);
    expect(ctrl.deletePaths, isEmpty);
  });

  test('markAllUnder(includeRoot: true) marks the folder itself too', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    await ctrl.markAllUnder(tp('root/sub'), Mark.delete, includeRoot: true);

    expect(ctrl.deletePaths..sort(), [
      tp('root/sub'),
      tp('root/sub/b.mp4'),
      tp('root/sub/c.mp4'),
    ]);
  });

  test(
    'commitDeletions deletes marked roots and subsumes descendants',
    () async {
      final c = await makeContainer();
      final ctrl = c.read(marksControllerProvider.notifier);

      await ctrl.setMark(tp('root/a.txt'), Mark.delete);
      await ctrl.setMark(tp('root/sub'), Mark.delete);
      await ctrl.setMark(tp('root/sub/b.mp4'), Mark.delete);

      final result = await ctrl.commitDeletions();

      expect(result.deleted, 2);
      expect(result.hasFailures, isFalse);
      expect(fs.deleteCalls, [tp('root/a.txt'), tp('root/sub')]);
      expect(ctrl.deletePaths, isEmpty);
    },
  );

  test('commitDeletions reports a locked file and keeps its mark', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);
    fs.failDeletesFor.add(tp('root/sub/b.mp4'));

    await ctrl.setMark(tp('root/a.txt'), Mark.delete);
    await ctrl.setMark(tp('root/sub/b.mp4'), Mark.delete);

    final result = await ctrl.commitDeletions();

    expect(result.deleted, 1);
    expect(result.failures.single.$1, tp('root/sub/b.mp4'));
    expect(ctrl.deletePaths, [tp('root/sub/b.mp4')]);
  });

  test('commitDeletions counts an already-gone path as success', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    await ctrl.setMark(tp('root/a.txt'), Mark.delete);
    await ctrl.setMark(tp('root/ghost.txt'), Mark.delete); // never existed

    final result = await ctrl.commitDeletions();

    expect(result.deleted, 2);
    expect(result.hasFailures, isFalse);
    expect(ctrl.deletePaths, isEmpty);
  });

  group('archive members', () {
    final zip = tp('root/pics.zip');

    setUp(() {
      fs.addFile(zip);
      archives
        ..add(zip, 'keep.jpg', [1])
        ..add(zip, 'a/one.jpg', [2])
        ..add(zip, 'a/two.jpg', [3]);
    });

    test('markAllUnder an archive folder marks its members', () async {
      final c = await makeContainer();
      final ctrl = c.read(marksControllerProvider.notifier);

      await ctrl.markAllUnder('$zip!/a', Mark.delete, includeRoot: true);

      expect(ctrl.deletePaths..sort(), [
        '$zip!/a',
        '$zip!/a/one.jpg',
        '$zip!/a/two.jpg',
      ]);
    });

    test(
      'commitDeletions repackages the archive without marked entries',
      () async {
        final c = await makeContainer();
        final ctrl = c.read(marksControllerProvider.notifier);

        await ctrl.setMark('$zip!/a/one.jpg', Mark.delete);
        await ctrl.setMark('$zip!/a/two.jpg', Mark.delete);

        final result = await ctrl.commitDeletions();

        expect(result.deleted, 2);
        expect(result.hasFailures, isFalse);
        expect(archives.entriesOf(zip)!.keys.toSet(), {'keep.jpg'});
        expect(ctrl.deletePaths, isEmpty);
        expect(fs.deleteCalls, isEmpty); // the .zip file itself stays
      },
    );

    test('deleting the archive file subsumes its marked members', () async {
      final c = await makeContainer();
      final ctrl = c.read(marksControllerProvider.notifier);

      await ctrl.setMark('$zip!/a/one.jpg', Mark.delete);
      await ctrl.setMark(zip, Mark.delete);

      final result = await ctrl.commitDeletions();

      expect(result.hasFailures, isFalse);
      expect(fs.deleteCalls, [zip]);
      expect(ctrl.deletePaths, isEmpty);
      // rewrite was skipped — the store still has every entry
      expect(archives.entriesOf(zip)!.length, 3);
    });

    test('a failed repackage keeps the member marks and reports it', () async {
      final c = await makeContainer();
      final ctrl = c.read(marksControllerProvider.notifier);
      archives.failRewriteFor.add(zip);

      await ctrl.setMark('$zip!/a/one.jpg', Mark.delete);
      final result = await ctrl.commitDeletions();

      expect(result.deleted, 0);
      expect(result.failures.single.$1, zip);
      expect(ctrl.deletePaths, ['$zip!/a/one.jpg']);
      expect(archives.entriesOf(zip)!.length, 3);
    });
  });

  test('marks persist across a fresh controller', () async {
    final c1 = await makeContainer();
    await c1
        .read(marksControllerProvider.notifier)
        .setMark(tp('root/a.txt'), Mark.delete);

    final c2 = await makeContainer();
    expect(
      c2.read(marksControllerProvider.notifier).markFor(tp('root/a.txt')),
      Mark.delete,
    );
  });
}
