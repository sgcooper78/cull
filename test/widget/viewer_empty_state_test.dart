import 'package:cull/data/fs/fs_providers.dart';
import 'package:cull/data/marks/marks_controller.dart';
import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/features/browser/browse_controller.dart';
import 'package:cull/features/viewer/viewer_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_file_source.dart';
import '../support/in_memory_mark_store.dart';
import '../support/in_memory_settings_store.dart';
import '../support/paths.dart';

void main() {
  testWidgets(
    'empty state offers Open Folder and a recent folder that opens on tap',
    (tester) async {
      final fs = FakeFileSource()..addDir(tp('root'));
      final settings = InMemorySettingsStore()..recentFolders = [tp('root')];

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

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ViewerPanel())),
        ),
      );
      await tester.pump(); // recentFoldersProvider hydrates
      await tester.pump();

      expect(find.text('Open Folder'), findsOneWidget);
      expect(find.text('root'), findsOneWidget); // recent tile title
      expect(find.text(tp('root')), findsOneWidget); // recent tile subtitle

      await tester.tap(find.text(tp('root')));
      await tester.pump();

      expect(container.read(browseProvider), tp('root'));
    },
  );

  testWidgets('no root and no recents shows just the Open Folder prompt', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        markStoreProvider.overrideWith((ref) async => InMemoryMarkStore()),
        settingsStoreProvider.overrideWith(
          (ref) async => InMemorySettingsStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ViewerPanel())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Open Folder'), findsOneWidget);
    expect(find.text('RECENT'), findsNothing);
  });
}
