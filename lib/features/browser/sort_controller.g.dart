// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sort_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the directory tree is sorted. Starts at [SortSettings.defaults], swaps
/// in the persisted value once loaded, and writes every change back.

@ProviderFor(SortSettingsController)
final sortSettingsControllerProvider = SortSettingsControllerProvider._();

/// How the directory tree is sorted. Starts at [SortSettings.defaults], swaps
/// in the persisted value once loaded, and writes every change back.
final class SortSettingsControllerProvider
    extends $NotifierProvider<SortSettingsController, SortSettings> {
  /// How the directory tree is sorted. Starts at [SortSettings.defaults], swaps
  /// in the persisted value once loaded, and writes every change back.
  SortSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sortSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sortSettingsControllerHash();

  @$internal
  @override
  SortSettingsController create() => SortSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SortSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SortSettings>(value),
    );
  }
}

String _$sortSettingsControllerHash() =>
    r'789ba98643491b551dd8657ac7306132a18888bd';

/// How the directory tree is sorted. Starts at [SortSettings.defaults], swaps
/// in the persisted value once loaded, and writes every change back.

abstract class _$SortSettingsController extends $Notifier<SortSettings> {
  SortSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SortSettings, SortSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SortSettings, SortSettings>,
              SortSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
