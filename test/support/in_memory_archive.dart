import 'dart:typed_data';

import 'package:cull/data/archives/archive_entry.dart';
import 'package:cull/data/archives/archive_reader.dart';
import 'package:cull/data/archives/archive_result.dart';

/// Shared in-memory archive contents for [InMemoryArchiveReader] /
/// [InMemoryArchiveWriter] — no disk, no isolates, safe inside `testWidgets`.
///
/// Build one per archive path:
/// ```dart
/// final store = FakeArchiveStore()
///   ..add(tp('root/a.zip'), 'photos/one.jpg', bytes)
///   ..add(tp('root/a.zip'), 'photos/two.jpg', bytes);
/// ```
class FakeArchiveStore {
  /// archivePath -> (entryPath -> bytes). Directories are implied.
  final Map<String, Map<String, Uint8List>> _archives = {};

  /// Formats to pretend we cannot rewrite (e.g. a `.rar` under test).
  final Set<String> readOnly = {};

  /// Archive paths whose next [InMemoryArchiveWriter.rewriteWithout] should
  /// fail, simulating a locked file / disk error.
  final Set<String> failRewriteFor = {};

  void add(String archivePath, String entryPath, List<int> bytes) {
    _archives.putIfAbsent(archivePath, () => {})[entryPath] =
        Uint8List.fromList(bytes);
  }

  bool has(String archivePath) => _archives.containsKey(archivePath);

  Map<String, Uint8List>? entriesOf(String archivePath) =>
      _archives[archivePath];
}

class InMemoryArchiveReader implements ArchiveReader {
  InMemoryArchiveReader(this.store);
  final FakeArchiveStore store;

  @override
  bool canRead(String archivePath) => store.has(archivePath);

  @override
  Future<ArchiveResult<List<ArchiveEntry>>> list(String archivePath) async {
    final files = store.entriesOf(archivePath);
    if (files == null) {
      return const ArchiveFailure(ArchiveErrorKind.notFound);
    }
    final entries = <String, ArchiveEntry>{};
    for (final e in files.entries) {
      entries[e.key] = ArchiveEntry(
        path: e.key,
        isDir: false,
        size: e.value.length,
      );
      var parent = entries[e.key]!.parent;
      while (parent.isNotEmpty && !entries.containsKey(parent)) {
        entries[parent] = ArchiveEntry(path: parent, isDir: true, size: 0);
        parent = entries[parent]!.parent;
      }
    }
    return ArchiveOk(entries.values.toList());
  }

  @override
  Future<ArchiveResult<Uint8List>> readEntry(
    String archivePath,
    String entryPath,
  ) async {
    final bytes = store.entriesOf(archivePath)?[entryPath];
    if (bytes == null) {
      return const ArchiveFailure(ArchiveErrorKind.entryNotFound);
    }
    return ArchiveOk(bytes);
  }
}

class InMemoryArchiveWriter implements ArchiveWriter {
  InMemoryArchiveWriter(this.store);
  final FakeArchiveStore store;

  @override
  bool canWrite(String archivePath) =>
      store.has(archivePath) && !store.readOnly.contains(archivePath);

  @override
  Future<ArchiveResult<void>> rewriteWithout(
    String archivePath,
    Set<String> remove, {
    void Function(RewriteProgress)? onProgress,
  }) async {
    if (!canWrite(archivePath)) {
      return const ArchiveFailure(ArchiveErrorKind.notWritable);
    }
    if (store.failRewriteFor.contains(archivePath)) {
      return const ArchiveFailure(ArchiveErrorKind.io);
    }
    final files = store.entriesOf(archivePath)!;
    files.removeWhere(
      (path, _) =>
          remove.contains(path) || remove.any((r) => path.startsWith('$r/')),
    );
    onProgress?.call(
      const RewriteProgress(
        entriesDone: 1,
        entriesTotal: 1,
        bytesDone: 1,
        bytesTotal: 1,
      ),
    );
    return const ArchiveOk(null);
  }
}
