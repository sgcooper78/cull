// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active [SettingsStore]. Tests override this with an in-memory one.

@ProviderFor(settingsStore)
final settingsStoreProvider = SettingsStoreProvider._();

/// The active [SettingsStore]. Tests override this with an in-memory one.

final class SettingsStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<SettingsStore>,
          SettingsStore,
          FutureOr<SettingsStore>
        >
    with $FutureModifier<SettingsStore>, $FutureProvider<SettingsStore> {
  /// The active [SettingsStore]. Tests override this with an in-memory one.
  SettingsStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStoreHash();

  @$internal
  @override
  $FutureProviderElement<SettingsStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SettingsStore> create(Ref ref) {
    return settingsStore(ref);
  }
}

String _$settingsStoreHash() => r'0f7ad8104a1da96b70d40c7fc6fc8d49626307a2';
