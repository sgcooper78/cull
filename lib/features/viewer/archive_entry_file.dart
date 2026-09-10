import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/archives/archive_entry.dart';
import '../../data/archives/archive_providers.dart';
import '../../data/archives/archive_result.dart';

part 'archive_entry_file.g.dart';

/// Raised when an archive entry can't be pulled out for preview.
class ArchiveEntryUnavailable implements Exception {
  ArchiveEntryUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Extracts one archive entry ([virtualPath] carries the `!/` separator) to a
/// file in the OS temp area and returns that real path, so the existing
/// path-based viewers (image / media / pdf / text / hex) can open it
/// unchanged. Cached per entry; a giant archive browsed page by page grows the
/// cache — eviction is a TODO, same as `data/thumbs`.
@riverpod
Future<String> archiveEntryFile(Ref ref, String virtualPath) async {
  final (archivePath, entryPath) = splitArchivePath(virtualPath);
  final result = await ref
      .watch(archiveReaderProvider)
      .readEntry(archivePath, entryPath);

  final bytes = switch (result) {
    ArchiveOk(:final value) => value,
    ArchiveFailure(:final message) => throw ArchiveEntryUnavailable(message),
  };

  final tmp = await getTemporaryDirectory();
  final cacheDir = Directory(p.join(tmp.path, 'cull_archive_cache'));
  await cacheDir.create(recursive: true);

  final digest = sha1.convert(utf8.encode(virtualPath)).toString();
  final file = File(p.join(cacheDir.path, '$digest${p.extension(entryPath)}'));
  if (!await file.exists() || await file.length() != bytes.length) {
    await file.writeAsBytes(bytes, flush: true);
  }
  return file.path;
}
