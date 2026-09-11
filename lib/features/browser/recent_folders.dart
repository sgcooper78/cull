import 'dart:developer' as developer;

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/settings/settings_store.dart';

part 'recent_folders.g.dart';

/// How many recently opened root folders to remember.
const maxRecentFolders = 8;

/// Recently opened root folders, most-recent first. Starts empty, swaps in
/// the persisted list once loaded (same pattern as [SortSettingsController]),
/// and writes every change back.
@Riverpod(keepAlive: true)
class RecentFolders extends _$RecentFolders {
  /// Set the moment [record]/[remove] first runs. Loading is async, so a call
  /// to either can land before it resolves; without this, the late hydration
  /// result would overwrite an already-applied, already-persisted change with
  /// the stale value that was on disk before it.
  bool _mutated = false;

  @override
  List<String> build() {
    _hydrate();
    return const [];
  }

  Future<void> _hydrate() async {
    try {
      final loaded = await (await ref.read(settingsStoreProvider.future))
          .loadRecentFolders();
      if (!_mutated) state = loaded;
    } catch (e, st) {
      developer.log('load recent folders failed', error: e, stackTrace: st);
    }
  }

  Future<void> _persist() async {
    try {
      final store = await ref.read(settingsStoreProvider.future);
      await store.saveRecentFolders(state);
    } catch (e, st) {
      developer.log('save recent folders failed', error: e, stackTrace: st);
    }
  }

  /// Move [path] to the front, deduplicating and capping the list at
  /// [maxRecentFolders]. Call whenever a folder is opened as the tree root.
  Future<void> record(String path) async {
    _mutated = true;
    final normalized = p.normalize(path);
    state = [
      normalized,
      for (final existing in state)
        if (!p.equals(existing, normalized)) existing,
    ].take(maxRecentFolders).toList();
    await _persist();
  }

  /// Drop [path] from the list — e.g. the user noticed it no longer exists.
  Future<void> remove(String path) async {
    _mutated = true;
    final next = [
      for (final existing in state)
        if (!p.equals(existing, path)) existing,
    ];
    if (next.length == state.length) return;
    state = next;
    await _persist();
  }
}
