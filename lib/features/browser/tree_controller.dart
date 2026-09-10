import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/fs/fs_entry.dart';
import 'archive_tree.dart';
import 'browse_controller.dart';
import 'sort_controller.dart';

part 'tree_controller.g.dart';

/// Absolute paths of the directories currently expanded in the tree. Also holds
/// expanded archive files and archive-member directories, whose paths carry the
/// `!/` separator.
@Riverpod(keepAlive: true)
class TreeExpansion extends _$TreeExpansion {
  @override
  Set<String> build() => const {};

  bool isExpanded(String path) => state.contains(path);

  void toggle(String path) {
    state = state.contains(path)
        ? (state.toSet()..remove(path))
        : {...state, path};
  }

  void expand(String path) => state = {...state, path};
  void collapseAll() => state = const {};
}

/// One rendered line of the tree.
sealed class TreeRow {
  const TreeRow(this.depth);
  final int depth;
}

/// A file or directory entry.
class EntryRow extends TreeRow {
  const EntryRow(super.depth, this.entry, {this.expanded = false});
  final FsEntry entry;
  final bool expanded;
}

/// Shown under a directory whose listing hasn't arrived yet.
class LoadingRow extends TreeRow {
  const LoadingRow(super.depth);
}

/// Shown under a directory that couldn't be read.
class ErrorRow extends TreeRow {
  const ErrorRow(super.depth, this.message);
  final String message;
}

/// The visible tree, flattened depth-first for a `ListView.builder`. Rebuilds
/// when the root, the expansion set, or any expanded folder's listing changes.
///
/// An expanded archive file (or a folder inside one) draws its children from
/// [archiveChildrenProvider] instead of [directoryListingProvider]; everything
/// downstream keeps working because the children are [FsEntry]s with `!/`
/// paths.
@riverpod
List<TreeRow> treeRows(Ref ref) {
  final root = ref.watch(browseProvider);
  if (root == null) return const [];
  final expanded = ref.watch(treeExpansionProvider);
  final sort = ref.watch(sortSettingsControllerProvider);

  final rows = <TreeRow>[];

  void addChildren(String container, int depth, {required bool archived}) {
    final listing = archived
        ? ref.watch(archiveChildrenProvider(container))
        : ref.watch(directoryListingProvider(container));
    switch (listing) {
      case AsyncData(:final value):
        final entries = [...value]..sort(sort.compare);
        for (final entry in entries) {
          final entering = !archived && isBrowsableArchive(entry);
          final canExpand = entry.isDirectory || entering;
          final isOpen = canExpand && expanded.contains(entry.path);
          rows.add(EntryRow(depth, entry, expanded: isOpen));
          if (isOpen) {
            addChildren(entry.path, depth + 1, archived: archived || entering);
          }
        }
      case AsyncError(:final error):
        rows.add(ErrorRow(depth, '$error'));
      case _:
        rows.add(LoadingRow(depth));
    }
  }

  addChildren(root, 0, archived: false);
  return rows;
}
