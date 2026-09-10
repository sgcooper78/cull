import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'archive_entry.dart';
import 'archive_reader.dart';
import 'archive_result.dart';
import 'composite_archive.dart';

part 'archive_providers.g.dart';

/// The active [ArchiveReader]. Tests override with an in-memory fake.
@Riverpod(keepAlive: true)
ArchiveReader archiveReader(Ref ref) => CompositeArchiveReader();

/// The active [ArchiveWriter] for repackage-on-delete.
@Riverpod(keepAlive: true)
ArchiveWriter archiveWriter(Ref ref) => CompositeArchiveWriter();

/// Thrown (as an [AsyncError]) when an archive can't be listed, so a tree row
/// shows the reason rather than a bare exception.
class ArchiveListingException implements Exception {
  ArchiveListingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Flat entry list of an on-disk archive. Cached; invalidate after a
/// repackage so the tree re-reads the shrunken archive.
@riverpod
Future<List<ArchiveEntry>> archiveEntries(Ref ref, String archivePath) async {
  final result = await ref.watch(archiveReaderProvider).list(archivePath);
  return switch (result) {
    ArchiveOk(:final value) => value,
    ArchiveFailure(:final message) => throw ArchiveListingException(message),
  };
}
