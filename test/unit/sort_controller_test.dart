import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/data/settings/sort_settings.dart';
import 'package:cull/features/browser/sort_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_settings_store.dart';

void main() {
  ProviderContainer containerWith(InMemorySettingsStore store) {
    final c = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWith((ref) async => store)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('starts at defaults', () async {
    final c = containerWith(InMemorySettingsStore());
    expect(c.read(sortSettingsControllerProvider), SortSettings.defaults);
  });

  test(
    'sortBy a new key resets to ascending; same key flips direction',
    () async {
      final c = containerWith(InMemorySettingsStore());
      final ctrl = c.read(sortSettingsControllerProvider.notifier);

      await ctrl.sortBy(SortKey.size);
      expect(c.read(sortSettingsControllerProvider).key, SortKey.size);
      expect(c.read(sortSettingsControllerProvider).ascending, isTrue);

      await ctrl.sortBy(SortKey.size); // same key again
      expect(c.read(sortSettingsControllerProvider).ascending, isFalse);
    },
  );

  test('reverse and foldersFirst, and they persist', () async {
    final store = InMemorySettingsStore();
    final c = containerWith(store);
    final ctrl = c.read(sortSettingsControllerProvider.notifier);

    await ctrl.reverse();
    await ctrl.setFoldersFirst(false);

    final saved = await store.loadSort();
    expect(saved?.ascending, isFalse);
    expect(saved?.foldersFirst, isFalse);
  });

  test('hydrates from a pre-populated store', () async {
    final store = InMemorySettingsStore(
      sort: const SortSettings(
        key: SortKey.modified,
        ascending: false,
        foldersFirst: false,
      ),
    );
    final c = containerWith(store);

    c.read(sortSettingsControllerProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(sortSettingsControllerProvider),
      const SortSettings(
        key: SortKey.modified,
        ascending: false,
        foldersFirst: false,
      ),
    );
  });
}
