import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../archive_entry.dart';
import '../archive_format.dart';
import '../archive_reader.dart';
import '../archive_result.dart';
import 'libarchive_ffi.dart';

/// Whether the native libarchive shared library could be loaded in this
/// process. `false` → 7z/RAR/etc. degrade to a "backend not installed" card.
bool get libarchiveAvailable => LibArchive.tryLoad() != null;

/// libarchive-backed reader for the formats pure Dart can't do: 7z, RAR, and
/// the read-only oddities (iso/cab/lha/…). Each call does its work on a
/// background isolate because libarchive's API is blocking.
class LibarchiveReader implements ArchiveReader {
  const LibarchiveReader();

  @override
  bool canRead(String archivePath) {
    final f = archiveFormatOf(archivePath);
    return f != null && f.needsNativeBackend;
  }

  @override
  Future<ArchiveResult<List<ArchiveEntry>>> list(String archivePath) async {
    if (!libarchiveAvailable) {
      return const ArchiveFailure(ArchiveErrorKind.nativeBackendMissing);
    }
    if (!await File(archivePath).exists()) {
      return const ArchiveFailure(ArchiveErrorKind.notFound);
    }
    try {
      return await Isolate.run(() => _listSync(archivePath));
    } catch (_) {
      return const ArchiveFailure(ArchiveErrorKind.io);
    }
  }

  @override
  Future<ArchiveResult<Uint8List>> readEntry(
    String archivePath,
    String entryPath,
  ) async {
    if (!libarchiveAvailable) {
      return const ArchiveFailure(ArchiveErrorKind.nativeBackendMissing);
    }
    try {
      return await Isolate.run(() => _readEntrySync(archivePath, entryPath));
    } catch (_) {
      return const ArchiveFailure(ArchiveErrorKind.io);
    }
  }

  // --- isolate bodies --------------------------------------------------

  static ArchiveResult<List<ArchiveEntry>> _listSync(String archivePath) {
    final lib = LibArchive.tryLoad();
    if (lib == null) {
      return const ArchiveFailure(ArchiveErrorKind.nativeBackendMissing);
    }
    final a = lib.read_new();
    lib.read_support_filter_all(a);
    lib.read_support_format_all(a);
    final entry = lib.entry_new();
    final pathC = archivePath.toNativeUtf8();
    try {
      if (lib.read_open_filename(a, pathC, 1 << 16) != LibArchive.ok) {
        return _mapOpenError(lib.errorString(a));
      }
      final entries = <ArchiveEntry>[];
      while (true) {
        final rc = lib.read_next_header2(a, entry);
        if (rc == LibArchive.eof) break;
        if (rc < LibArchive.warn) {
          return _mapOpenError(lib.errorString(a));
        }
        final nameP = lib.entry_pathname(entry);
        final name = nameP == nullptr
            ? ''
            : nameP
                  .toDartString()
                  .replaceAll(r'\', '/')
                  .replaceAll(RegExp(r'/+$'), '');
        if (name.isEmpty) {
          lib.read_data_skip(a);
          continue;
        }
        final isDir =
            (lib.entry_filetype(entry) & LibArchive.ifmt) == LibArchive.ifdir;
        entries.add(
          ArchiveEntry(
            path: name,
            isDir: isDir,
            size: isDir ? 0 : lib.entry_size(entry),
            modified: DateTime.fromMillisecondsSinceEpoch(
              lib.entry_mtime(entry) * 1000,
              isUtc: true,
            ),
          ),
        );
        lib.read_data_skip(a);
      }
      return ArchiveOk(entries);
    } finally {
      lib.entry_free(entry);
      lib.read_close(a);
      lib.read_free(a);
      malloc.free(pathC);
    }
  }

  static ArchiveResult<Uint8List> _readEntrySync(
    String archivePath,
    String entryPath,
  ) {
    final lib = LibArchive.tryLoad();
    if (lib == null) {
      return const ArchiveFailure(ArchiveErrorKind.nativeBackendMissing);
    }
    final a = lib.read_new();
    lib.read_support_filter_all(a);
    lib.read_support_format_all(a);
    final entry = lib.entry_new();
    final pathC = archivePath.toNativeUtf8();
    const chunk = 256 * 1024;
    final buf = malloc<Uint8>(chunk);
    try {
      if (lib.read_open_filename(a, pathC, 1 << 16) != LibArchive.ok) {
        return _mapOpenError(lib.errorString(a)).cast();
      }
      while (true) {
        final rc = lib.read_next_header2(a, entry);
        if (rc == LibArchive.eof) break;
        if (rc < LibArchive.warn) {
          return _mapOpenError(lib.errorString(a)).cast();
        }
        final nameP = lib.entry_pathname(entry);
        final name = nameP == nullptr
            ? ''
            : nameP.toDartString().replaceAll(r'\', '/');
        if (name != entryPath) {
          lib.read_data_skip(a);
          continue;
        }
        final out = BytesBuilder(copy: false);
        while (true) {
          final n = lib.read_data(a, buf.cast(), chunk);
          if (n == 0) break;
          if (n < 0) return const ArchiveFailure(ArchiveErrorKind.corrupt);
          out.add(buf.asTypedList(n).sublist(0, n));
        }
        return ArchiveOk(out.toBytes());
      }
      return const ArchiveFailure(ArchiveErrorKind.entryNotFound);
    } finally {
      malloc.free(buf);
      lib.entry_free(entry);
      lib.read_close(a);
      lib.read_free(a);
      malloc.free(pathC);
    }
  }

  static ArchiveFailure<List<ArchiveEntry>> _mapOpenError(String err) {
    final e = err.toLowerCase();
    if (e.contains('passphrase') || e.contains('encrypt')) {
      return const ArchiveFailure(ArchiveErrorKind.encrypted);
    }
    if (e.contains('recogniz') || e.contains('unrecogn')) {
      return const ArchiveFailure(ArchiveErrorKind.unsupportedFormat);
    }
    return ArchiveFailure(ArchiveErrorKind.corrupt, err.isEmpty ? null : err);
  }
}

/// libarchive-backed repackager for 7z and compressed tar. RAR and the
/// read-only oddities return [ArchiveErrorKind.notWritable].
class LibarchiveWriter implements ArchiveWriter {
  const LibarchiveWriter();

  @override
  bool canWrite(String archivePath) {
    final f = archiveFormatOf(archivePath);
    return f != null && f.needsNativeBackend && f.isRewritable;
  }

  @override
  Future<ArchiveResult<void>> rewriteWithout(
    String archivePath,
    Set<String> remove, {
    void Function(RewriteProgress)? onProgress,
  }) async {
    final format = archiveFormatOf(archivePath);
    if (format == null || !format.isRewritable) {
      return const ArchiveFailure(ArchiveErrorKind.notWritable);
    }
    if (!format.needsNativeBackend) {
      return const ArchiveFailure(ArchiveErrorKind.unsupportedFormat);
    }
    if (!libarchiveAvailable) {
      return const ArchiveFailure(ArchiveErrorKind.nativeBackendMissing);
    }
    if (remove.isEmpty) return const ArchiveOk(null);
    if (!await File(archivePath).exists()) {
      return const ArchiveFailure(ArchiveErrorKind.notFound);
    }

    final tmp = p.join(
      p.dirname(archivePath),
      '${p.basename(archivePath)}.cull-tmp',
    );
    final ArchiveResult<void> result;
    try {
      result = await Isolate.run(
        () => _rewriteSync(archivePath, tmp, format, remove),
      );
    } catch (_) {
      await _tidy(tmp);
      return const ArchiveFailure(ArchiveErrorKind.io);
    }
    if (result is ArchiveFailure) {
      await _tidy(tmp);
      return result;
    }

    // Swap the freshly written temp file over the original.
    try {
      await File(tmp).rename(archivePath);
    } on FileSystemException {
      try {
        await File(archivePath).delete();
        await File(tmp).rename(archivePath);
      } on FileSystemException {
        await _tidy(tmp);
        return const ArchiveFailure(ArchiveErrorKind.io);
      }
    }
    onProgress?.call(
      const RewriteProgress(
        entriesDone: 1,
        entriesTotal: 1,
        bytesDone: 1,
        bytesTotal: 1,
      ),
    );
    return const ArchiveOk(null);
  }

  static Future<void> _tidy(String tmp) async {
    try {
      final f = File(tmp);
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // best effort
    }
  }

  static ArchiveResult<void> _rewriteSync(
    String srcPath,
    String tmpPath,
    ArchiveFormat format,
    Set<String> remove,
  ) {
    final lib = LibArchive.tryLoad();
    if (lib == null) {
      return const ArchiveFailure(ArchiveErrorKind.nativeBackendMissing);
    }
    final r = lib.read_new();
    lib.read_support_filter_all(r);
    lib.read_support_format_all(r);
    final w = lib.write_new();
    switch (format) {
      case ArchiveFormat.sevenZip:
        lib.write_set_format_7zip(w);
      case ArchiveFormat.compressedTar:
        lib.write_set_format_pax_restricted(w);
        lib.write_add_filter_gzip(w);
      default:
        lib.write_set_format_pax_restricted(w);
        lib.write_add_filter_none(w);
    }

    final entry = lib.entry_new();
    final srcC = srcPath.toNativeUtf8();
    final tmpC = tmpPath.toNativeUtf8();
    const chunk = 256 * 1024;
    final buf = malloc<Uint8>(chunk);

    bool dropped(String name) {
      final n = name.replaceAll(r'\', '/').replaceAll(RegExp(r'/+$'), '');
      return remove.contains(n) || remove.any((x) => n.startsWith('$x/'));
    }

    try {
      if (lib.read_open_filename(r, srcC, 1 << 16) != LibArchive.ok) {
        return ArchiveFailure(ArchiveErrorKind.corrupt, lib.errorString(r));
      }
      if (lib.write_open_filename(w, tmpC) != LibArchive.ok) {
        return ArchiveFailure(ArchiveErrorKind.io, lib.errorString(w));
      }
      while (true) {
        final rc = lib.read_next_header2(r, entry);
        if (rc == LibArchive.eof) break;
        if (rc < LibArchive.warn) {
          return ArchiveFailure(ArchiveErrorKind.corrupt, lib.errorString(r));
        }
        final nameP = lib.entry_pathname(entry);
        final name = nameP == nullptr ? '' : nameP.toDartString();
        if (name.isEmpty || dropped(name)) {
          lib.read_data_skip(r);
          continue;
        }
        if (lib.write_header(w, entry) < LibArchive.warn) {
          return ArchiveFailure(ArchiveErrorKind.io, lib.errorString(w));
        }
        while (true) {
          final n = lib.read_data(r, buf.cast(), chunk);
          if (n == 0) break;
          if (n < 0) {
            return ArchiveFailure(ArchiveErrorKind.corrupt, lib.errorString(r));
          }
          var off = 0;
          while (off < n) {
            final wrote = lib.write_data(w, (buf + off).cast(), n - off);
            if (wrote < 0) {
              return ArchiveFailure(ArchiveErrorKind.io, lib.errorString(w));
            }
            off += wrote;
          }
        }
        lib.write_finish_entry(w);
      }
      lib.write_close(w);
      return const ArchiveOk(null);
    } finally {
      malloc.free(buf);
      lib.entry_free(entry);
      lib.read_close(r);
      lib.read_free(r);
      lib.write_free(w);
      malloc.free(srcC);
      malloc.free(tmpC);
    }
  }
}
