import 'package:flutter/material.dart';

import '../../../core/file_kind.dart';
import '../../../data/fs/fs_entry.dart';

/// Leading glyph for a directory row or a file row (by [FileKind]).
class EntryIcon extends StatelessWidget {
  const EntryIcon(this.entry, {super.key});

  final FsEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.isDirectory) {
      return const Icon(Icons.folder, color: Color(0xFFE8B339));
    }
    final data = switch (fileKindOf(entry.name)) {
      FileKind.image => Icons.image_outlined,
      FileKind.video => Icons.movie_outlined,
      FileKind.audio => Icons.audiotrack_outlined,
      FileKind.pdf => Icons.picture_as_pdf_outlined,
      FileKind.comic => Icons.auto_stories_outlined,
      FileKind.archive => Icons.folder_zip_outlined,
      FileKind.text => Icons.description_outlined,
      FileKind.other => Icons.insert_drive_file_outlined,
    };
    return Icon(data, color: Theme.of(context).colorScheme.onSurfaceVariant);
  }
}
