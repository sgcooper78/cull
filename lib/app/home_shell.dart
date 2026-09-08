import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/marks/mark.dart';
import '../data/marks/marks_controller.dart';
import '../features/browser/browse_controller.dart';
import '../features/browser/browser_panel.dart';
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
                shortcut: const SingleActivator(LogicalKeyboardKey.enter),
                onPressed: hasRoot ? onNext : null,
                child: const Text('Next file'),
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
