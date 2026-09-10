// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewer_key_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ViewerKeyHandlers)
final viewerKeyHandlersProvider = ViewerKeyHandlersProvider._();

final class ViewerKeyHandlersProvider
    extends $NotifierProvider<ViewerKeyHandlers, ViewerKeyBinding> {
  ViewerKeyHandlersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerKeyHandlersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerKeyHandlersHash();

  @$internal
  @override
  ViewerKeyHandlers create() => ViewerKeyHandlers();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ViewerKeyBinding value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ViewerKeyBinding>(value),
    );
  }
}

String _$viewerKeyHandlersHash() => r'96c896262df644290db3e8f0f51dd00d10e8476a';

abstract class _$ViewerKeyHandlers extends $Notifier<ViewerKeyBinding> {
  ViewerKeyBinding build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ViewerKeyBinding, ViewerKeyBinding>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ViewerKeyBinding, ViewerKeyBinding>,
              ViewerKeyBinding,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
