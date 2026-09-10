import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import 'archive_format.dart';
import 'archive_reader.dart';
import 'archive_result.dart';

/// Pure-Dart repackager for ZIP and uncompressed tar. Rewrites the archive to a
/// sibling `*.cull-tmp` file, then swaps it over the original — the original is
/// only touched once the replacement is fully written and closed.
///
/// A round-trip through `package:archive` re-deflates every retained entry and
/// does not preserve extra fields, so the confirm dialog must warn that the
/// archive is being rebuilt. `.tgz`/`.7z` rewrites go to the native backend.
class PackageArchiveWriter implements ArchiveWriter {
  const PackageArchiveWriter({this.maxBytes = 512 << 20});

  final int maxBytes;

  static const _handled = {ArchiveFormat.zip, ArchiveFormat.tar};

  @override
  bool canWrite(String archivePath) =>
      _handled.contains(archiveFormatOf(archivePath));

  @override
  Future<ArchiveResult<void>> rewriteWithout(
    String archivePath,
    Set<String> remove, {
    void Function(RewriteProgress)? onProgress,
  }) async {
    final format = archiveFormatOf(archivePath);
    if (!_handled.contains(format)) {
      return const ArchiveFailure(ArchiveErrorKind.notWritable);
    }
    if (remove.isEmpty) return const ArchiveOk(null);

    final src = File(archivePath);
    final int length;
    try {
      length = await src.length();
    } on FileSystemException {
      return const ArchiveFailure(ArchiveErrorKind.notFound);
    }
    if (length > maxBytes) {
      return const ArchiveFailure(ArchiveErrorKind.tooLarge);
    }

    final Uint8List input;
    try {
      input = await src.readAsBytes();
    } on FileSystemException {
      return const ArchiveFailure(ArchiveErrorKind.io);
    }

    final Uint8List rebuilt;
    try {
      rebuilt = await Isolate.run(() => _rebuildSync(input, format!, remove));
    } catch (_) {
      return const ArchiveFailure(ArchiveErrorKind.corrupt);
    }
    onProgress?.call(
      RewriteProgress(
        entriesDone: 1,
        entriesTotal: 1,
        bytesDone: rebuilt.length,
        bytesTotal: rebuilt.length,
      ),
    );

    return _swapIn(archivePath, rebuilt);
  }

  Future<ArchiveResult<void>> _swapIn(
    String archivePath,
    Uint8List data,
  ) async {
    final dir = p.dirname(archivePath);
    final tmp = File(p.join(dir, '${p.basename(archivePath)}.cull-tmp'));
    try {
      await tmp.writeAsBytes(data, flush: true);
    } on FileSystemException {
      try {
        if (await tmp.exists()) await tmp.delete();
      } on FileSystemException {
        // best effort
      }
      return const ArchiveFailure(ArchiveErrorKind.io);
    }
    try {
      // rename() replaces atomically on POSIX; on Windows it throws if the
      // destination exists, so fall back to delete-then-rename.
      await tmp.rename(archivePath);
    } on FileSystemException {
      try {
        await File(archivePath).delete();
        await tmp.rename(archivePath);
      } on FileSystemException {
        try {
          if (await tmp.exists()) await tmp.delete();
        } on FileSystemException {
          // best effort
        }
        return const ArchiveFailure(ArchiveErrorKind.io);
      }
    }
    return const ArchiveOk(null);
  }

  // --- isolate body ------------------------------------------------------

  static Uint8List _rebuildSync(
    Uint8List bytes,
    ArchiveFormat format,
    Set<String> remove,
  ) {
    final source = format == ArchiveFormat.zip
        ? ZipDecoder().decodeBytes(bytes)
        : TarDecoder().decodeBytes(bytes);

    bool dropped(String name) {
      final n = name.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');
      if (remove.contains(n)) return true;
      // A removed directory takes its whole subtree with it.
      return remove.any((r) => n == r || n.startsWith('$r/'));
    }

    final out = Archive();
    for (final f in source) {
      final name = f.name.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');
      if (dropped(name)) continue;
      if (f.isFile) {
        final data = f.readBytes() ?? Uint8List(0);
        out.add(
          ArchiveFile.bytes(f.name, data)
            ..lastModTime = f.lastModTime
            ..mode = f.mode,
        );
      } else {
        out.add(ArchiveFile.directory(f.name)..lastModTime = f.lastModTime);
      }
    }

    return format == ArchiveFormat.zip
        ? ZipEncoder().encodeBytes(out)
        : TarEncoder().encodeBytes(out);
  }
}
