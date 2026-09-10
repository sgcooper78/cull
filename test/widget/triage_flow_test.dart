import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:cull/features/browser/browse_controller.dart';
import 'package:cull/features/browser/tree_controller.dart';
import 'package:cull/features/triage/triage_actions.dart';
import 'package:cull/features/viewer/selection_controller.dart';
import 'package:cull/features/viewer/viewer_key_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_mark_store.dart';
import '../support/paths.dart';

void main() {
  late FakeFileSource fs;

  setUp(() {
    fs = FakeFileSource()
      ..addDir(tp('root'))
      ..addDir(tp('root/sub'))
      ..addFile(tp('root/sub/z.txt'))
      ..addFile(tp('root/a.txt'))
      ..addFile(tp('root/b.txt'))
      ..addFile(tp('root/c.txt'));
  });

  Future<(ProviderContainer, WidgetRef)> harness(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        fileSourceProvider.overrideWithValue(fs),
        markStoreProvider.overrideWith((ref) async => InMemoryMarkStore()),
        directoryListingProvider.overrideWith(
          (ref, dirPath) => Stream.fromFuture(fs.list(dirPath)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(marksControllerProvider.future);
    container.read(browseProvider.notifier).openRoot(tp('root'));

    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (_, r, _) {
              ref = r;
              r.watch(treeRowsProvider); // keep it resolved
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return (container, ref);
  }

  testWidgets('advance with nothing selected picks the first visible file', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);
    expect(advanceSelection(ref), isTrue);
    await tester.pump();
    expect(container.read(selectionProvider)?.name, 'a.txt'); // folder skipped
  });

  testWidgets('D marks the viewed file and steps to the next', (tester) async {
    final (container, ref) = await harness(tester);
    advanceSelection(ref); // -> a.txt
    await tester.pump();

    await markCurrentAndAdvance(ref, Mark.delete);
    await tester.pump();

    final marks = container.read(marksControllerProvider.notifier);
    expect(marks.markFor(tp('root/a.txt')), Mark.delete);
    expect(container.read(selectionProvider)?.name, 'b.txt');
  });

  testWidgets('expanding a folder puts its files into the walk order', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);
    container.read(treeExpansionProvider.notifier).expand(tp('root/sub'));
    await tester.pump();
    await tester.pump();

    // sub's z.txt sorts before a.txt in the flattened tree (folder first).
    expect(advanceSelection(ref), isTrue);
    await tester.pump();
    expect(container.read(selectionProvider)?.path, tp('root/sub/z.txt'));
  });

  testWidgets('advance past the last visible file does nothing', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);
    container
        .read(selectionProvider.notifier)
        .select(
          (await fs.list(tp('root'))).firstWhere((e) => e.name == 'c.txt'),
        );

    expect(advanceSelection(ref), isFalse);
    await tester.pump();
    expect(container.read(selectionProvider)?.name, 'c.txt');
  });

  testWidgets('moveSelection walks folders too, unlike advanceSelection', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);

    expect(moveSelection(ref, 1), isTrue);
    await tester.pump();
    // The folder row comes first in the flattened tree.
    expect(container.read(selectionProvider)?.path, tp('root/sub'));
    expect(container.read(selectionProvider)?.isDirectory, isTrue);

    expect(moveSelection(ref, 1), isTrue);
    await tester.pump();
    expect(container.read(selectionProvider)?.name, 'a.txt');

    expect(moveSelection(ref, -1), isTrue);
    await tester.pump();
    expect(container.read(selectionProvider)?.path, tp('root/sub'));
  });

  testWidgets(
    'moveSelection with nothing selected: Down picks first, Up last',
    (tester) async {
      final (container, ref) = await harness(tester);

      expect(moveSelection(ref, -1), isTrue);
      await tester.pump();
      expect(container.read(selectionProvider)?.name, 'c.txt'); // last row

      container.read(selectionProvider.notifier).clear();
      expect(moveSelection(ref, 1), isTrue);
      await tester.pump();
      expect(
        container.read(selectionProvider)?.path,
        tp('root/sub'),
      ); // first row
    },
  );

  testWidgets('moveSelection clamps past the last row', (tester) async {
    final (container, ref) = await harness(tester);
    container
        .read(selectionProvider.notifier)
        .select(
          (await fs.list(tp('root'))).firstWhere((e) => e.name == 'c.txt'),
        );
    expect(moveSelection(ref, 1), isFalse);
    await tester.pump();
    expect(container.read(selectionProvider)?.name, 'c.txt');
  });

  testWidgets('stepViewer expands/collapses a selected folder', (tester) async {
    final (container, ref) = await harness(tester);
    container
        .read(selectionProvider.notifier)
        .select((await fs.list(tp('root'))).firstWhere((e) => e.isDirectory));

    expect(stepViewer(ref, forward: true), isTrue);
    await tester.pump();
    expect(
      container.read(treeExpansionProvider).contains(tp('root/sub')),
      isTrue,
    );

    expect(stepViewer(ref, forward: false), isTrue);
    await tester.pump();
    expect(
      container.read(treeExpansionProvider).contains(tp('root/sub')),
      isFalse,
    );
  });

  testWidgets('stepViewer defers to a registered viewer handler', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);
    final steps = <bool>[];
    container
        .read(viewerKeyHandlersProvider.notifier)
        .register(step: ({required bool forward}) => steps.add(forward));

    // A folder is selected, but the viewer handler wins over expand/collapse.
    container
        .read(selectionProvider.notifier)
        .select((await fs.list(tp('root'))).firstWhere((e) => e.isDirectory));

    expect(stepViewer(ref, forward: true), isTrue);
    expect(stepViewer(ref, forward: false), isTrue);
    expect(steps, [true, false]);
    expect(
      container.read(treeExpansionProvider).contains(tp('root/sub')),
      isFalse,
    );
  });

  testWidgets('jumpViewer only fires when a handler is registered', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);
    expect(jumpViewer(ref, toEnd: true), isFalse);

    final jumps = <bool>[];
    container
        .read(viewerKeyHandlersProvider.notifier)
        .register(jump: ({required bool toEnd}) => jumps.add(toEnd));
    expect(jumpViewer(ref, toEnd: true), isTrue);
    expect(jumps, [true]);
  });
}
