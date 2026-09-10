import 'dart:typed_data';

import 'archive_entry.dart';
import 'archive_result.dart';

/// Reads the contents of an on-disk archive without extracting it to disk.
///
/// Every method takes the plain on-disk path of the archive (`C:\dl\a.7z`),
/// never an [archivePathSeparator] path. Implementations must not throw across
/// this boundary — failures come back as [ArchiveFailure].
abstract interface class ArchiveReader {
  /// Whether this reader recognises [archivePath] by extension. A `true` here
  /// does not guarantee [list] will succeed (the file may be corrupt).
  bool canRead(String archivePath);

  /// Flat listing of every entry in the archive, directories included, in the
  /// archive's own order. Sorting/tree-building is the caller's job.
  Future<ArchiveResult<List<ArchiveEntry>>> list(String archivePath);

  /// Uncompressed bytes of a single entry. [entryPath] is the `/`-separated
  /// internal path exactly as it appears in [ArchiveEntry.path].
  Future<ArchiveResult<Uint8List>> readEntry(
    String archivePath,
    String entryPath,
  );
}

/// Progress tick from [ArchiveWriter.rewriteWithout].
class RewriteProgress {
  const RewriteProgress({
    required this.entriesDone,
    required this.entriesTotal,
    required this.bytesDone,
    required this.bytesTotal,
  });

  final int entriesDone;
  final int entriesTotal;
  final int bytesDone;
  final int bytesTotal;

  double get fraction => bytesTotal == 0 ? 1 : bytesDone / bytesTotal;
}

/// Rebuilds an archive in place, minus a set of entries. Used by the
/// mark-inside-an-archive delete flow: on commit, each affected archive is
/// rewritten once to a sibling temp file, then swapped over the original.
abstract interface class ArchiveWriter {
  /// Whether the format at [archivePath] can be re-encoded. `false` for RAR and
  /// other read-only formats — callers must disable the mark control for
  /// entries inside those.
  bool canWrite(String archivePath);

  /// Rewrite [archivePath], dropping every entry whose path is in [remove]
  /// (directory paths in [remove] drop their whole subtree). The original is
  /// left untouched on any failure. [onProgress] is called on the calling
  /// isolate as work streams through.
  Future<ArchiveResult<void>> rewriteWithout(
    String archivePath,
    Set<String> remove, {
    void Function(RewriteProgress)? onProgress,
  });
}
