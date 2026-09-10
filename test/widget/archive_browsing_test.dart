import 'package:cull/data/archives/archive_providers.dart';
import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:cull/features/browser/browse_controller.dart';
import 'package:cull/features/browser/tree_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_archive.dart';
import '../support/in_memory_mark_store.dart';
import '../support/paths.dart';

void main() {
  late FakeFileSource fs;
  late FakeArchiveStore archives;

  final zipPath = tp('root/photos.zip');

  setUp(() {
    fs = FakeFileSource()
      ..addDir(tp('root'))
      ..addFile(tp('root/readme.txt'))
      ..addFile(zipPath);
    archives = FakeArchiveStore()
      ..add(zipPath, 'top.txt', [1, 2, 3])
      ..add(zipPath, 'a/one.jpg', [4, 5])
      ..add(zipPath, 'a/two.jpg', [6, 7, 8]);
  });

  Future<ProviderContainer> boot(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        fileSourceProvider.overrideWithValue(fs),
        markStoreProvider.overrideWith((ref) async => InMemoryMarkStore()),
        archiveReaderProvider.overrideWithValue(
          InMemoryArchiveReader(archives),
        ),
        directoryListingProvider.overrideWith(
          (ref, dirPath) => Stream.fromFuture(fs.list(dirPath)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(marksControllerProvider.future);
    container.read(browseProvider.notifier).openRoot(tp('root'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) {
              ref.watch(treeRowsProvider);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return container;
  }

  List<String> rowPaths(ProviderContainer c) => [
    for (final r in c.read(treeRowsProvider))
      if (r is EntryRow) r.entry.path,
  ];

  testWidgets('a browsable archive is a collapsed, expandable row', (
    tester,
  ) async {
    final c = await boot(tester);
    expect(rowPaths(c), contains(zipPath));
    // Not expanded → no members yet.
    expect(rowPaths(c).where((p) => p.contains('!/')), isEmpty);
  });

  testWidgets('expanding the archive lists its top-level entries', (
    tester,
  ) async {
    final c = await boot(tester);
    c.read(treeExpansionProvider.notifier).toggle(zipPath);
    await tester.pump();
    await tester.pump();

    expect(rowPaths(c), contains('$zipPath!/a'));
    expect(rowPaths(c), contains('$zipPath!/top.txt'));
    // 'a' is a directory row; its children aren't shown until it too is open.
    expect(rowPaths(c), isNot(contains('$zipPath!/a/one.jpg')));
  });

  testWidgets('expanding a folder inside the archive lists its files', (
    tester,
  ) async {
    final c = await boot(tester);
    c.read(treeExpansionProvider.notifier)
      ..toggle(zipPath)
      ..toggle('$zipPath!/a');
    await tester.pump();
    await tester.pump();

    expect(rowPaths(c), contains('$zipPath!/a/one.jpg'));
    expect(rowPaths(c), contains('$zipPath!/a/two.jpg'));
  });

  testWidgets('marking a file inside the archive marks just that entry', (
    tester,
  ) async {
    final c = await boot(tester);
    final marks = c.read(marksControllerProvider.notifier);

    await marks.setMark('$zipPath!/a/one.jpg', Mark.delete);
    expect(marks.deletePaths, ['$zipPath!/a/one.jpg']);
  });

  testWidgets('markAllUnder on an archive folder walks the archive listing', (
    tester,
  ) async {
    final c = await boot(tester);
    final marks = c.read(marksControllerProvider.notifier);

    await marks.markAllUnder('$zipPath!/a', Mark.delete, includeRoot: true);

    expect(marks.deletePaths..sort(), [
      '$zipPath!/a',
      '$zipPath!/a/one.jpg',
      '$zipPath!/a/two.jpg',
    ]);
  });
}
