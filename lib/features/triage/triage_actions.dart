import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fs/fs_entry.dart';
import '../../data/marks/mark.dart';
import '../../data/marks/marks_controller.dart';
import '../browser/tree_controller.dart';
import '../viewer/selection_controller.dart';
import '../viewer/viewer_key_handler.dart';

/// The files visible in the tree right now (folders excluded), top to bottom.
/// This is the sequence the `D`/`S`/`Enter` triage keys step through — expand
/// the folders you care about and they walk exactly those files, across
/// folders.
List<FsEntry> visibleFiles(WidgetRef ref) => [
  for (final row in ref.read(treeRowsProvider))
    if (row is EntryRow && !row.entry.isDirectory) row.entry,
];

/// Every visible tree row — files *and* directories, top to bottom. This is
/// what the Up/Down arrows walk (Enter still steps files only).
List<FsEntry> visibleEntries(WidgetRef ref) => [
  for (final row in ref.read(treeRowsProvider))
    if (row is EntryRow) row.entry,
];

/// Select the next file after the current selection. With nothing selected,
/// selects the first file. Returns false if there is no next file.
bool advanceSelection(WidgetRef ref) {
  final files = visibleFiles(ref);
  if (files.isEmpty) return false;
  final current = ref.read(selectionProvider);
  final index = current == null
      ? -1
      : files.indexWhere((e) => e.path == current.path);
  final next = index + 1;
  if (next >= files.length) return false;
  ref.read(selectionProvider.notifier).select(files[next]);
  return true;
}

/// Move the selection by [delta] rows through [visibleEntries] (Up/Down arrows).
/// Clamps at the ends — returns false if it could not move.
bool moveSelection(WidgetRef ref, int delta) {
  final entries = visibleEntries(ref);
  if (entries.isEmpty) return false;
  final current = ref.read(selectionProvider);
  final index = current == null
      ? -1
      : entries.indexWhere((e) => e.path == current.path);
  final next = index < 0 ? (delta > 0 ? 0 : entries.length - 1) : index + delta;
  if (next < 0 || next >= entries.length) return false;
  ref.read(selectionProvider.notifier).select(entries[next]);
  return true;
}

/// Left/Right (and PageUp/PageDown). If a viewer has registered a step handler
/// (comic pager, video seek…), drive it. Otherwise, if a directory row is
/// selected, expand/collapse it. Returns false if nothing consumed the key.
bool stepViewer(WidgetRef ref, {required bool forward}) {
  final handler = ref.read(viewerKeyHandlersProvider).step;
  if (handler != null) {
    handler(forward: forward);
    return true;
  }
  final selection = ref.read(selectionProvider);
  if (selection != null && selection.isDirectory) {
    ref.read(treeExpansionProvider.notifier).toggle(selection.path);
    return true;
  }
  return false;
}

/// Home/End — jump to the far end of whatever the viewer is showing.
bool jumpViewer(WidgetRef ref, {required bool toEnd}) {
  final handler = ref.read(viewerKeyHandlersProvider).jump;
  if (handler == null) return false;
  handler(toEnd: toEnd);
  return true;
}

/// Mark the file open in the viewer, then advance to the next one.
Future<void> markCurrentAndAdvance(WidgetRef ref, Mark mark) async {
  final current = ref.read(selectionProvider);
  if (current == null) return;
  await ref.read(marksControllerProvider.notifier).setMark(current.path, mark);
  advanceSelection(ref);
}
