import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// A container format Cull can look inside. Ordered roughly by how we open it,
/// not by popularity.
enum ArchiveFormat {
  /// PKZIP family — `.zip`, `.cbz`, `.jar`, `.epub`… Pure-Dart read + write.
  zip,

  /// USTAR/PAX/GNU tar, uncompressed — `.tar`, `.cbt`. Pure-Dart read + write.
  tar,

  /// tar wrapped in a single compression filter — `.tgz`, `.tar.gz`, `.tbz2`,
  /// `.tar.xz`. Pure-Dart read; write goes through the native backend.
  compressedTar,

  /// 7-Zip — `.7z`, `.cb7`. Native backend (libarchive) read + write.
  sevenZip,

  /// RAR — `.rar`, `.cbr`. Native backend read only; **cannot be rebuilt**.
  rar,

  /// Everything libarchive can list but we treat as read-only curiosities:
  /// `.iso`, `.cab`, `.lha`, `.arj`, `.ar`, `.cpio`, `.xar`…
  otherReadOnly;

  /// Can we enumerate entries and pull bytes out (given the backend it needs)?
  bool get isBrowsable => true;

  /// Can [ArchiveWriter.rewriteWithout] produce a valid replacement? Gates
  /// whether entries inside may be marked for deletion.
  bool get isRewritable => switch (this) {
    zip || tar || compressedTar || sevenZip => true,
    rar || otherReadOnly => false,
  };

  /// Does opening it require the native libarchive backend?
  bool get needsNativeBackend => switch (this) {
    zip || tar || compressedTar => false,
    sevenZip || rar || otherReadOnly => true,
  };
}

const _zipExt = {
  'zip',
  'zipx',
  'cbz',
  'jar',
  'war',
  'ear',
  'apk',
  'xpi',
  'crx',
  'nupkg',
  'whl',
  'egg',
  'epub',
  'odt',
  'ods',
  'odp',
  'docx',
  'xlsx',
  'pptx',
  'vsix',
};
const _tarExt = {'tar', 'cbt'};
const _compressedTarExt = {'tgz', 'tbz', 'tbz2', 'txz', 'tzst', 'taz', 'tlz'};
const _sevenZipExt = {'7z', 'cb7'};
const _rarExt = {'rar', 'cbr'};
const _otherReadOnlyExt = {
  'iso',
  'cab',
  'lha',
  'lzh',
  'arj',
  'ar',
  'a',
  'cpio',
  'xar',
  'rpm',
  'deb',
  'ace',
  'alz',
  'z',
  'cpgz',
};

/// Classifies by extension, including the `.tar.gz` double extension.
ArchiveFormat? archiveFormatOf(String path) {
  final lower = p.basename(path).toLowerCase();
  if (lower.endsWith('.tar.gz') ||
      lower.endsWith('.tar.bz2') ||
      lower.endsWith('.tar.xz') ||
      lower.endsWith('.tar.zst') ||
      lower.endsWith('.tar.lz')) {
    return ArchiveFormat.compressedTar;
  }
  final ext = p.extension(lower).replaceFirst('.', '');
  if (_zipExt.contains(ext)) return ArchiveFormat.zip;
  if (_tarExt.contains(ext)) return ArchiveFormat.tar;
  if (_compressedTarExt.contains(ext)) return ArchiveFormat.compressedTar;
  if (_sevenZipExt.contains(ext)) return ArchiveFormat.sevenZip;
  if (_rarExt.contains(ext)) return ArchiveFormat.rar;
  if (_otherReadOnlyExt.contains(ext)) return ArchiveFormat.otherReadOnly;
  return null;
}

/// Sniffs the first bytes of [file] to catch mislabelled archives — a `.cbz`
/// that is really RAR, a `.bin` that is really 7z. Returns `null` if nothing
/// matches (caller falls back to [archiveFormatOf]).
Future<ArchiveFormat?> sniffArchiveFormat(File file) async {
  RandomAccessFile? raf;
  try {
    raf = await file.open();
    final head = await raf.read(8);
    if (head.length < 4) return null;
    return _magic(head);
  } on FileSystemException {
    return null;
  } finally {
    await raf?.close();
  }
}

ArchiveFormat? _magic(Uint8List b) {
  bool starts(List<int> sig) {
    if (b.length < sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (b[i] != sig[i]) return false;
    }
    return true;
  }

  // 7z: '7z' BC AF 27 1C
  if (starts([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C])) {
    return ArchiveFormat.sevenZip;
  }
  // RAR4: 'Rar!' 1A 07 00 ; RAR5: 'Rar!' 1A 07 01 00
  if (starts([0x52, 0x61, 0x72, 0x21, 0x1A, 0x07])) return ArchiveFormat.rar;
  // ZIP: 'PK' 03 04 / 05 06 (empty) / 07 08 (spanned)
  if (starts([0x50, 0x4B]) && (b[2] == 0x03 || b[2] == 0x05 || b[2] == 0x07)) {
    return ArchiveFormat.zip;
  }
  // GZIP: 1F 8B  (assume tar inside for our purposes)
  if (starts([0x1F, 0x8B])) return ArchiveFormat.compressedTar;
  // XZ: FD '7zXZ' 00
  if (starts([0xFD, 0x37, 0x7A, 0x58, 0x5A, 0x00])) {
    return ArchiveFormat.compressedTar;
  }
  // BZIP2: 'BZh'
  if (starts([0x42, 0x5A, 0x68])) return ArchiveFormat.compressedTar;
  return null;
}
