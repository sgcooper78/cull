import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/marks/mark.dart';
import '../data/marks/marks_controller.dart';
import '../features/browser/browse_controller.dart';
import '../features/browser/browser_panel.dart';
import '../features/browser/resume.dart';
import '../features/triage/delete_marked.dart';
import '../features/triage/triage_actions.dart';
import '../features/viewer/scrub_mode_controller.dart';
import '../features/viewer/selection_controller.dart';
import '../features/viewer/viewer_panel.dart';
import '../features/viewer/widgets/scrub_settings_dialog.dart';

/// Cmd on macOS, Ctrl on Windows/Linux — the platform-native menu modifier.
SingleActivator _menuKey(LogicalKeyboardKey key, {bool shift = false}) {
  final mac = defaultTargetPlatform == TargetPlatform.macOS;
  return SingleActivator(key, control: !mac, meta: mac, shift: shift);
}

/// The whole window: menu bar on top, directory sidebar left, viewer right.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const path = '/';

  Future<void> _openDirectory(WidgetRef ref) async {
    final dir = await getDirectoryPath();
    if (dir == null) return;
    ref.read(selectionProvider.notifier).clear();
    ref.read(browseProvider.notifier).openRoot(dir);
  }

  void _markAll(WidgetRef ref, Mark mark) {
    final root = ref.read(browseProvider);
    if (root == null) return;
    ref.read(marksControllerProvider.notifier).markAllUnder(root, mark);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRoot = ref.watch(browseProvider) != null;
    final scrubOn = ref.watch(scrubModeProvider);

    // Resume: jump back to the last file when a directory is (re)opened, and
    // record the current file as we move through it.
    ref.listen(browseProvider, (prev, next) {
      if (next != null && next != prev) restoreResume(ref, next);
    });
    ref.listen(selectionProvider, (prev, next) {
      final root = ref.read(browseProvider);
      if (root != null && next != null && !next.isDirectory) {
        rememberResume(ref, root, next.path);
      }
    });

    return CallbackShortcuts(
      bindings: {
        _menuKey(LogicalKeyboardKey.keyO): () => _openDirectory(ref),
        _menuKey(LogicalKeyboardKey.keyD, shift: true): () =>
            runDeleteMarked(context, ref),
        // Triage flow — mark the viewed file and step to the next one.
        const SingleActivator(LogicalKeyboardKey.keyD): () =>
            markCurrentAndAdvance(ref, Mark.delete),
        const SingleActivator(LogicalKeyboardKey.keyS): () =>
            markCurrentAndAdvance(ref, Mark.safe),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            advanceSelection(ref),
        const SingleActivator(LogicalKeyboardKey.keyV): () =>
            ref.read(scrubModeProvider.notifier).toggle(),
        // Up/Down walk every tree row (files and folders); Left/Right and
        // PageUp/PageDown drive the viewer (comic pages, video seek) or
        // expand/collapse a selected folder; Home/End jump within the viewer.
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            moveSelection(ref, 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            moveSelection(ref, -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            stepViewer(ref, forward: true),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            stepViewer(ref, forward: false),
        const SingleActivator(LogicalKeyboardKey.pageDown): () =>
            stepViewer(ref, forward: true),
        const SingleActivator(LogicalKeyboardKey.pageUp): () =>
            stepViewer(ref, forward: false),
        const SingleActivator(LogicalKeyboardKey.home): () =>
            jumpViewer(ref, toEnd: false),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            jumpViewer(ref, toEnd: true),
        const SingleActivator(LogicalKeyboardKey.space): () =>
            togglePlayback(ref),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              _MenuBar(
                hasRoot: hasRoot,
                scrubOn: scrubOn,
                onOpen: () => _openDirectory(ref),
                onDeleteMarked: () => runDeleteMarked(context, ref),
                onMarkAllDelete: () => _markAll(ref, Mark.delete),
                onMarkAllSafe: () => _markAll(ref, Mark.safe),
                onMarkCurrentDelete: () =>
                    markCurrentAndAdvance(ref, Mark.delete),
                onMarkCurrentSafe: () => markCurrentAndAdvance(ref, Mark.safe),
                onNext: () => advanceSelection(ref),
                onPrevItem: () => moveSelection(ref, -1),
                onNextItem: () => moveSelection(ref, 1),
                onToggleScrub: () =>
                    ref.read(scrubModeProvider.notifier).toggle(),
                onScrubSettings: () => showScrubSettingsDialog(context),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 340, child: BrowserPanel()),
                    const VerticalDivider(width: 1),
                    const Expanded(child: ViewerPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  const _MenuBar({
    required this.hasRoot,
    required this.scrubOn,
    required this.onOpen,
    required this.onDeleteMarked,
    required this.onMarkAllDelete,
    required this.onMarkAllSafe,
    required this.onMarkCurrentDelete,
    required this.onMarkCurrentSafe,
    required this.onNext,
    required this.onPrevItem,
    required this.onNextItem,
    required this.onToggleScrub,
    required this.onScrubSettings,
  });

  final bool hasRoot;
  final bool scrubOn;
  final VoidCallback onOpen;
  final VoidCallback onDeleteMarked;
  final VoidCallback onMarkAllDelete;
  final VoidCallback onMarkAllSafe;
  final VoidCallback onMarkCurrentDelete;
  final VoidCallback onMarkCurrentSafe;
  final VoidCallback onNext;
  final VoidCallback onPrevItem;
  final VoidCallback onNextItem;
  final VoidCallback onToggleScrub;
  final VoidCallback onScrubSettings;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MenuBar(
        style: const MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(0),
        ),
        children: [
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                shortcut: _menuKey(LogicalKeyboardKey.keyO),
                onPressed: onOpen,
                child: const Text('Open Directory…'),
              ),
              MenuItemButton(
                shortcut: _menuKey(LogicalKeyboardKey.keyD, shift: true),
                onPressed: hasRoot ? onDeleteMarked : null,
                child: const Text('Delete marked files…'),
              ),
            ],
            child: const Text('File'),
          ),
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                shortcut: const SingleActivator(LogicalKeyboardKey.keyD),
                onPressed: hasRoot ? onMarkCurrentDelete : null,
                child: const Text('Mark viewed file — Delete, then next'),
              ),
              MenuItemButton(
                shortcut: const SingleActivator(LogicalKeyboardKey.keyS),
                onPressed: hasRoot ? onMarkCurrentSafe : null,
                child: const Text('Mark viewed file — Keep, then next'),
              ),
              const Divider(height: 1),
              MenuItemButton(
                onPressed: hasRoot ? onMarkAllDelete : null,
                child: const Text('Mark whole tree — Delete'),
              ),
              MenuItemButton(
                onPressed: hasRoot ? onMarkAllSafe : null,
                child: const Text('Mark whole tree — Safe'),
              ),
            ],
            child: const Text('Mark'),
          ),
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                shortcut: const SingleActivator(LogicalKeyboardKey.arrowUp),
                onPressed: hasRoot ? onPrevItem : null,
                child: const Text('Previous item'),
              ),
              MenuItemButton(
                shortcut: const SingleActivator(LogicalKeyboardKey.arrowDown),
                onPressed: hasRoot ? onNextItem : null,
                child: const Text('Next item'),
              ),
              MenuItemButton(
                shortcut: const SingleActivator(LogicalKeyboardKey.enter),
                onPressed: hasRoot ? onNext : null,
                child: const Text('Next file (skip folders)'),
              ),
              MenuItemButton(
                leadingIcon: Icon(
                  scrubOn ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                ),
                shortcut: const SingleActivator(LogicalKeyboardKey.keyV),
                onPressed: onToggleScrub,
                child: const Text('Scrub mode (video/audio skim)'),
              ),
              MenuItemButton(
                onPressed: onScrubSettings,
                child: const Text('Scrub settings…'),
              ),
            ],
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
