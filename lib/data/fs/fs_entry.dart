import 'package:path/path.dart' as p;

/// One item in a directory listing: a file or a subdirectory.
class FsEntry {
  const FsEntry({
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.accessed,
    required this.changed,
  });

  /// Absolute, normalized path. Also the mark key.
  final String path;
  final bool isDirectory;

  /// Bytes. `0` for directories.
  final int size;

  final DateTime modified;
  final DateTime accessed;

  /// Metadata-change / creation time as reported by the OS.
  final DateTime changed;

  String get name => p.basename(path);

  @override
  bool operator ==(Object other) => other is FsEntry && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
