import 'package:cull/data/settings/settings_store.dart';
import 'package:cull/features/viewer/comic_resume.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_settings_store.dart';

void main() {
  late InMemorySettingsStore settings;

  setUp(() {
    settings = InMemorySettingsStore();
  });

  Future<WidgetRef> harness(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWith((ref) async => settings),
      ],
    );
    addTearDown(container.dispose);

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

  testWidgets('rememberComicPage then lastComicPage round-trips', (
    tester,
  ) async {
    final ref = await harness(tester);

    await rememberComicPage(ref, r'C:\comics\a.cbz', 'page-005.jpg');

    expect(await lastComicPage(ref, r'C:\comics\a.cbz'), 'page-005.jpg');
  });

  testWidgets('lastComicPage is null when nothing was remembered', (
    tester,
  ) async {
    final ref = await harness(tester);

    expect(await lastComicPage(ref, r'C:\comics\never-opened.cbz'), isNull);
  });

  testWidgets('remembering a later page for the same comic overwrites it', (
    tester,
  ) async {
    final ref = await harness(tester);

    await rememberComicPage(ref, r'C:\comics\a.cbz', 'page-001.jpg');
    await rememberComicPage(ref, r'C:\comics\a.cbz', 'page-009.jpg');

    expect(await lastComicPage(ref, r'C:\comics\a.cbz'), 'page-009.jpg');
    expect(settings.comicPages.length, 1);
  });

  testWidgets('oldest entry is dropped once past the 200-comic cap', (
    tester,
  ) async {
    final ref = await harness(tester);

    for (var i = 0; i < 200; i++) {
      await rememberComicPage(ref, 'C:\\comics\\$i.cbz', 'page-000.jpg');
    }
    expect(settings.comicPages.length, 200);
    expect(await lastComicPage(ref, r'C:\comics\0.cbz'), 'page-000.jpg');

    // One more pushes the map past the cap; the oldest (comic 0) is dropped.
    await rememberComicPage(ref, r'C:\comics\200.cbz', 'page-000.jpg');

    expect(settings.comicPages.length, 200);
    expect(await lastComicPage(ref, r'C:\comics\0.cbz'), isNull);
    expect(await lastComicPage(ref, r'C:\comics\200.cbz'), 'page-000.jpg');
  });
}
