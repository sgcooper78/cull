import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/features/browser/recent_folders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_settings_store.dart';
import '../support/paths.dart';

void main() {
  ProviderContainer containerWith(InMemorySettingsStore store) {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWith((ref) async => store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('starts empty', () {
    final c = containerWith(InMemorySettingsStore());
    expect(c.read(recentFoldersProvider), isEmpty);
  });

  test('record adds to the front and persists', () async {
    final store = InMemorySettingsStore();
    final c = containerWith(store);
    final ctrl = c.read(recentFoldersProvider.notifier);

    await ctrl.record(tp('a'));
    await ctrl.record(tp('b'));

    expect(c.read(recentFoldersProvider), [tp('b'), tp('a')]);
    expect(await store.loadRecentFolders(), [tp('b'), tp('a')]);
  });

  test('re-recording an existing folder moves it to the front', () async {
    final c = containerWith(InMemorySettingsStore());
    final ctrl = c.read(recentFoldersProvider.notifier);

    await ctrl.record(tp('a'));
    await ctrl.record(tp('b'));
    await ctrl.record(tp('a'));

    expect(c.read(recentFoldersProvider), [tp('a'), tp('b')]);
  });

  test('caps at maxRecentFolders', () async {
    final c = containerWith(InMemorySettingsStore());
    final ctrl = c.read(recentFoldersProvider.notifier);

    for (var i = 0; i < maxRecentFolders + 3; i++) {
      await ctrl.record(tp('folder$i'));
    }

    expect(c.read(recentFoldersProvider), hasLength(maxRecentFolders));
    // Most recent survive; oldest are dropped.
    expect(
      c.read(recentFoldersProvider).first,
      tp('folder${maxRecentFolders + 2}'),
    );
  });

  test('remove drops a folder and persists', () async {
    final store = InMemorySettingsStore();
    final c = containerWith(store);
    final ctrl = c.read(recentFoldersProvider.notifier);

    await ctrl.record(tp('a'));
    await ctrl.record(tp('b'));
    await ctrl.remove(tp('a'));

    expect(c.read(recentFoldersProvider), [tp('b')]);
    expect(await store.loadRecentFolders(), [tp('b')]);
  });

  test('hydrates from a pre-populated store', () async {
    final store = InMemorySettingsStore()
      ..recentFolders = [tp('old'), tp('older')];
    final c = containerWith(store);

    c.read(recentFoldersProvider);
    await Future<void>.delayed(Duration.zero);

    expect(c.read(recentFoldersProvider), [tp('old'), tp('older')]);
  });
}
