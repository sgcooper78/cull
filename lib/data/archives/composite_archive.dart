import 'dart:typed_data';

import 'archive_entry.dart';
import 'archive_format.dart';
import 'archive_reader.dart';
import 'archive_result.dart';
import 'libarchive/libarchive_backend.dart';
import 'package_archive_reader.dart';
import 'package_archive_writer.dart';

/// The reader the app uses. Pure-Dart [PackageArchiveReader] handles the ZIP
/// family and tar; everything else falls through to [LibarchiveReader].
class CompositeArchiveReader implements ArchiveReader {
  CompositeArchiveReader({ArchiveReader? package, ArchiveReader? native})
    : _package = package ?? const PackageArchiveReader(),
      _native = native ?? const LibarchiveReader();

  final ArchiveReader _package;
  final ArchiveReader _native;

  @override
  bool canRead(String archivePath) => archiveFormatOf(archivePath) != null;

  ArchiveReader? _pick(String archivePath) {
    if (_package.canRead(archivePath)) return _package;
    if (_native.canRead(archivePath)) return _native;
    return null;
  }

  @override
  Future<ArchiveResult<List<ArchiveEntry>>> list(String archivePath) async {
    final reader = _pick(archivePath);
    if (reader == null) {
      return const ArchiveFailure(ArchiveErrorKind.unsupportedFormat);
    }
    return reader.list(archivePath);
  }

  @override
  Future<ArchiveResult<Uint8List>> readEntry(
    String archivePath,
    String entryPath,
  ) async {
    final reader = _pick(archivePath);
    if (reader == null) {
      return const ArchiveFailure(ArchiveErrorKind.unsupportedFormat);
    }
    return reader.readEntry(archivePath, entryPath);
  }
}

/// The writer the app uses for repackage-on-delete. Mirrors
/// [CompositeArchiveReader]'s routing.
class CompositeArchiveWriter implements ArchiveWriter {
  CompositeArchiveWriter({ArchiveWriter? package, ArchiveWriter? native})
    : _package = package ?? const PackageArchiveWriter(),
      _native = native ?? const LibarchiveWriter();

  final ArchiveWriter _package;
  final ArchiveWriter _native;

  @override
  bool canWrite(String archivePath) {
    final f = archiveFormatOf(archivePath);
    if (f == null || !f.isRewritable) return false;
    if (_package.canWrite(archivePath)) return true;
    return f.needsNativeBackend && libarchiveAvailable;
  }

  @override
  Future<ArchiveResult<void>> rewriteWithout(
    String archivePath,
    Set<String> remove, {
    void Function(RewriteProgress)? onProgress,
  }) async {
    final f = archiveFormatOf(archivePath);
    if (f == null || !f.isRewritable) {
      return const ArchiveFailure(ArchiveErrorKind.notWritable);
    }
    final writer = _package.canWrite(archivePath) ? _package : _native;
    return writer.rewriteWithout(archivePath, remove, onProgress: onProgress);
  }
}
