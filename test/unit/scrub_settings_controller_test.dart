import 'package:cull/data/settings/scrub_settings.dart';
import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/features/viewer/scrub_mode_controller.dart';
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

  test('starts at defaults, then persists edits', () async {
    final store = InMemorySettingsStore();
    final c = containerWith(store);

    expect(
      c.read(mediaScrubSettingsControllerProvider),
      MediaScrubSettings.defaults,
    );

    await c
        .read(mediaScrubSettingsControllerProvider.notifier)
        .setSkipPercent(25);

    expect(c.read(mediaScrubSettingsControllerProvider).skipPercent, 25);
    expect((await store.loadScrub())?.skipPercent, 25);
  });

  test('edits are clamped', () async {
    final c = containerWith(InMemorySettingsStore());
    await c
        .read(mediaScrubSettingsControllerProvider.notifier)
        .setPlaySeconds(999);
    expect(c.read(mediaScrubSettingsControllerProvider).playSeconds, 30);
  });

  test('hydrates from a pre-populated store', () async {
    final store = InMemorySettingsStore(
      scrub: const MediaScrubSettings(playSeconds: 9, skipPercent: 30),
    );
    final c = containerWith(store);

    c.read(mediaScrubSettingsControllerProvider); // trigger build + _hydrate
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(mediaScrubSettingsControllerProvider),
      const MediaScrubSettings(playSeconds: 9, skipPercent: 30),
    );
  });

  test('reset restores defaults after edits', () async {
    final c = containerWith(InMemorySettingsStore());
    await c
        .read(mediaScrubSettingsControllerProvider.notifier)
        .setPlaySeconds(20);
    await c.read(mediaScrubSettingsControllerProvider.notifier).reset();

    expect(
      c.read(mediaScrubSettingsControllerProvider),
      MediaScrubSettings.defaults,
    );
  });

  group('ComicScrubSettingsController', () {
    test('starts at defaults, then persists edits', () async {
      final store = InMemorySettingsStore();
      final c = containerWith(store);

      expect(
        c.read(comicScrubSettingsControllerProvider),
        ComicScrubSettings.defaults,
      );

      await c
          .read(comicScrubSettingsControllerProvider.notifier)
          .setPageSkip(12);

      expect(c.read(comicScrubSettingsControllerProvider).pageSkip, 12);
      expect((await store.loadComicScrub())?.pageSkip, 12);
    });

    test('setPageSeconds edits are clamped', () async {
      final c = containerWith(InMemorySettingsStore());
      await c
          .read(comicScrubSettingsControllerProvider.notifier)
          .setPageSeconds(999);
      expect(c.read(comicScrubSettingsControllerProvider).pageSeconds, 30);
    });

    test('setPageSkip edits are clamped', () async {
      final c = containerWith(InMemorySettingsStore());
      await c
          .read(comicScrubSettingsControllerProvider.notifier)
          .setPageSkip(0);
      expect(c.read(comicScrubSettingsControllerProvider).pageSkip, 1);
    });

    test('reset restores defaults after edits', () async {
      final c = containerWith(InMemorySettingsStore());
      await c
          .read(comicScrubSettingsControllerProvider.notifier)
          .setPageSeconds(25);
      await c.read(comicScrubSettingsControllerProvider.notifier).reset();

      expect(
        c.read(comicScrubSettingsControllerProvider),
        ComicScrubSettings.defaults,
      );
    });

    test('hydrates from a pre-populated store', () async {
      final store = InMemorySettingsStore(
        comicScrub: const ComicScrubSettings(pageSeconds: 8, pageSkip: 20),
      );
      final c = containerWith(store);

      c.read(
        comicScrubSettingsControllerProvider,
      ); // trigger build + _hydrate
      await Future<void>.delayed(Duration.zero);

      expect(
        c.read(comicScrubSettingsControllerProvider),
        const ComicScrubSettings(pageSeconds: 8, pageSkip: 20),
      );
    });
  });
}
