import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/archives/archive_entry.dart';
import '../../data/fs/file_source.dart';
import '../../data/fs/fs_entry.dart';
import '../../data/fs/fs_providers.dart';
import '../../data/settings/settings_store.dart';
import '../viewer/selection_controller.dart';
import 'tree_controller.dart';

/// How many roots to keep resume positions for. Oldest-written entries are
/// dropped past this — a plain LRU would need timestamps we don't store, so
/// this is just a size guard on `settings.json`.
const _maxRoots = 60;

/// Record [filePath] as the spot to resume [root] at next time it's opened.
/// No-ops for directories and archive-member paths.
Future<void> rememberResume(WidgetRef ref, String root, String filePath) async {
  if (isArchiveMemberPath(filePath)) return;
  final store = await ref.read(settingsStoreProvider.future);
  final map = Map<String, String>.from(await store.loadResume());
  if (map[root] == filePath) return;
  map.remove(root); // re-insert at the end so trimming drops stale roots first
  map[root] = filePath;
  while (map.length > _maxRoots) {
    map.remove(map.keys.first);
  }
  await store.saveResume(map);
}

/// If [root] has a saved resume file that still exists, expand the tree down to
/// it and select it so the viewer opens on that file.
Future<void> restoreResume(WidgetRef ref, String root) async {
  final store = await ref.read(settingsStoreProvider.future);
  final saved = (await store.loadResume())[root];
  if (saved == null || isArchiveMemberPath(saved)) return;
  if (!p.isWithin(root, saved)) return;

  final FsEntry entry;
  try {
    entry = await ref.read(fileSourceProvider).stat(saved);
  } on FileSourceException {
    return; // the file moved or was deleted since last session
  }
  if (entry.isDirectory) return;

  final expansion = ref.read(treeExpansionProvider.notifier);
  var dir = p.dirname(saved);
  final ancestors = <String>[];
  while (p.isWithin(root, dir)) {
    ancestors.add(dir);
    dir = p.dirname(dir);
  }
  for (final a in ancestors.reversed) {
    expansion.expand(a);
  }
  ref.read(selectionProvider.notifier).select(entry);
}
