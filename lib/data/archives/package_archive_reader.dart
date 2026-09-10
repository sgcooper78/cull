import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'archive_entry.dart';
import 'archive_format.dart';
import 'archive_reader.dart';
import 'archive_result.dart';

/// Pure-Dart reader for the formats `package:archive` understands: the ZIP
/// family, uncompressed tar, and single-filter compressed tar (`.tgz` etc.).
///
/// The whole container is read into memory (capped by [maxBytes]) and decoded
/// on a background isolate, so no file handle lingers to block a later delete
/// on Windows. 7z/RAR are refused here — [CompositeArchiveReader] routes those
/// to the native backend.
class PackageArchiveReader implements ArchiveReader {
  const PackageArchiveReader({this.maxBytes = 512 << 20});

  final int maxBytes;

  static const _handled = {
    ArchiveFormat.zip,
    ArchiveFormat.tar,
    ArchiveFormat.compressedTar,
  };

  @override
  bool canRead(String archivePath) =>
      _handled.contains(archiveFormatOf(archivePath));

  @override
  Future<ArchiveResult<List<ArchiveEntry>>> list(String archivePath) async {
    final format = archiveFormatOf(archivePath);
    if (!_handled.contains(format)) {
      return const ArchiveFailure(ArchiveErrorKind.unsupportedFormat);
    }
    final bytes = await _readCapped(archivePath);
    if (bytes is ArchiveFailure) {
      return (bytes as ArchiveFailure).cast();
    }
    try {
      return await Isolate.run(
        () => _listSync((bytes as ArchiveOk<Uint8List>).value, format!),
      );
    } catch (_) {
      return const ArchiveFailure(ArchiveErrorKind.corrupt);
    }
  }

  @override
  Future<ArchiveResult<Uint8List>> readEntry(
    String archivePath,
    String entryPath,
  ) async {
    final format = archiveFormatOf(archivePath);
    if (!_handled.contains(format)) {
      return const ArchiveFailure(ArchiveErrorKind.unsupportedFormat);
    }
    final bytes = await _readCapped(archivePath);
    if (bytes is ArchiveFailure) {
      return (bytes as ArchiveFailure).cast();
    }
    try {
      return await Isolate.run(
        () => _readEntrySync(
          (bytes as ArchiveOk<Uint8List>).value,
          format!,
          entryPath,
        ),
      );
    } catch (_) {
      return const ArchiveFailure(ArchiveErrorKind.corrupt);
    }
  }

  Future<ArchiveResult<Uint8List>> _readCapped(String path) async {
    final file = File(path);
    final int length;
    try {
      length = await file.length();
    } on FileSystemException {
      return const ArchiveFailure(ArchiveErrorKind.notFound);
    }
    if (length > maxBytes) {
      return const ArchiveFailure(ArchiveErrorKind.tooLarge);
    }
    try {
      return ArchiveOk(await file.readAsBytes());
    } on FileSystemException {
      return const ArchiveFailure(ArchiveErrorKind.io);
    }
  }

  // --- isolate bodies (no `this`, no plugin calls) ------------------------

  static ArchiveResult<List<ArchiveEntry>> _listSync(
    Uint8List bytes,
    ArchiveFormat format,
  ) {
    final archive = _decode(bytes, format);
    final entries = <ArchiveEntry>[];
    for (final f in archive) {
      final name = f.name.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');
      if (name.isEmpty) continue;
      entries.add(
        ArchiveEntry(
          path: name,
          isDir: !f.isFile,
          size: f.isFile ? f.size : 0,
          modified: DateTime.fromMillisecondsSinceEpoch(
            f.lastModTime * 1000,
            isUtc: true,
          ),
        ),
      );
    }
    return ArchiveOk(_withSyntheticDirs(entries));
  }

  static ArchiveResult<Uint8List> _readEntrySync(
    Uint8List bytes,
    ArchiveFormat format,
    String entryPath,
  ) {
    final archive = _decode(bytes, format);
    for (final f in archive) {
      if (!f.isFile) continue;
      final name = f.name.replaceAll(r'\', '/');
      if (name == entryPath) {
        return ArchiveOk(f.readBytes() ?? Uint8List(0));
      }
    }
    return const ArchiveFailure(ArchiveErrorKind.entryNotFound);
  }

  static Archive _decode(Uint8List bytes, ArchiveFormat format) =>
      switch (format) {
        ArchiveFormat.zip => ZipDecoder().decodeBytes(bytes),
        ArchiveFormat.tar => TarDecoder().decodeBytes(bytes),
        ArchiveFormat.compressedTar => TarDecoder().decodeBytes(
          _inflate(bytes),
        ),
        _ => throw StateError('unreachable: $format'),
      };

  static List<int> _inflate(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      return GZipDecoder().decodeBytes(bytes);
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0xFD &&
        bytes[1] == 0x37 &&
        bytes[2] == 0x7A) {
      return XZDecoder().decodeBytes(bytes);
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x42 &&
        bytes[1] == 0x5A &&
        bytes[2] == 0x68) {
      return BZip2Decoder().decodeBytes(bytes);
    }
    return bytes; // plain .tar mislabelled — try as-is
  }

  /// tar and some zips omit directory entries; synthesise them so the tree
  /// builder has folders to hang children off.
  static List<ArchiveEntry> _withSyntheticDirs(List<ArchiveEntry> entries) {
    final byPath = {for (final e in entries) e.path: e};
    for (final e in List.of(entries)) {
      var parent = e.parent;
      while (parent.isNotEmpty && !byPath.containsKey(parent)) {
        final dir = ArchiveEntry(path: parent, isDir: true, size: 0);
        byPath[parent] = dir;
        entries.add(dir);
        parent = dir.parent;
      }
    }
    return entries;
  }
}
