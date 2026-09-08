import 'dart:io';

import 'package:flutter/material.dart';

/// Fallback for unrecognized files: a hex + ASCII dump of the first bytes.
class HexView extends StatelessWidget {
  const HexView({required this.path, super.key});

  final String path;

  static const _previewBytes = 1024;

  Future<List<int>> _head() async {
    final raf = await File(path).open();
    try {
      return await raf.read(_previewBytes);
    } finally {
      await raf.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _head(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            _dump(snap.data!),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        );
      },
    );
  }

  String _dump(List<int> bytes) {
    final sb = StringBuffer();
    for (var i = 0; i < bytes.length; i += 16) {
      final row = bytes.sublist(i, (i + 16).clamp(0, bytes.length));
      final hex = row
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ')
          .padRight(16 * 3 - 1);
      final ascii = row
          .map((b) => (b >= 0x20 && b < 0x7f) ? String.fromCharCode(b) : '.')
          .join();
      sb.writeln('${i.toRadixString(16).padLeft(8, '0')}  $hex  $ascii');
    }
    return sb.toString();
  }
}
