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
    final entries = <FsEntry>[];
    try {
      await for (final e in dir.list(followLinks: false)) {
        try {
          entries.add(await _toEntry(e));
        } on FileSystemException {
          // Unreadable child (locked, permission) — skip it.
        }
      }
    } on FileSystemException catch (e) {
      throw FileSourceException(dirPath, e.message, cause: e);
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
