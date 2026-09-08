import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/mark.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:cull/features/browser/browse_controller.dart';
import 'package:cull/features/browser/tree_controller.dart';
import 'package:cull/features/triage/triage_actions.dart';
import 'package:cull/features/viewer/selection_controller.dart';
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
      ..addFile(r'C:\root\sub\z.txt')
      ..addFile(r'C:\root\a.txt')
      ..addFile(r'C:\root\b.txt')
      ..addFile(r'C:\root\c.txt');
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
    container.read(browseProvider.notifier).openRoot(r'C:\root');

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
    expect(marks.markFor(r'C:\root\a.txt'), Mark.delete);
    expect(container.read(selectionProvider)?.name, 'b.txt');
  });

  testWidgets('expanding a folder puts its files into the walk order', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);
    container.read(treeExpansionProvider.notifier).expand(r'C:\root\sub');
    await tester.pump();
    await tester.pump();

    // sub's z.txt sorts before a.txt in the flattened tree (folder first).
    expect(advanceSelection(ref), isTrue);
    await tester.pump();
    expect(container.read(selectionProvider)?.path, r'C:\root\sub\z.txt');
  });

  testWidgets('advance past the last visible file does nothing', (
    tester,
  ) async {
    final (container, ref) = await harness(tester);
    container
        .read(selectionProvider.notifier)
        .select(
          (await fs.list(r'C:\root')).firstWhere((e) => e.name == 'c.txt'),
        );

    expect(advanceSelection(ref), isFalse);
    await tester.pump();
    expect(container.read(selectionProvider)?.name, 'c.txt');
  });
}
