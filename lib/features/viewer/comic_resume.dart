import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings/settings_store.dart';

/// How many comics to keep a remembered page for. Oldest-written entries are
/// dropped past this — a plain LRU would need timestamps we don't store, so
/// this is just a size guard on `settings.json` (same approach as
/// `rememberResume` in `features/browser/resume.dart`).
const _maxComics = 200;

/// Record [pageName] as the page to resume [comicPath] at next time it's
/// opened.
Future<void> rememberComicPage(
  WidgetRef ref,
  String comicPath,
  String pageName,
) async {
  final store = await ref.read(settingsStoreProvider.future);
  final map = Map<String, String>.from(await store.loadComicPages());
  if (map[comicPath] == pageName) return;
  map.remove(comicPath); // re-insert at the end so trimming drops stale first
  map[comicPath] = pageName;
  while (map.length > _maxComics) {
    map.remove(map.keys.first);
  }
  await store.saveComicPages(map);
}

/// The last page viewed in [comicPath], if any was remembered.
Future<String?> lastComicPage(WidgetRef ref, String comicPath) async {
  final store = await ref.read(settingsStoreProvider.future);
  return (await store.loadComicPages())[comicPath];
}
