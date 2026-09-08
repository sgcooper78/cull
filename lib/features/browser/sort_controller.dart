import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/settings/settings_store.dart';
import '../../data/settings/sort_settings.dart';

part 'sort_controller.g.dart';

/// How the directory tree is sorted. Starts at [SortSettings.defaults], swaps
/// in the persisted value once loaded, and writes every change back.
@Riverpod(keepAlive: true)
class SortSettingsController extends _$SortSettingsController {
  @override
  SortSettings build() {
    _hydrate();
    return SortSettings.defaults;
  }

  Future<void> _hydrate() async {
    try {
      final loaded = await (await ref.read(settingsStoreProvider.future))
          .loadSort();
      if (loaded != null) state = loaded;
    } catch (e, st) {
      developer.log('load sort settings failed', error: e, stackTrace: st);
    }
  }

  Future<void> _update(SortSettings next) async {
    state = next;
    try {
      await (await ref.read(settingsStoreProvider.future)).saveSort(state);
    } catch (e, st) {
      developer.log('save sort settings failed', error: e, stackTrace: st);
    }
  }

  /// Pick a sort key. Choosing the key that's already active flips direction.
  Future<void> sortBy(SortKey key) => _update(
    state.key == key
        ? state.copyWith(ascending: !state.ascending)
        : state.copyWith(key: key, ascending: true),
  );

  Future<void> setAscending(bool ascending) =>
      _update(state.copyWith(ascending: ascending));

  Future<void> setFoldersFirst(bool value) =>
      _update(state.copyWith(foldersFirst: value));

  Future<void> reverse() => setAscending(!state.ascending);
}
