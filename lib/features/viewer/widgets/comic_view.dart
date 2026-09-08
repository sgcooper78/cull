import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../core/file_kind.dart';
import '../../../core/natural_sort.dart';

/// Page reader for `.cbz` (zip) and `.cbt` (tar) comics. `.cbr` (rar) and
/// `.cb7` (7z) can't be extracted in pure Dart — those show a message.
///
/// Left/Right or PageUp/PageDown turn pages; Home/End jump to first/last.
/// Non-navigation keys bubble up to the app's triage shortcuts.
class ComicView extends StatefulWidget {
  const ComicView({required this.path, super.key});

  final String path;

  @override
  State<ComicView> createState() => _ComicViewState();
}

class _ComicViewState extends State<ComicView> {
  static const _maxBytes = 400 << 20; // 400 MiB archive cap

  final FocusNode _focus = FocusNode();
  List<_Page>? _pages;
  Object? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ComicView old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      setState(() {
        _pages = null;
        _error = null;
        _index = 0;
      });
      _load();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ext = p.extension(widget.path).toLowerCase();
      if (!comicIsReadable(widget.path)) {
        throw _ComicError(
          '${ext.toUpperCase()} comics use RAR/7z, which cannot be '
          'extracted without an external tool. Convert to .cbz to read it '
          'here.',
        );
      }
      final file = File(widget.path);
      if (await file.length() > _maxBytes) {
        throw const _ComicError('Comic archive is larger than 400 MiB.');
      }
      final bytes = await file.readAsBytes();
      final archive = ext == '.cbt'
          ? TarDecoder().decodeBytes(bytes)
          : ZipDecoder().decodeBytes(bytes);

      final pages =
          [
            for (final e in archive)
              if (e.isFile && fileKindOf(e.name) == FileKind.image) _Page(e),
          ]..sort(
            (a, b) =>
                naturalCompare(a.name.toLowerCase(), b.name.toLowerCase()),
          );

      if (pages.isEmpty) {
        throw const _ComicError('No image pages found in this archive.');
      }
      if (!mounted) return;
      setState(() => _pages = pages);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _go(int delta) {
    final pages = _pages;
    if (pages == null) return;
    final next = (_index + delta).clamp(0, pages.length - 1);
    if (next != _index) setState(() => _index = next);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final pages = _pages;
    if (pages == null) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.pageDown:
        _go(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.pageUp:
        _go(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        setState(() => _index = 0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        setState(() => _index = pages.length - 1);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_error case final Object e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            e is _ComicError ? e.message : 'Could not open comic:\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final pages = _pages;
    if (pages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final page = pages[_index];

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: Image.memory(
                  page.bytes,
                  key: ValueKey(page.name),
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Text('Cannot decode ${page.name}'),
                ),
              ),
            ),
          ),
          _NavZone(alignment: Alignment.centerLeft, onTap: () => _go(-1)),
          _NavZone(alignment: Alignment.centerRight, onTap: () => _go(1)),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: _PageChip(index: _index, total: pages.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _Page {
  _Page(this._file);

  final ArchiveFile _file;
  Uint8List? _cache;

  String get name => _file.name;
  Uint8List get bytes =>
      _cache ??= Uint8List.fromList(_file.content as List<int>);
}

class _NavZone extends StatelessWidget {
  const _NavZone({required this.alignment, required this.onTap});

  final Alignment alignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.centerLeft;
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      width: 88,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Align(
            alignment: alignment,
            child: Icon(
              left ? Icons.chevron_left : Icons.chevron_right,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface
            .withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${index + 1} / $total',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onInverseSurface,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ComicError implements Exception {
  const _ComicError(this.message);
  final String message;
}
