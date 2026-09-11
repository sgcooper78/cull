import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewer/selection_controller.dart';
import 'browse_controller.dart';
import 'recent_folders.dart';

/// Opens [path] as the tree root: clears the current file selection and
/// records it in Recent Folders. Shared by the folder picker, the empty-state
/// "Open Folder" button, and clicking a recent folder.
void openRootFolder(WidgetRef ref, String path) {
  ref.read(selectionProvider.notifier).clear();
  ref.read(browseProvider.notifier).openRoot(path);
  ref.read(recentFoldersProvider.notifier).record(path);
}

/// Shows the native folder picker and opens whatever the user chooses.
Future<void> pickAndOpenDirectory(WidgetRef ref) async {
  final dir = await getDirectoryPath();
  if (dir == null) return;
  openRootFolder(ref, dir);
}
