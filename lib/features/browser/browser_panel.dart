import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/formatting.dart';
import '../../data/marks/mark.dart';
import '../../data/marks/marks_controller.dart';
import '../triage/delete_marked.dart';
import '../triage/deletion_stats.dart';
import 'browse_controller.dart';
import 'tree_controller.dart';
import 'widgets/sort_menu.dart';
import 'widgets/tree_tile.dart';

/// The left sidebar: root path bar, bulk-mark actions, and the directory tree.
class BrowserPanel extends ConsumerWidget {
  const BrowserPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = ref.watch(browseProvider);
    if (root == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No directory open.\nFile ▸ Open Directory…',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final rows = ref.watch(treeRowsProvider);

    return Column(
      children: [
        _RootBar(root: root),
        _BulkBar(root: root),
        const _MarkedSummary(),
        const Divider(height: 1),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  primary: true,
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final row = rows[i];
                    return switch (row) {
                      EntryRow() => TreeTile(row),
                      LoadingRow() => TreeStatusTile(depth: row.depth),
                      ErrorRow() => TreeStatusTile(
                        depth: row.depth,
                        error: row.message,
                      ),
                    };
                  },
                ),
        ),
      ],
    );
  }
}

class _RootBar extends ConsumerWidget {
  const _RootBar({required this.root});

  final String root;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: root,
              child: Text(
                p.basename(root).isEmpty ? root : p.basename(root),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SortMenu(),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            tooltip: 'Collapse all',
            onPressed: () =>
                ref.read(treeExpansionProvider.notifier).collapseAll(),
          ),
        ],
      ),
    );
  }
}

/// Live "what a delete would remove" line. Hidden when nothing is marked;
/// tapping it opens the confirm dialog.
class _MarkedSummary extends ConsumerWidget {
  const _MarkedSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats =
        ref.watch(deletionStatsControllerProvider).asData?.value ??
        DeletionStats.empty;
    if (stats.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final parts = <String>[
      if (stats.fileCount > 0)
        '${stats.fileCount} file${stats.fileCount == 1 ? '' : 's'}',
      if (stats.folderCount > 0)
        '${stats.folderCount} folder${stats.folderCount == 1 ? '' : 's'}',
      if (stats.archiveEntryCount > 0) '${stats.archiveEntryCount} in archives',
    ];
    final freed = stats.bytes > 0
        ? ' · ${formatBytes(stats.bytes)} to free'
        : '';

    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.45),
      child: InkWell(
        onTap: () => runDeleteMarked(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.delete_sweep, size: 16, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${parts.join(' · ')} marked$freed',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkBar extends ConsumerWidget {
  const _BulkBar({required this.root});

  final String root;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> markAll(Mark mark) =>
        ref.read(marksControllerProvider.notifier).markAllUnder(root, mark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.cancel, color: Colors.red.shade600, size: 18),
              label: const Text('All delete'),
              onPressed: () => markAll(Mark.delete),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 18,
              ),
              label: const Text('All safe'),
              onPressed: () => markAll(Mark.safe),
            ),
          ),
        ],
      ),
    );
  }
}
