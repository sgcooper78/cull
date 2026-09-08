import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/file_kind.dart';
import '../../core/formatting.dart';
import '../../data/fs/fs_entry.dart';
import '../../data/marks/mark.dart';
import '../../data/marks/marks_controller.dart';
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
      return const Center(child: Text('Select a file to preview it.'));
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
    final kind = fileKindOf(entry.name);
    final scrubbing = ref.watch(scrubModeProvider) && kind.isMedia;

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
                    _Fact('Type', kind.name),
                    _Fact('Size', formatBytes(entry.size)),
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
                'D delete · S keep · Enter next · V scrub',
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

class _Body extends StatelessWidget {
  const _Body({required this.entry});

  final FsEntry entry;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(entry.path);
    return switch (fileKindOf(entry.name)) {
      FileKind.image => ImageView(key: key, path: entry.path),
      FileKind.video => MediaView(key: key, path: entry.path, audioOnly: false),
      FileKind.audio => MediaView(key: key, path: entry.path, audioOnly: true),
      FileKind.pdf => PdfView(key: key, path: entry.path),
      FileKind.comic => ComicView(key: key, path: entry.path),
      FileKind.text => TextView(key: key, path: entry.path),
      FileKind.archive => ArchiveView(key: key, path: entry.path),
      FileKind.other => HexView(key: key, path: entry.path),
    };
  }
}
