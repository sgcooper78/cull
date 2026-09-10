import 'package:path/path.dart' as p;

/// One node inside an archive — a file or a directory. Paths are the archive's
/// own internal paths: always `/`-separated, never host-native, no leading
/// slash (`photos/2026/IMG_001.jpg`).
class ArchiveEntry {
  const ArchiveEntry({
    required this.path,
    required this.isDir,
    required this.size,
    this.modified,
  });

  /// `/`-separated path inside the archive. Directory entries have no trailing
  /// slash.
  final String path;
  final bool isDir;

  /// Uncompressed size in bytes. `0` for directories.
  final int size;

  /// Modification time if the container records one.
  final DateTime? modified;

  /// Last path segment.
  String get name {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }

  /// Parent path inside the archive, or `''` for a top-level entry.
  String get parent {
    final i = path.lastIndexOf('/');
    return i < 0 ? '' : path.substring(0, i);
  }

  @override
  bool operator ==(Object other) =>
      other is ArchiveEntry && other.path == path && other.isDir == isDir;

  @override
  int get hashCode => Object.hash(path, isDir);

  @override
  String toString() => 'ArchiveEntry($path${isDir ? '/' : ''}, $size)';
}

/// Separates the on-disk archive path from an entry path inside it, e.g.
/// `C:\dl\photos.7z!/2026/IMG_001.jpg`. Chosen over a plain join because a real
/// directory can legitimately be named `photos.7z`, and the mark/delete
/// subsumption logic in [MarksController] compares paths with
/// `package:path`'s `isWithin` — an unambiguous marker keeps the two apart.
///
/// Nesting composes: `a.7z!/inner.zip!/x.jpg` splits (on the *first* `!/`) into
/// archive `a.7z` and entry `inner.zip!/x.jpg`, which is itself an archive
/// member path.
const archivePathSeparator = '!/';

/// True if [path] points at something inside an archive rather than on disk.
bool isArchiveMemberPath(String path) => path.contains(archivePathSeparator);

/// Splits an archive-member path into (on-disk archive, internal entry path).
/// The archive part may still be an archive-member path itself when archives
/// are nested. Returns `(path, '')` if [path] has no separator.
(String archive, String entry) splitArchivePath(String path) {
  final i = path.indexOf(archivePathSeparator);
  if (i < 0) return (path, '');
  return (
    path.substring(0, i),
    path.substring(i + archivePathSeparator.length),
  );
}

/// The on-disk `.zip`/`.7z`/… file that ultimately contains [path], peeling
/// away every level of nesting.
String rootArchiveOf(String path) {
  final i = path.indexOf(archivePathSeparator);
  return i < 0 ? path : path.substring(0, i);
}

/// Builds an archive-member path. [entry] is normalised to `/`-separated with
/// no leading/trailing slash.
String joinArchivePath(String archive, String entry) {
  final e = entry.replaceAll(r'\', '/').replaceAll(RegExp(r'^/+|/+$'), '');
  return '$archive$archivePathSeparator$e';
}

/// Rejects entry paths that would escape the archive root when extracted
/// (`../`, absolute, or drive-qualified). Zip-slip guard — call before writing
/// any entry to disk.
bool isSafeEntryPath(String entry) {
  if (entry.isEmpty) return false;
  final norm = p.posix.normalize(entry.replaceAll(r'\', '/'));
  if (norm.startsWith('/') || norm.startsWith('..')) return false;
  if (RegExp(r'^[a-zA-Z]:').hasMatch(norm)) return false;
  return !norm.split('/').contains('..');
}
