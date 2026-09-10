import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/archives/archive_entry.dart';
import '../../data/fs/file_source.dart';
import '../../data/fs/fs_providers.dart';
import '../../data/marks/mark.dart';
import '../../data/marks/marks_controller.dart';

part 'deletion_stats.g.dart';

/// Running tally of what a "Delete marked" would remove. Powers the sidebar
/// indicator and the confirm dialog. Sizes for entries inside archives are not
/// counted — repackaging frees only the compressed portion, which we can't
/// know cheaply — but they are counted in [archiveEntryCount].
class DeletionStats {
  const DeletionStats({
    required this.fileCount,
    required this.folderCount,
    required this.archiveEntryCount,
    required this.bytes,
  });

  final int fileCount;
  final int folderCount;
  final int archiveEntryCount;

  /// Sum of marked *file* sizes on disk (folders contribute via their
  /// individually-marked children).
  final int bytes;

  int get itemCount => fileCount + folderCount + archiveEntryCount;
  bool get isEmpty => itemCount == 0;

  static const empty = DeletionStats(
    fileCount: 0,
    folderCount: 0,
    archiveEntryCount: 0,
    bytes: 0,
  );
}

/// Recomputes whenever the marks change. A per-path metadata cache keeps the
/// cost to one `stat` per file for its lifetime, so repeated re-marking stays
/// cheap.
@Riverpod(keepAlive: true)
class DeletionStatsController extends _$DeletionStatsController {
  final Map<String, ({bool isDir, int size})> _meta = {};

  @override
  Future<DeletionStats> build() async {
    final marks = await ref.watch(marksControllerProvider.future);
    final fs = ref.read(fileSourceProvider);

    var files = 0, folders = 0, archiveEntries = 0, bytes = 0;
    for (final entry in marks.entries) {
      if (entry.value != Mark.delete) continue;
      final path = entry.key;
      if (isArchiveMemberPath(path)) {
        archiveEntries++;
        continue;
      }
      var meta = _meta[path];
      if (meta == null) {
        try {
          final stat = await fs.stat(path);
          meta = (isDir: stat.isDirectory, size: stat.size);
        } on FileSourceException {
          continue; // already gone — don't count it
        }
        _meta[path] = meta;
      }
      if (meta.isDir) {
        folders++;
      } else {
        files++;
        bytes += meta.size;
      }
    }
    return DeletionStats(
      fileCount: files,
      folderCount: folders,
      archiveEntryCount: archiveEntries,
      bytes: bytes,
    );
  }
}
