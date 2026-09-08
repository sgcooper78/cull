// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tree_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Absolute paths of the directories currently expanded in the tree.

@ProviderFor(TreeExpansion)
final treeExpansionProvider = TreeExpansionProvider._();

/// Absolute paths of the directories currently expanded in the tree.
final class TreeExpansionProvider
    extends $NotifierProvider<TreeExpansion, Set<String>> {
  /// Absolute paths of the directories currently expanded in the tree.
  TreeExpansionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'treeExpansionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$treeExpansionHash();

  @$internal
  @override
  TreeExpansion create() => TreeExpansion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$treeExpansionHash() => r'e26a5c333dfc14ed826fa05d54e0ae6a43c51c7c';

/// Absolute paths of the directories currently expanded in the tree.

abstract class _$TreeExpansion extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The visible tree, flattened depth-first for a `ListView.builder`. Rebuilds
/// when the root, the expansion set, or any expanded folder's listing changes.

@ProviderFor(treeRows)
final treeRowsProvider = TreeRowsProvider._();

/// The visible tree, flattened depth-first for a `ListView.builder`. Rebuilds
/// when the root, the expansion set, or any expanded folder's listing changes.

final class TreeRowsProvider
    extends $FunctionalProvider<List<TreeRow>, List<TreeRow>, List<TreeRow>>
    with $Provider<List<TreeRow>> {
  /// The visible tree, flattened depth-first for a `ListView.builder`. Rebuilds
  /// when the root, the expansion set, or any expanded folder's listing changes.
  TreeRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'treeRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$treeRowsHash();

  @$internal
  @override
  $ProviderElement<List<TreeRow>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<TreeRow> create(Ref ref) {
    return treeRows(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TreeRow> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TreeRow>>(value),
    );
  }
}

String _$treeRowsHash() => r'b2f9ef7244705075f430b3b0316b6631c58fe16b';
