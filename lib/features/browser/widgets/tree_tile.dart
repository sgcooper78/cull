import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting.dart';
import '../../../data/marks/mark.dart';
import '../../../data/marks/marks_controller.dart';
import '../../viewer/selection_controller.dart';
import '../archive_tree.dart';
import '../tree_controller.dart';
import 'entry_icon.dart';
import 'mark_button.dart';

/// One row of the directory tree. Tapping a folder — or a browsable archive —
/// expands/collapses it; tapping a file opens it in the viewer. The mark toggle
/// sets that entry, and for a folder (on disk or inside an archive) everything
/// under it.
class TreeTile extends ConsumerWidget {
  const TreeTile(this.row, {super.key});

  final EntryRow row;

  static const _indent = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = row.entry;
    final isDir = entry.isDirectory;
    final canExpand = isDir || isBrowsableArchive(entry);

    final mark = ref.watch(
      marksControllerProvider.select(
        (v) => (v.asData?.value ?? const {})[entry.path] ?? Mark.safe,
      ),
    );
    final selected = ref.watch(
      selectionProvider.select((e) => e?.path == entry.path),
    );
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        if (canExpand) {
          ref.read(treeExpansionProvider.notifier).toggle(entry.path);
        } else {
          ref.read(selectionProvider.notifier).select(entry);
        }
      },
      child: Container(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
        padding: EdgeInsets.only(left: 8 + row.depth * _indent, right: 4),
        height: 34,
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: canExpand
                  ? Icon(
                      row.expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 18,
                    )
                  : null,
            ),
            EntryIcon(entry),
            const SizedBox(width: 6),
            Expanded(child: Text(entry.name, overflow: TextOverflow.ellipsis)),
            if (!isDir) ...[
              Text(
                formatBytes(entry.size),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(width: 4),
            ],
            MarkButton(
              mark: mark,
              onChanged: (m) {
                final marks = ref.read(marksControllerProvider.notifier);
                if (isDir) {
                  marks.markAllUnder(entry.path, m, includeRoot: true);
                } else {
                  marks.setMark(entry.path, m);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The loading spinner / error text shown beneath a not-yet-ready folder.
class TreeStatusTile extends StatelessWidget {
  const TreeStatusTile({required this.depth, this.error, super.key});

  final int depth;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 26 + depth * 16.0, top: 6, bottom: 6),
      child: error == null
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
