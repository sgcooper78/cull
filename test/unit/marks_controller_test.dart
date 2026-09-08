import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_mark_store.dart';

void main() {
  late FakeFileSource fs;
  late InMemoryMarkStore markStore;

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [
        fileSourceProvider.overrideWithValue(fs),
        markStoreProvider.overrideWith((ref) async => markStore),
      ],
    );
    addTearDown(container.dispose);
    await container.read(marksControllerProvider.future);
    return container;
  }

  setUp(() {
    markStore = InMemoryMarkStore();
    fs = FakeFileSource()
      ..addDir(r'C:\root')
      ..addDir(r'C:\root\sub')
      ..addFile(r'C:\root\a.txt')
      ..addFile(r'C:\root\sub\b.mp4')
      ..addFile(r'C:\root\sub\c.mp4');
  });

  test('setMark and toggle change a single path', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    expect(ctrl.markFor(r'C:\root\a.txt'), Mark.safe);

    await ctrl.setMark(r'C:\root\a.txt', Mark.delete);
    expect(ctrl.markFor(r'C:\root\a.txt'), Mark.delete);

    await ctrl.toggle(r'C:\root\a.txt');
    expect(ctrl.markFor(r'C:\root\a.txt'), Mark.safe);
  });

  test('markAllUnder recurses into files and subfolders', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    await ctrl.markAllUnder(r'C:\root', Mark.delete);

    expect(ctrl.deletePaths..sort(), [
      r'C:\root\a.txt',
      r'C:\root\sub',
      r'C:\root\sub\b.mp4',
      r'C:\root\sub\c.mp4',
    ]);

    await ctrl.markAllUnder(r'C:\root', Mark.safe);
    expect(ctrl.deletePaths, isEmpty);
  });

  test('markAllUnder(includeRoot: true) marks the folder itself too', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    await ctrl.markAllUnder(r'C:\root\sub', Mark.delete, includeRoot: true);

    expect(ctrl.deletePaths..sort(), [
      r'C:\root\sub',
      r'C:\root\sub\b.mp4',
      r'C:\root\sub\c.mp4',
    ]);
  });

  test(
    'commitDeletions deletes marked roots and subsumes descendants',
    () async {
      final c = await makeContainer();
      final ctrl = c.read(marksControllerProvider.notifier);

      await ctrl.setMark(r'C:\root\a.txt', Mark.delete);
      await ctrl.setMark(r'C:\root\sub', Mark.delete);
      await ctrl.setMark(r'C:\root\sub\b.mp4', Mark.delete);

      final result = await ctrl.commitDeletions();

      expect(result.deleted, 2);
      expect(result.hasFailures, isFalse);
      expect(fs.deleteCalls, [r'C:\root\a.txt', r'C:\root\sub']);
      expect(ctrl.deletePaths, isEmpty);
    },
  );

  test('commitDeletions reports a locked file and keeps its mark', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);
    fs.failDeletesFor.add(r'C:\root\sub\b.mp4');

    await ctrl.setMark(r'C:\root\a.txt', Mark.delete);
    await ctrl.setMark(r'C:\root\sub\b.mp4', Mark.delete);

    final result = await ctrl.commitDeletions();

    expect(result.deleted, 1);
    expect(result.failures.single.$1, r'C:\root\sub\b.mp4');
    expect(ctrl.deletePaths, [r'C:\root\sub\b.mp4']);
  });

  test('commitDeletions counts an already-gone path as success', () async {
    final c = await makeContainer();
    final ctrl = c.read(marksControllerProvider.notifier);

    await ctrl.setMark(r'C:\root\a.txt', Mark.delete);
    await ctrl.setMark(r'C:\root\ghost.txt', Mark.delete); // never existed

    final result = await ctrl.commitDeletions();

    expect(result.deleted, 2);
    expect(result.hasFailures, isFalse);
    expect(ctrl.deletePaths, isEmpty);
  });

  test('marks persist across a fresh controller', () async {
    final c1 = await makeContainer();
    await c1
        .read(marksControllerProvider.notifier)
        .setMark(r'C:\root\a.txt', Mark.delete);

    final c2 = await makeContainer();
    expect(
      c2.read(marksControllerProvider.notifier).markFor(r'C:\root\a.txt'),
      Mark.delete,
    );
  });
}
