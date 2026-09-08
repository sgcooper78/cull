import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/settings/sort_settings.dart';
import '../sort_controller.dart';

enum _Action { name, size, modified, type, reverse, foldersFirst }

/// The sort control in the sidebar header. Pick a key (picking the active one
/// flips direction); toggle Descending and Folders-first.
class SortMenu extends ConsumerWidget {
  const SortMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sortSettingsControllerProvider);
    final c = ref.read(sortSettingsControllerProvider.notifier);

    PopupMenuItem<_Action> keyItem(_Action a, SortKey key) => PopupMenuItem(
      value: a,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: s.key == key
                ? Icon(
                    s.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                  )
                : null,
          ),
          Text(key.label),
        ],
      ),
    );

    PopupMenuItem<_Action> checkItem(_Action a, String label, bool on) =>
        PopupMenuItem(
          value: a,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: on ? const Icon(Icons.check, size: 16) : null,
              ),
              Text(label),
            ],
          ),
        );

    return PopupMenuButton<_Action>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort: ${s.key.label} ${s.ascending ? '↑' : '↓'}',
      onSelected: (a) => switch (a) {
        _Action.name => c.sortBy(SortKey.name),
        _Action.size => c.sortBy(SortKey.size),
        _Action.modified => c.sortBy(SortKey.modified),
        _Action.type => c.sortBy(SortKey.type),
        _Action.reverse => c.reverse(),
        _Action.foldersFirst => c.setFoldersFirst(!s.foldersFirst),
      },
      itemBuilder: (_) => [
        keyItem(_Action.name, SortKey.name),
        keyItem(_Action.size, SortKey.size),
        keyItem(_Action.modified, SortKey.modified),
        keyItem(_Action.type, SortKey.type),
        const PopupMenuDivider(),
        checkItem(_Action.reverse, 'Descending', !s.ascending),
        checkItem(_Action.foldersFirst, 'Folders first', s.foldersFirst),
      ],
    );
  }
}
