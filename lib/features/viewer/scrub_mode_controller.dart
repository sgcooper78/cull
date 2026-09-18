import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/settings/scrub_settings.dart';
import '../../data/settings/settings_store.dart';

part 'scrub_mode_controller.g.dart';

/// When on, [MediaView]/[ComicView] skim the current file — media plays a
/// short window then jumps forward, comics show a page then jump forward —
/// repeating for a fast triage skim. One global switch, toggled with a
/// shortcut key; each viewer reacts to it according to its own kind.
@Riverpod(keepAlive: true)
class ScrubMode extends _$ScrubMode {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool on) => state = on;
}

/// The user-tunable [MediaScrubSettings] (video/audio). Starts at
/// [MediaScrubSettings.defaults], then swaps in the persisted values once
/// loaded; every change is written back.
@Riverpod(keepAlive: true)
class MediaScrubSettingsController extends _$MediaScrubSettingsController {
  @override
  MediaScrubSettings build() {
    _hydrate();
    return MediaScrubSettings.defaults;
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

  Future<void> _update(MediaScrubSettings next) async {
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

  Future<void> reset() => _update(MediaScrubSettings.defaults);
}

/// The user-tunable [ComicScrubSettings] (`.cbz`/`.cbt` page reader). Same
/// hydrate-then-persist pattern as [MediaScrubSettingsController].
@Riverpod(keepAlive: true)
class ComicScrubSettingsController extends _$ComicScrubSettingsController {
  @override
  ComicScrubSettings build() {
    _hydrate();
    return ComicScrubSettings.defaults;
  }

  Future<void> _hydrate() async {
    try {
      final loaded = await (await ref.read(settingsStoreProvider.future))
          .loadComicScrub();
      if (loaded != null) state = loaded;
    } catch (e, st) {
      developer.log(
        'load comic scrub settings failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _update(ComicScrubSettings next) async {
    state = next.clamped();
    try {
      await (await ref.read(
        settingsStoreProvider.future,
      )).saveComicScrub(state);
    } catch (e, st) {
      developer.log(
        'save comic scrub settings failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> setPageSeconds(int seconds) =>
      _update(state.copyWith(pageSeconds: seconds));

  Future<void> setPageSkip(int pages) =>
      _update(state.copyWith(pageSkip: pages));

  Future<void> reset() => _update(ComicScrubSettings.defaults);
}
