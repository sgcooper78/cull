// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scrub_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// When on, [MediaView] plays a short window then jumps forward, repeating —
/// a fast skim of a video/audio file for triage. Toggled with a shortcut key.

@ProviderFor(ScrubMode)
final scrubModeProvider = ScrubModeProvider._();

/// When on, [MediaView] plays a short window then jumps forward, repeating —
/// a fast skim of a video/audio file for triage. Toggled with a shortcut key.
final class ScrubModeProvider extends $NotifierProvider<ScrubMode, bool> {
  /// When on, [MediaView] plays a short window then jumps forward, repeating —
  /// a fast skim of a video/audio file for triage. Toggled with a shortcut key.
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

/// When on, [MediaView] plays a short window then jumps forward, repeating —
/// a fast skim of a video/audio file for triage. Toggled with a shortcut key.

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

/// The user-tunable [ScrubSettings]. Starts at [ScrubSettings.defaults], then
/// swaps in the persisted values once loaded; every change is written back.

@ProviderFor(ScrubSettingsController)
final scrubSettingsControllerProvider = ScrubSettingsControllerProvider._();

/// The user-tunable [ScrubSettings]. Starts at [ScrubSettings.defaults], then
/// swaps in the persisted values once loaded; every change is written back.
final class ScrubSettingsControllerProvider
    extends $NotifierProvider<ScrubSettingsController, ScrubSettings> {
  /// The user-tunable [ScrubSettings]. Starts at [ScrubSettings.defaults], then
  /// swaps in the persisted values once loaded; every change is written back.
  ScrubSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scrubSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scrubSettingsControllerHash();

  @$internal
  @override
  ScrubSettingsController create() => ScrubSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScrubSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScrubSettings>(value),
    );
  }
}

String _$scrubSettingsControllerHash() =>
    r'ef06501c0b9f3b771fd3eb7228a5bc354a39a7fc';

/// The user-tunable [ScrubSettings]. Starts at [ScrubSettings.defaults], then
/// swaps in the persisted values once loaded; every change is written back.

abstract class _$ScrubSettingsController extends $Notifier<ScrubSettings> {
  ScrubSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScrubSettings, ScrubSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScrubSettings, ScrubSettings>,
              ScrubSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
