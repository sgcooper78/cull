import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/file_kind.dart';
import '../../../core/natural_sort.dart';
import '../comic_resume.dart';
import '../scrub_mode_controller.dart';
import '../viewer_key_handler.dart';

/// Page reader for `.cbz` (zip) and `.cbt` (tar) comics. `.cbr` (rar) and
/// `.cb7` (7z) can't be extracted in pure Dart — those show a message.
///
/// Left/Right and PageUp/PageDown turn pages; Home/End jump to first/last.
/// Those keys arrive through the app-global shortcuts via [ViewerKeyHandlers]
/// (registered in [initState], cleared in [dispose]) so they work without this
/// widget holding focus.
///
/// Remembers the last page viewed per comic (`comic_resume.dart`) and — like
/// [MediaView] for video/audio — reacts to the global [scrubModeProvider]:
/// while scrub mode is on, the current page is shown for
/// [ComicScrubSettings.dwell] seconds, then jumps forward
/// [ComicScrubSettings.pageSkip] pages, wrapping around at the end.
class ComicView extends ConsumerStatefulWidget {
  const ComicView({required this.path, super.key});

  final String path;

  @override
  ConsumerState<ComicView> createState() => _ComicViewState();
}

/// Top-level so it can run in an isolate via [compute] — parsing a `.cbz`/
/// `.cbt` and decompressing every page is CPU-bound enough to freeze the UI
/// thread for a large comic (same reasoning as [decodeImageToPng] in
/// `image_view.dart`). Pages come back as plain bytes rather than
/// [ArchiveFile]s because the latter aren't sendable across the isolate
/// boundary.
List<(String name, Uint8List bytes)> decodeComicPages((Uint8List, bool) args) {
  final (bytes, isTar) = args;
  final archive = isTar
      ? TarDecoder().decodeBytes(bytes)
      : ZipDecoder().decodeBytes(bytes);
  final pages = [
    for (final e in archive)
      if (e.isFile && fileKindOf(e.name) == FileKind.image)
        (e.name, Uint8List.fromList(e.readBytes() ?? const <int>[])),
  ]..sort((a, b) => naturalCompare(a.$1.toLowerCase(), b.$1.toLowerCase()));
  return pages;
}

/// Next page index when scrub mode jumps forward by [skip] pages, wrapping
/// around to the start once it runs past the end (mirrors the wrap-to-zero
/// behaviour `MediaView._onPosition` uses at the end of a file).
int nextScrubPageIndex({
  required int current,
  required int skip,
  required int length,
}) {
  if (length <= 0) return 0;
  return (current + skip) % length;
}

class _ComicViewState extends ConsumerState<ComicView> {
  static const _maxBytes = 400 << 20; // 400 MiB archive cap
  static const _saveDelay = Duration(milliseconds: 500);

  /// How long this comic has to stay selected before it's actually decoded.
  /// [ComicView] is remounted fresh per file (keyed by path at the call site
  /// in `viewer_panel.dart`), so unlike [MediaView]'s shared-key debounce,
  /// this just delays the call to [_load] inside one mount — stepping past
  /// several large `.cbz`/`.cbt` files quickly tears down each one (cancelling
  /// its pending timer in [dispose]) before it ever starts decompressing.
  static const _loadDelay = Duration(milliseconds: 150);

  List<_Page>? _pages;
  Object? _error;
  int _index = 0;
  Timer? _loadDebounce;
  Timer? _saveDebounce;
  Timer? _scrubTimer;

  @override
  void initState() {
    super.initState();
    _loadDebounce = Timer(_loadDelay, _load);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(viewerKeyHandlersProvider.notifier)
          .register(step: _step, jump: _jump);
    });
  }

  @override
  void dispose() {
    _loadDebounce?.cancel();
    _scrubTimer?.cancel();
    _saveDebounce?.cancel();
    final pages = _pages;
    if (pages != null && _error == null) {
      // Fire-and-forget: flush the current page immediately so a quick close
      // doesn't lose position waiting on the debounce.
      unawaited(rememberComicPage(ref, widget.path, pages[_index].name));
    }
    ref.read(viewerKeyHandlersProvider.notifier).clear();
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
      final decoded = await compute(decodeComicPages, (bytes, ext == '.cbt'));
      final pages = [for (final (name, data) in decoded) _Page(name, data)];

      if (pages.isEmpty) {
        throw const _ComicError('No image pages found in this archive.');
      }
      if (!mounted) return;

      var initialIndex = 0;
      final savedPage = await lastComicPage(ref, widget.path);
      if (savedPage != null) {
        final idx = pages.indexWhere((pg) => pg.name == savedPage);
        if (idx != -1) initialIndex = idx;
      }
      if (!mounted) return;

      setState(() {
        _pages = pages;
        _index = initialIndex;
      });
      // Honour scrub mode if it was already on when this comic opened.
      if (mounted && ref.read(scrubModeProvider)) _setScrub(true);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _step({required bool forward}) => _go(forward ? 1 : -1);

  void _jump({required bool toEnd}) {
    final pages = _pages;
    if (pages == null) return;
    final next = toEnd ? pages.length - 1 : 0;
    if (next != _index) {
      setState(() => _index = next);
      _scheduleSave();
    }
  }

  void _go(int delta) {
    final pages = _pages;
    if (pages == null) return;
    final next = (_index + delta).clamp(0, pages.length - 1);
    if (next != _index) {
      setState(() => _index = next);
      _scheduleSave();
    }
  }

  /// Debounce (like `MediaView`'s `_openDebounce`) so rapid page-turning
  /// doesn't hit the settings store on every keystroke — only the page the
  /// user settles on gets persisted.
  void _scheduleSave() {
    final pages = _pages;
    if (pages == null) return;
    final name = pages[_index].name;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDelay, () {
      unawaited(rememberComicPage(ref, widget.path, name));
    });
  }

  void _setScrub(bool on) {
    _scrubTimer?.cancel();
    _scrubTimer = null;
    if (!on || _pages == null || _error != null) return;
    final settings = ref.read(comicScrubSettingsControllerProvider);
    _scrubTimer = Timer.periodic(settings.dwell, (_) => _advanceScrub());
  }

  void _advanceScrub() {
    final pages = _pages;
    if (pages == null || pages.isEmpty) return;
    final settings = ref.read(comicScrubSettingsControllerProvider);
    final next = nextScrubPageIndex(
      current: _index,
      skip: settings.pageSkip,
      length: pages.length,
    );
    if (next != _index) {
      setState(() => _index = next);
      _scheduleSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scrubModeProvider, (_, on) => _setScrub(on));
    // Re-arm with the new dwell/skip if settings change while scrub is on.
    ref.listen(comicScrubSettingsControllerProvider, (_, _) {
      if (_scrubTimer != null) _setScrub(true);
    });

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

    return Stack(
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
    );
  }
}

class _Page {
  const _Page(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
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
