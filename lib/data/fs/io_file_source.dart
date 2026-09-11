import 'dart:io';

import 'package:path/path.dart' as p;

import 'file_source.dart';
import 'fs_entry.dart';

/// `dart:io` backend. Used on Windows/macOS/Linux.
class IoFileSource implements FileSource {
  const IoFileSource();

  @override
  String? get homePath =>
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];

  /// How many children to `stat` concurrently. A folder with tens of
  /// thousands of entries would otherwise take a long time to list — one
  /// awaited `stat` at a time — and that cost is paid again on every
  /// [listRecursive]-free re-list the directory watcher triggers.
  static const _statConcurrency = 64;

  @override
  Future<List<FsEntry>> list(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      throw FileSourceException(
        dirPath,
        'Directory does not exist',
        notFound: true,
      );
    }
    final children = <FileSystemEntity>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        children.add(e);
      }
    } on FileSystemException catch (e) {
      throw FileSourceException(dirPath, e.message, cause: e);
    }

    final entries = <FsEntry>[];
    for (var i = 0; i < children.length; i += _statConcurrency) {
      final batch = children.skip(i).take(_statConcurrency);
      final stated = await Future.wait(
        batch.map((e) async {
          try {
            return await _toEntry(e);
          } on FileSystemException {
            return null; // unreadable child (locked, permission) — skip it
          }
        }),
      );
      entries.addAll(stated.nonNulls);
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  @override
  Stream<FsEntry> listRecursive(String dirPath) async* {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;
    final stack = <Directory>[dir];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      List<FileSystemEntity> children;
      try {
        children = await current.list(followLinks: false).toList();
      } on FileSystemException {
        continue; // skip unreadable subtree
      }
      for (final child in children) {
        if (child is Directory) {
          stack.add(child);
        } else if (child is File) {
          try {
            yield await _toEntry(child);
          } on FileSystemException {
            // skip
          }
        }
      }
    }
  }

  @override
  Future<FsEntry> stat(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      throw FileSourceException(path, 'Path does not exist', notFound: true);
    }
    final entity = type == FileSystemEntityType.directory
        ? Directory(path)
        : File(path);
    return _toEntry(entity);
  }

  @override
  Future<void> delete(String path, {required bool isDirectory}) async {
    try {
      final entity = isDirectory ? Directory(path) : File(path);
      await entity.delete(recursive: isDirectory);
    } on FileSystemException catch (e) {
      // errno 2 = ENOENT / ERROR_FILE_NOT_FOUND, 3 = ERROR_PATH_NOT_FOUND.
      final code = e.osError?.errorCode;
      throw FileSourceException(
        path,
        e.osError?.message ?? e.message,
        notFound: code == 2 || code == 3,
        cause: e,
      );
    }
  }

  Future<FsEntry> _toEntry(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final isDir = stat.type == FileSystemEntityType.directory;
    return FsEntry(
      path: p.normalize(entity.absolute.path),
      isDirectory: isDir,
      size: isDir ? 0 : stat.size,
      modified: stat.modified,
      accessed: stat.accessed,
      changed: stat.changed,
    );
  }
}
