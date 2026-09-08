import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Read-only text preview, capped so a huge log doesn't blow up memory.
class TextView extends StatelessWidget {
  const TextView({required this.path, super.key});

  final String path;

  static const _maxBytes = 1 << 20; // 1 MiB

  Future<(String, bool)> _read() async {
    final file = File(path);
    final len = await file.length();
    final raf = await file.open();
    try {
      final bytes = await raf.read(len.clamp(0, _maxBytes));
      return (
        const Utf8Decoder(allowMalformed: true).convert(bytes),
        len > _maxBytes,
      );
    } finally {
      await raf.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String, bool)>(
      future: _read(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (text, truncated) = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (truncated)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.secondaryContainer,
                padding: const EdgeInsets.all(6),
                child: const Text('Showing first 1 MiB only'),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  text,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
