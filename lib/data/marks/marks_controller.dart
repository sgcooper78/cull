import 'dart:developer' as developer;

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../archives/archive_entry.dart';
import '../archives/archive_providers.dart';
import '../archives/archive_result.dart';
import '../fs/file_source.dart';
import '../fs/fs_entry.dart';
import '../fs/fs_providers.dart';
import 'mark.dart';
import 'mark_store.dart';

part 'marks_controller.g.dart';

/// Overridable so tests can inject an in-memory store.
@Riverpod(keepAlive: true)
Future<MarkStore> markStore(Ref ref) => MarkStore.open();

/// Outcome of [MarksController.commitDeletions].
class DeletionResult {
  const DeletionResult({required this.deleted, required this.failures});

  final int deleted;

  /// `(path, message)` for each item that could not be removed.
  final List<(String, String)> failures;

  bool get hasFailures => failures.isNotEmpty;
}

/// Source of truth for triage marks. `safe` is implicit (absent from the map).
@Riverpod(keepAlive: true)
class MarksController extends _$MarksController {
  @override
  Future<Map<String, Mark>> build() async {
    final store = await ref.watch(markStoreProvider.future);
    return store.load();
  }

  Map<String, Mark> get _current => state.asData?.value ?? const {};

  Future<void> _commit(Map<String, Mark> next) async {
    state = AsyncData(next);
    try {
      final store = await ref.read(markStoreProvider.future);
      await store.save(next);
    } catch (e, st) {
      developer.log('Failed to persist marks', error: e, stackTrace: st);
    }
  }

  Mark markFor(String path) => _current[path] ?? Mark.safe;

  Future<void> setMark(String path, Mark mark) async {
    final next = Map<String, Mark>.from(_current);
    if (mark == Mark.safe) {
      next.remove(path);
    } else {
      next[path] = mark;
    }
    await _commit(next);
  }

  Future<void> toggle(String path) => setMark(path, markFor(path).toggled());

  /// Recursively set [mark] on every file and subdirectory under [dirPath].
  /// With [includeRoot], [dirPath] itself is marked too (used by the tree's
  /// folder toggle — mark a folder, mark everything in it).
  Future<void> markAllUnder(
    String dirPath,
    Mark mark, {
    bool includeRoot = false,
  }) async {
    if (isArchiveMemberPath(dirPath)) {
      return _markArchiveSubtree(dirPath, mark, includeRoot: includeRoot);
    }
    final fs = ref.read(fileSourceProvider);
    final paths = includeRoot ? <String>[dirPath] : <String>[];
    final stack = <String>[dirPath];
    while (stack.isNotEmpty) {
      final dir = stack.removeLast();
      final List<FsEntry> entries;
      try {
        entries = await fs.list(dir);
      } on FileSourceException {
        continue;
      }
      for (final e in entries) {
        paths.add(e.path);
        if (e.isDirectory) stack.add(e.path);
      }
    }
    final next = Map<String, Mark>.from(_current);
    for (final path in paths) {
      if (mark == Mark.safe) {
        next.remove(path);
      } else {
        next[path] = mark;
      }
    }
    await _commit(next);
  }

  /// Marks every entry under an archive-member directory (a `!/` path). The
  /// listing comes from the archive itself, not the filesystem.
  Future<void> _markArchiveSubtree(
    String containerPath,
    Mark mark, {
    required bool includeRoot,
  }) async {
    final root = rootArchiveOf(containerPath);
    final (_, prefix) = splitArchivePath(containerPath);
    final result = await ref.read(archiveReaderProvider).list(root);
    final entries = result.valueOrNull ?? const <ArchiveEntry>[];

    final paths = <String>[if (includeRoot) containerPath];
    for (final e in entries) {
      if (e.path == prefix) continue;
      if (e.path.startsWith('$prefix/')) {
        paths.add(joinArchivePath(root, e.path));
      }
    }

    final next = Map<String, Mark>.from(_current);
    for (final path in paths) {
      if (mark == Mark.safe) {
        next.remove(path);
      } else {
        next[path] = mark;
      }
    }
    await _commit(next);
  }

  /// Paths currently marked [Mark.delete].
  List<String> get deletePaths => [
    for (final e in _current.entries)
      if (e.value == Mark.delete) e.key,
  ];

  /// Permanently apply every mark. Files and folders on disk are deleted
  /// outright (a marked folder subsumes its marked descendants). Entries marked
  /// *inside* an archive are removed by rewriting that archive once to a temp
  /// file and swapping it in — unless the archive file itself is also being
  /// deleted, in which case they go with it.
  Future<DeletionResult> commitDeletions() async {
    final targets = deletePaths..sort();
    final fsTargets = [
      for (final t in targets)
        if (!isArchiveMemberPath(t)) t,
    ];
    final archiveTargets = [
      for (final t in targets)
        if (isArchiveMemberPath(t)) t,
    ];

    var deleted = 0;
    final failures = <(String, String)>[];
    final doneFs = <String>{};
    final doneArchive = <String>{};

    // --- filesystem deletions (files, folders, whole archive files) --------
    final roots = <String>[];
    for (final path in fsTargets) {
      final covered = roots.any(
        (r) => p.equals(r, path) || p.isWithin(r, path),
      );
      if (!covered) roots.add(path);
    }
    final fs = ref.read(fileSourceProvider);
    for (final path in roots) {
      try {
        final entry = await fs.stat(path);
        await fs.delete(path, isDirectory: entry.isDirectory);
        deleted++;
        doneFs.add(path);
      } on FileSourceException catch (e) {
        if (e.notFound) {
          deleted++; // already gone — treat as success
          doneFs.add(path);
        } else {
          failures.add((path, e.message));
        }
      }
    }

    bool archiveFileGone(String archivePath) => doneFs.any(
      (d) => p.equals(d, archivePath) || p.isWithin(d, archivePath),
    );

    // --- archive-member deletions (repackage each affected archive once) ---
    final byArchive = <String, List<String>>{};
    for (final t in archiveTargets) {
      byArchive.putIfAbsent(rootArchiveOf(t), () => []).add(t);
    }
    final writer = ref.read(archiveWriterProvider);
    for (final entryPair in byArchive.entries) {
      final archivePath = entryPair.key;
      final members = entryPair.value;
      if (archiveFileGone(archivePath)) {
        doneArchive.addAll(members); // subsumed by the deleted archive file
        continue;
      }
      final remove = {for (final m in members) splitArchivePath(m).$2};
      final result = await writer.rewriteWithout(archivePath, remove);
      switch (result) {
        case ArchiveOk():
          deleted += remove.length;
          doneArchive.addAll(members);
          ref.invalidate(archiveEntriesProvider(archivePath));
        case ArchiveFailure(:final message):
          failures.add((archivePath, message));
      }
    }

    // --- clear marks for everything that is now gone ----------------------
    bool removed(String key) {
      if (doneArchive.contains(key)) return true;
      final base = isArchiveMemberPath(key) ? rootArchiveOf(key) : key;
      return doneFs.any((d) => p.equals(d, base) || p.isWithin(d, base));
    }

    final next = <String, Mark>{
      for (final e in _current.entries)
        if (!removed(e.key)) e.key: e.value,
    };
    await _commit(next);

    return DeletionResult(deleted: deleted, failures: failures);
  }
}
