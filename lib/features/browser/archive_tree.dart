import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/archives/archive_entry.dart';
import '../../data/archives/archive_format.dart';
import '../../data/archives/archive_providers.dart';
import '../../data/fs/fs_entry.dart';

part 'archive_tree.g.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// True for an on-disk archive the tree can expand inline (pure-Dart formats
/// only for now — 7z/RAR need the native backend and are left as leaves).
bool isBrowsableArchive(FsEntry entry) {
  if (entry.isDirectory) return false;
  final format = archiveFormatOf(entry.name);
  return format != null && !format.needsNativeBackend;
}

/// Direct children of a tree container that lives inside an archive.
/// [containerPath] is either the on-disk archive path (`C:\d\a.zip`) or an
/// archive-member directory (`C:\d\a.zip!/photos`). Children come back as
/// [FsEntry] with [archivePathSeparator] paths so the rest of the tree, the
/// selection, and the mark store treat them like any other row.
@riverpod
Future<List<FsEntry>> archiveChildren(Ref ref, String containerPath) async {
  final root = rootArchiveOf(containerPath);
  final (_, prefix) = splitArchivePath(containerPath);
  // Nested archives aren't expanded yet.
  if (prefix.contains(archivePathSeparator)) return const [];

  final entries = await ref.watch(archiveEntriesProvider(root).future);
  final out = <FsEntry>[];
  for (final e in entries) {
    if (e.path == prefix || e.parent != prefix) continue;
    out.add(
      FsEntry(
        path: joinArchivePath(root, e.path),
        isDirectory: e.isDir,
        size: e.size,
        modified: e.modified ?? _epoch,
        accessed: e.modified ?? _epoch,
        changed: e.modified ?? _epoch,
      ),
    );
  }
  return out;
}
