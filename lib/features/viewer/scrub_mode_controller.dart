import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/settings/scrub_settings.dart';
import '../../data/settings/settings_store.dart';

part 'scrub_mode_controller.g.dart';

/// When on, [MediaView] plays a short window then jumps forward, repeating —
/// a fast skim of a video/audio file for triage. Toggled with a shortcut key.
@Riverpod(keepAlive: true)
class ScrubMode extends _$ScrubMode {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool on) => state = on;
}

/// The user-tunable [ScrubSettings]. Starts at [ScrubSettings.defaults], then
/// swaps in the persisted values once loaded; every change is written back.
@Riverpod(keepAlive: true)
class ScrubSettingsController extends _$ScrubSettingsController {
  @override
  ScrubSettings build() {
    _hydrate();
    return ScrubSettings.defaults;
  }

  Future<void> _hydrate() async {
    try {
      final loaded = await (await ref.read(settingsStoreProvider.future))
          .loadScrub();
      if (loaded != null) state = loaded;
    } catch (e, st) {
      developer.log('load scrub settings failed', error: e, stackTrace: st);
    }
  }

  Future<void> _update(ScrubSettings next) async {
    state = next.clamped();
    try {
      await (await ref.read(settingsStoreProvider.future)).saveScrub(state);
    } catch (e, st) {
      developer.log('save scrub settings failed', error: e, stackTrace: st);
    }
  }

  Future<void> setPlaySeconds(int seconds) =>
      _update(state.copyWith(playSeconds: seconds));

  Future<void> setSkipPercent(int percent) =>
      _update(state.copyWith(skipPercent: percent));

  Future<void> reset() => _update(ScrubSettings.defaults);
}
