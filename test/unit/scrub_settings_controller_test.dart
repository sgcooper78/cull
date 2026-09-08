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

    expect(c.read(scrubSettingsControllerProvider), ScrubSettings.defaults);

    await c.read(scrubSettingsControllerProvider.notifier).setSkipPercent(25);

    expect(c.read(scrubSettingsControllerProvider).skipPercent, 25);
    expect((await store.loadScrub())?.skipPercent, 25);
  });

  test('edits are clamped', () async {
    final c = containerWith(InMemorySettingsStore());
    await c.read(scrubSettingsControllerProvider.notifier).setPlaySeconds(999);
    expect(c.read(scrubSettingsControllerProvider).playSeconds, 30);
  });

  test('hydrates from a pre-populated store', () async {
    final store = InMemorySettingsStore(
      scrub: const ScrubSettings(playSeconds: 9, skipPercent: 30),
    );
    final c = containerWith(store);

    c.read(scrubSettingsControllerProvider); // trigger build + _hydrate
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(scrubSettingsControllerProvider),
      const ScrubSettings(playSeconds: 9, skipPercent: 30),
    );
  });
}
