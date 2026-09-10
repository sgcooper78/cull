// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marks_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Overridable so tests can inject an in-memory store.

@ProviderFor(markStore)
final markStoreProvider = MarkStoreProvider._();

/// Overridable so tests can inject an in-memory store.

final class MarkStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<MarkStore>,
          MarkStore,
          FutureOr<MarkStore>
        >
    with $FutureModifier<MarkStore>, $FutureProvider<MarkStore> {
  /// Overridable so tests can inject an in-memory store.
  MarkStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markStoreHash();

  @$internal
  @override
  $FutureProviderElement<MarkStore> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MarkStore> create(Ref ref) {
    return markStore(ref);
  }
}

String _$markStoreHash() => r'470e2ed496e37c6ed1b4dc0e76e4e95c8da71b0a';

/// Source of truth for triage marks. `safe` is implicit (absent from the map).

@ProviderFor(MarksController)
final marksControllerProvider = MarksControllerProvider._();

/// Source of truth for triage marks. `safe` is implicit (absent from the map).
final class MarksControllerProvider
    extends $AsyncNotifierProvider<MarksController, Map<String, Mark>> {
  /// Source of truth for triage marks. `safe` is implicit (absent from the map).
  MarksControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marksControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marksControllerHash();

  @$internal
  @override
  MarksController create() => MarksController();
}

String _$marksControllerHash() => r'34f2f0ce56c2441a75ef9fc1b255379cdb3b57c4';

/// Source of truth for triage marks. `safe` is implicit (absent from the map).

abstract class _$MarksController extends $AsyncNotifier<Map<String, Mark>> {
  FutureOr<Map<String, Mark>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, Mark>>, Map<String, Mark>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, Mark>>, Map<String, Mark>>,
              AsyncValue<Map<String, Mark>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
