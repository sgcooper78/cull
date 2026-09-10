import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/features/browser/browse_controller.dart';
import 'package:cull/features/browser/resume.dart';
import 'package:cull/features/browser/tree_controller.dart';
import 'package:cull/features/viewer/selection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_mark_store.dart';
import '../support/in_memory_settings_store.dart';
import '../support/paths.dart';

void main() {
  late FakeFileSource fs;
  late InMemorySettingsStore settings;

  setUp(() {
    settings = InMemorySettingsStore();
    fs = FakeFileSource()
      ..addDir(tp('root'))
      ..addDir(tp('root/sub'))
      ..addFile(tp('root/a.txt'))
      ..addFile(tp('root/sub/deep.txt'));
  });

  Future<WidgetRef> harness(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        fileSourceProvider.overrideWithValue(fs),
        markStoreProvider.overrideWith((ref) async => InMemoryMarkStore()),
        settingsStoreProvider.overrideWith((ref) async => settings),
        directoryListingProvider.overrideWith(
          (ref, dirPath) => Stream.fromFuture(fs.list(dirPath)),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(browseProvider.notifier).openRoot(tp('root'));

    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (_, r, _) {
              ref = r;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return ref;
  }

  testWidgets('rememberResume persists per root', (tester) async {
    final ref = await harness(tester);

    await rememberResume(ref, tp('root'), tp('root/sub/deep.txt'));
    expect(settings.resume[tp('root')], tp('root/sub/deep.txt'));

    // Archive-member paths are not recorded.
    await rememberResume(ref, tp('root'), '${tp('root/x.zip')}!/inside.txt');
    expect(settings.resume[tp('root')], tp('root/sub/deep.txt'));
  });

  testWidgets('restoreResume expands to the saved file and selects it', (
    tester,
  ) async {
    final ref = await harness(tester);
    settings.resume[tp('root')] = tp('root/sub/deep.txt');

    await restoreResume(ref, tp('root'));
    await tester.pump();

    expect(ref.read(selectionProvider)?.path, tp('root/sub/deep.txt'));
    expect(ref.read(treeExpansionProvider).contains(tp('root/sub')), isTrue);
  });

  testWidgets('restoreResume is a no-op when the saved file is gone', (
    tester,
  ) async {
    final ref = await harness(tester);
    settings.resume[tp('root')] = tp('root/deleted-since.txt');

    await restoreResume(ref, tp('root'));
    await tester.pump();

    expect(ref.read(selectionProvider), isNull);
  });
}
