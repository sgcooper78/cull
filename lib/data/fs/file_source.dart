import 'fs_entry.dart';

/// Abstraction over the filesystem so platform backends (desktop `dart:io`
/// today; Android SAF / web File System Access later) can differ without
/// touching feature code. See CLAUDE.md "Platform strategy".
abstract interface class FileSource {
  /// Direct children of [dirPath]. Directories first, then files, each group
  /// sorted case-insensitively by name. Throws [FileSourceException] on
  /// permission or IO errors.
  Future<List<FsEntry>> list(String dirPath);

  /// Every file under [dirPath], recursively (no directories). Unreadable
  /// subtrees are skipped, not fatal.
  Stream<FsEntry> listRecursive(String dirPath);

  /// Metadata for a single path.
  Future<FsEntry> stat(String path);

  /// Permanently delete a file, or a directory and everything in it.
  /// Throws [FileSourceException] on failure (e.g. file in use on Windows).
  Future<void> delete(String path, {required bool isDirectory});

  /// The user's home directory, or null if it can't be determined.
  String? get homePath;
}

class FileSourceException implements Exception {
  FileSourceException(
    this.path,
    this.message, {
    this.notFound = false,
    this.cause,
  });

  final String path;
  final String message;

  /// The path was already gone. Callers deleting a path can treat this as
  /// success rather than failure.
  final bool notFound;

  final Object? cause;

  @override
  String toString() => 'FileSourceException($path): $message';
}
