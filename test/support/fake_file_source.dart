import 'package:cull/data/fs/file_source.dart';
import 'package:cull/data/fs/fs_entry.dart';
import 'package:path/path.dart' as p;

/// In-memory [FileSource] for tests. Build a tree with [addDir]/[addFile]
/// using native-style paths for the host (on Windows, `C:\root\sub\a.mp4`).
class FakeFileSource implements FileSource {
  final Map<String, FsEntry> _entries = {};
  final List<String> deleteCalls = [];

  /// Paths whose [delete] should fail with a non-"does not exist" error,
  /// simulating a locked file on Windows.
  final Set<String> failDeletesFor = {};

  final _epoch = DateTime(2026, 1, 1);

  void addDir(String path) {
    _entries[path] = FsEntry(
      path: path,
      isDirectory: true,
      size: 0,
      modified: _epoch,
      accessed: _epoch,
      changed: _epoch,
    );
  }

  void addFile(String path, {int size = 16}) {
    _entries[path] = FsEntry(
      path: path,
      isDirectory: false,
      size: size,
      modified: _epoch,
      accessed: _epoch,
      changed: _epoch,
    );
  }

  @override
  String? get homePath => p.join('C:', 'home');

  @override
  Future<List<FsEntry>> list(String dirPath) async {
    if (!_entries.containsKey(dirPath)) {
      throw FileSourceException(
        dirPath,
        'Directory does not exist',
        notFound: true,
      );
    }
    return _entries.values
        .where((e) => e.path != dirPath && p.dirname(e.path) == dirPath)
        .toList()
      ..sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  @override
  Stream<FsEntry> listRecursive(String dirPath) async* {
    for (final e in _entries.values) {
      if (!e.isDirectory && p.isWithin(dirPath, e.path)) yield e;
    }
  }

  @override
  Future<FsEntry> stat(String path) async {
    final e = _entries[path];
    if (e == null) {
      throw FileSourceException(path, 'Path does not exist', notFound: true);
    }
    return e;
  }

  @override
  Future<void> delete(String path, {required bool isDirectory}) async {
    deleteCalls.add(path);
    if (failDeletesFor.contains(path)) {
      throw FileSourceException(path, 'The process cannot access the file');
    }
    if (!_entries.containsKey(path)) {
      throw FileSourceException(path, 'Path does not exist', notFound: true);
    }
    _entries.removeWhere((k, _) => k == path || p.isWithin(path, k));
  }
}
