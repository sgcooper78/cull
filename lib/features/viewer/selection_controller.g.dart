// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The file open in the viewer pane, or null when nothing is selected.

@ProviderFor(Selection)
final selectionProvider = SelectionProvider._();

/// The file open in the viewer pane, or null when nothing is selected.
final class SelectionProvider extends $NotifierProvider<Selection, FsEntry?> {
  /// The file open in the viewer pane, or null when nothing is selected.
  SelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionHash();

  @$internal
  @override
  Selection create() => Selection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FsEntry? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FsEntry?>(value),
    );
  }
}

String _$selectionHash() => r'1fc25864ee1041a63af96460f2af8a01c7f5b5af';

/// The file open in the viewer pane, or null when nothing is selected.

abstract class _$Selection extends $Notifier<FsEntry?> {
  FsEntry? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FsEntry?, FsEntry?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FsEntry?, FsEntry?>,
              FsEntry?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
