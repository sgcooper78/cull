import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/archives/archive_entry.dart';
import '../../data/marks/marks_controller.dart';

/// Show the confirm dialog for committing deletions, run it, and report the
/// outcome. No-op (with a SnackBar) when nothing is marked.
Future<void> runDeleteMarked(BuildContext context, WidgetRef ref) async {
  final marks = ref.read(marksControllerProvider.notifier);
  final paths = marks.deletePaths..sort();
  final messenger = ScaffoldMessenger.of(context);

  if (paths.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nothing is marked for deletion.')),
    );
    return;
  }

  final archiveCount = paths
      .where(isArchiveMemberPath)
      .map(rootArchiveOf)
      .toSet()
      .length;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Delete ${paths.length} marked item'
        '${paths.length == 1 ? '' : 's'}?',
      ),
      content: SizedBox(
        width: 520,
        height: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently removes them from disk. Folders are '
              'deleted with everything inside them.',
            ),
            if (archiveCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$archiveCount archive${archiveCount == 1 ? '' : 's'} will be '
                'rebuilt without the marked entries — compression settings and '
                'metadata may change.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: paths.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      paths[i],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete permanently'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final result = await marks.commitDeletions();

  final summary = StringBuffer(
    'Deleted ${result.deleted} item'
    '${result.deleted == 1 ? '' : 's'}.',
  );
  if (result.hasFailures) {
    summary.write(' ${result.failures.length} could not be removed.');
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(summary.toString()),
      duration: const Duration(seconds: 4),
    ),
  );
}
