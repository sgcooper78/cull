import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/formatting.dart';

/// Lists the entries inside a `.zip`. Other archive formats (7z, rar, tar)
/// show a not-supported note in v1.
class ArchiveView extends StatelessWidget {
  const ArchiveView({required this.path, super.key});

  final String path;

  static const _maxBytes = 64 << 20; // 64 MiB

  Future<List<({String name, int size, bool isFile})>> _entries() async {
    if (p.extension(path).toLowerCase() != '.zip') {
      throw const _Unsupported();
    }
    final file = File(path);
    if (await file.length() > _maxBytes) throw const _TooBig();
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    return [
      for (final e in archive) (name: e.name, size: e.size, isFile: e.isFile),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<({String name, int size, bool isFile})>>(
      future: _entries(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final msg = switch (snap.error) {
            _Unsupported() => 'Listing is only supported for .zip in v1.',
            _TooBig() => 'Archive is larger than 64 MiB — not listed.',
            _ => 'Could not read archive:\n${snap.error}',
          };
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(msg, textAlign: TextAlign.center),
            ),
          );
        }
        final entries = snap.data!;
        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (_, i) {
            final e = entries[i];
            return ListTile(
              dense: true,
              leading: Icon(
                e.isFile ? Icons.insert_drive_file_outlined : Icons.folder,
              ),
              title: Text(e.name, overflow: TextOverflow.ellipsis),
              trailing: e.isFile ? Text(formatBytes(e.size)) : null,
            );
          },
        );
      },
    );
  }
}

class _Unsupported implements Exception {
  const _Unsupported();
}

class _TooBig implements Exception {
  const _TooBig();
}
