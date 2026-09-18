// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scrub_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When on, [MediaView]/[ComicView] skim the current file — media plays a
/// short window then jumps forward, comics show a page then jump forward —
/// repeating for a fast triage skim. One global switch, toggled with a
/// shortcut key; each viewer reacts to it according to its own kind.

@ProviderFor(ScrubMode)
final scrubModeProvider = ScrubModeProvider._();

/// When on, [MediaView]/[ComicView] skim the current file — media plays a
/// short window then jumps forward, comics show a page then jump forward —
/// repeating for a fast triage skim. One global switch, toggled with a
/// shortcut key; each viewer reacts to it according to its own kind.
final class ScrubModeProvider extends $NotifierProvider<ScrubMode, bool> {
  /// When on, [MediaView]/[ComicView] skim the current file — media plays a
  /// short window then jumps forward, comics show a page then jump forward —
  /// repeating for a fast triage skim. One global switch, toggled with a
  /// shortcut key; each viewer reacts to it according to its own kind.
  ScrubModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scrubModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scrubModeHash();

  @$internal
  @override
  ScrubMode create() => ScrubMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$scrubModeHash() => r'990493bcb8703e099e5f5f5d6a8e46533dc6af3a';

/// When on, [MediaView]/[ComicView] skim the current file — media plays a
/// short window then jumps forward, comics show a page then jump forward —
/// repeating for a fast triage skim. One global switch, toggled with a
/// shortcut key; each viewer reacts to it according to its own kind.

abstract class _$ScrubMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The user-tunable [MediaScrubSettings] (video/audio). Starts at
/// [MediaScrubSettings.defaults], then swaps in the persisted values once
/// loaded; every change is written back.

@ProviderFor(MediaScrubSettingsController)
final mediaScrubSettingsControllerProvider =
    MediaScrubSettingsControllerProvider._();

/// The user-tunable [MediaScrubSettings] (video/audio). Starts at
/// [MediaScrubSettings.defaults], then swaps in the persisted values once
/// loaded; every change is written back.
final class MediaScrubSettingsControllerProvider
    extends
        $NotifierProvider<MediaScrubSettingsController, MediaScrubSettings> {
  /// The user-tunable [MediaScrubSettings] (video/audio). Starts at
  /// [MediaScrubSettings.defaults], then swaps in the persisted values once
  /// loaded; every change is written back.
  MediaScrubSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaScrubSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaScrubSettingsControllerHash();

  @$internal
  @override
  MediaScrubSettingsController create() => MediaScrubSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaScrubSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaScrubSettings>(value),
    );
  }
}

String _$mediaScrubSettingsControllerHash() =>
    r'bb499347756194cb2e5f6cf3d11c0f05f11852a5';

/// The user-tunable [MediaScrubSettings] (video/audio). Starts at
/// [MediaScrubSettings.defaults], then swaps in the persisted values once
/// loaded; every change is written back.

abstract class _$MediaScrubSettingsController
    extends $Notifier<MediaScrubSettings> {
  MediaScrubSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MediaScrubSettings, MediaScrubSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MediaScrubSettings, MediaScrubSettings>,
              MediaScrubSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The user-tunable [ComicScrubSettings] (`.cbz`/`.cbt` page reader). Same
/// hydrate-then-persist pattern as [MediaScrubSettingsController].

@ProviderFor(ComicScrubSettingsController)
final comicScrubSettingsControllerProvider =
    ComicScrubSettingsControllerProvider._();

/// The user-tunable [ComicScrubSettings] (`.cbz`/`.cbt` page reader). Same
/// hydrate-then-persist pattern as [MediaScrubSettingsController].
final class ComicScrubSettingsControllerProvider
    extends
        $NotifierProvider<ComicScrubSettingsController, ComicScrubSettings> {
  /// The user-tunable [ComicScrubSettings] (`.cbz`/`.cbt` page reader). Same
  /// hydrate-then-persist pattern as [MediaScrubSettingsController].
  ComicScrubSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comicScrubSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comicScrubSettingsControllerHash();

  @$internal
  @override
  ComicScrubSettingsController create() => ComicScrubSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComicScrubSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComicScrubSettings>(value),
    );
  }
}

String _$comicScrubSettingsControllerHash() =>
    r'e153ddd98ca15983afea2434fb31264cd879fc8c';

/// The user-tunable [ComicScrubSettings] (`.cbz`/`.cbt` page reader). Same
/// hydrate-then-persist pattern as [MediaScrubSettingsController].

abstract class _$ComicScrubSettingsController
    extends $Notifier<ComicScrubSettings> {
  ComicScrubSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ComicScrubSettings, ComicScrubSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ComicScrubSettings, ComicScrubSettings>,
              ComicScrubSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
