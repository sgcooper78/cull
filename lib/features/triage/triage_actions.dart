import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fs/fs_entry.dart';
import '../../data/marks/mark.dart';
import '../../data/marks/marks_controller.dart';
import '../browser/tree_controller.dart';
import '../viewer/selection_controller.dart';

/// The files visible in the tree right now (folders excluded), top to bottom.
/// This is the sequence the triage keys step through — expand the folders you
/// care about and `D`/`S`/`Enter` walk exactly those files, across folders.
List<FsEntry> visibleFiles(WidgetRef ref) => [
  for (final row in ref.read(treeRowsProvider))
    if (row is EntryRow && !row.entry.isDirectory) row.entry,
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

/// Mark the file open in the viewer, then advance to the next one.
Future<void> markCurrentAndAdvance(WidgetRef ref, Mark mark) async {
  final current = ref.read(selectionProvider);
  if (current == null) return;
  await ref.read(marksControllerProvider.notifier).setMark(current.path, mark);
  advanceSelection(ref);
}
