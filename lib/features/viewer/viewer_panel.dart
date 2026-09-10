import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/file_kind.dart';
import '../../core/formatting.dart';
import '../../data/archives/archive_entry.dart';
import '../../data/fs/fs_entry.dart';
import '../../data/marks/mark.dart';
import '../../data/marks/marks_controller.dart';
import 'archive_entry_file.dart';
import 'scrub_mode_controller.dart';
import 'selection_controller.dart';
import 'widgets/archive_view.dart';
import 'widgets/comic_view.dart';
import 'widgets/hex_view.dart';
import 'widgets/image_view.dart';
import 'widgets/mark_choice.dart';
import 'widgets/media_view.dart';
import 'widgets/pdf_view.dart';
import 'widgets/text_view.dart';

/// The right pane: metadata header with the mark toggle, then the file body.
class ViewerPanel extends ConsumerWidget {
  const ViewerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(selectionProvider);
    if (entry == null) {
      return const _EmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(entry: entry),
        const Divider(height: 1),
        Expanded(child: _Body(entry: entry)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/branding/cull_icon_256.png',
            width: 96,
            height: 96,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const SizedBox(width: 96, height: 96),
          ),
          const SizedBox(height: 16),
          Text('Cull', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Open a folder, then select a file to preview it.',
            style: text.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.entry});

  final FsEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mark = ref.watch(
      marksControllerProvider.select(
        (v) => (v.asData?.value ?? const {})[entry.path] ?? Mark.safe,
      ),
    );
    final text = Theme.of(context).textTheme;
    final isDir = entry.isDirectory;
    final kind = fileKindOf(entry.name);
    final scrubbing = ref.watch(scrubModeProvider) && !isDir && kind.isMedia;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        style: text.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (scrubbing) ...[
                      const SizedBox(width: 8),
                      const _ScrubChip(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.path,
                  style: text.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 2,
                  children: [
                    _Fact('Type', isDir ? 'folder' : kind.name),
                    if (!isDir) _Fact('Size', formatBytes(entry.size)),
                    _Fact('Modified', formatDateTime(entry.modified)),
                    _Fact('Changed', formatDateTime(entry.changed)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MarkChoice(
                mark: mark,
                onChanged: (m) => ref
                    .read(marksControllerProvider.notifier)
                    .setMark(entry.path, m),
              ),
              const SizedBox(height: 4),
              Text(
                isDir
                    ? '↑ ↓ move · ← → expand/collapse'
                    : 'D delete · S keep · Enter next · ↑ ↓ move · V scrub',
                style: text.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrubChip extends StatelessWidget {
  const _ScrubChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fast_forward, size: 14),
          const SizedBox(width: 4),
          Text('SCRUB', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: text.bodySmall,
        children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

/// Shown when the selection lands on a folder row (Up/Down can walk onto one).
class _FolderNote extends StatelessWidget {
  const _FolderNote({required this.entry, super.key});

  final FsEntry entry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder, size: 72),
          const SizedBox(height: 12),
          Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Folder — press → to expand, ← to collapse',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.entry});

  final FsEntry entry;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(entry.path);
    if (entry.isDirectory) {
      return _FolderNote(key: key, entry: entry);
    }
    if (isArchiveMemberPath(entry.path)) {
      return _ArchiveEntryBody(key: key, entry: entry);
    }
    return bodyForKind(fileKindOf(entry.name), entry.path, key);
  }
}

/// Dispatches a real on-disk [path] to the viewer for [kind].
Widget bodyForKind(FileKind kind, String path, Key key) => switch (kind) {
  FileKind.image => ImageView(key: key, path: path),
  FileKind.video => MediaView(key: key, path: path, audioOnly: false),
  FileKind.audio => MediaView(key: key, path: path, audioOnly: true),
  FileKind.pdf => PdfView(key: key, path: path),
  FileKind.comic => ComicView(key: key, path: path),
  FileKind.text => TextView(key: key, path: path),
  FileKind.archive => ArchiveView(key: key, path: path),
  FileKind.other => HexView(key: key, path: path),
};

/// A file that lives inside an archive: pull it out to a temp file, then hand
/// the real path to the normal viewer for its kind.
class _ArchiveEntryBody extends ConsumerWidget {
  const _ArchiveEntryBody({required this.entry, super.key});

  final FsEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extracted = ref.watch(archiveEntryFileProvider(entry.path));
    return extracted.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not open this archive entry:\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (path) => bodyForKind(
        fileKindOf(entry.name),
        path,
        ValueKey('${entry.path}#extracted'),
      ),
    );
  }
}
