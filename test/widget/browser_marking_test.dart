import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:cull/features/browser/browse_controller.dart';
import 'package:cull/features/browser/browser_panel.dart';
import 'package:cull/features/browser/widgets/tree_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_mark_store.dart';

void main() {
  late FakeFileSource fs;

  setUp(() {
    fs = FakeFileSource()
      ..addDir(r'C:\root')
      ..addDir(r'C:\root\sub')
      ..addFile(r'C:\root\sub\c.txt')
      ..addFile(r'C:\root\a.txt')
      ..addFile(r'C:\root\b.txt');
  });

  Future<ProviderContainer> pumpPanel(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        fileSourceProvider.overrideWithValue(fs),
        markStoreProvider.overrideWith((ref) async => InMemoryMarkStore()),
        // Per-folder listing without the real DirectoryWatcher.
        directoryListingProvider.overrideWith(
          (ref, dirPath) => Stream.fromFuture(fs.list(dirPath)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(marksControllerProvider.future);
    container.read(browseProvider.notifier).openRoot(r'C:\root');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 360, child: BrowserPanel())),
        ),
      ),
    );
    await tester.pump(); // stream emits
    await tester.pump();
    return container;
  }

  Finder tileFor(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(TreeTile));

  testWidgets('tree shows the root folder, subfolders collapsed', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(find.text('sub'), findsOneWidget);
    expect(find.text('a.txt'), findsOneWidget);
    expect(find.text('b.txt'), findsOneWidget);
    expect(find.text('c.txt'), findsNothing); // sub not expanded
  });

  testWidgets('tapping a folder row expands it', (tester) async {
    await pumpPanel(tester);
    await tester.tap(tileFor('sub'));
    await tester.pump();
    await tester.pump();
    expect(find.text('c.txt'), findsOneWidget);
  });

  testWidgets('toggling a file marks just that file', (tester) async {
    final container = await pumpPanel(tester);

    await tester.tap(
      find.descendant(of: tileFor('a.txt'), matching: find.byType(IconButton)),
    );
    await tester.pump();

    final ctrl = container.read(marksControllerProvider.notifier);
    expect(ctrl.markFor(r'C:\root\a.txt'), Mark.delete);
    expect(ctrl.markFor(r'C:\root\b.txt'), Mark.safe);
  });

  testWidgets('toggling a folder marks it and everything inside', (
    tester,
  ) async {
    final container = await pumpPanel(tester);

    await tester.tap(
      find.descendant(of: tileFor('sub'), matching: find.byType(IconButton)),
    );
    await tester.pump();
    await tester.pump();

    final ctrl = container.read(marksControllerProvider.notifier);
    expect(ctrl.deletePaths..sort(), [r'C:\root\sub', r'C:\root\sub\c.txt']);
  });

  testWidgets('"All delete" marks the whole tree', (tester) async {
    final container = await pumpPanel(tester);

    await tester.tap(find.text('All delete'));
    await tester.pump();
    await tester.pump();

    final ctrl = container.read(marksControllerProvider.notifier);
    expect(ctrl.deletePaths..sort(), [
      r'C:\root\a.txt',
      r'C:\root\b.txt',
      r'C:\root\sub',
      r'C:\root\sub\c.txt',
    ]);
  });
}
