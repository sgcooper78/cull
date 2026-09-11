// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browse_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The root directory the tree is showing. Null until the user opens one.

@ProviderFor(Browse)
final browseProvider = BrowseProvider._();

/// The root directory the tree is showing. Null until the user opens one.
final class BrowseProvider extends $NotifierProvider<Browse, String?> {
  /// The root directory the tree is showing. Null until the user opens one.
  BrowseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseHash();

  @$internal
  @override
  Browse create() => Browse();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$browseHash() => r'e740941e11ecf418a360cbcac8e584cbe0a76681';

/// The root directory the tree is showing. Null until the user opens one.

abstract class _$Browse extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Live contents of [dirPath]: an initial listing plus a refresh whenever the
/// OS reports a change in that folder. One instance per expanded tree node.

@ProviderFor(directoryListing)
final directoryListingProvider = DirectoryListingFamily._();

/// Live contents of [dirPath]: an initial listing plus a refresh whenever the
/// OS reports a change in that folder. One instance per expanded tree node.

final class DirectoryListingProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FsEntry>>,
          List<FsEntry>,
          Stream<List<FsEntry>>
        >
    with $FutureModifier<List<FsEntry>>, $StreamProvider<List<FsEntry>> {
  /// Live contents of [dirPath]: an initial listing plus a refresh whenever the
  /// OS reports a change in that folder. One instance per expanded tree node.
  DirectoryListingProvider._({
    required DirectoryListingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'directoryListingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$directoryListingHash();

  @override
  String toString() {
    return r'directoryListingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<FsEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FsEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return directoryListing(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DirectoryListingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$directoryListingHash() => r'e57c992fbdb21e32e77bf466387a83fc64a79c36';

/// Live contents of [dirPath]: an initial listing plus a refresh whenever the
/// OS reports a change in that folder. One instance per expanded tree node.

final class DirectoryListingFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<FsEntry>>, String> {
  DirectoryListingFamily._()
    : super(
        retry: null,
        name: r'directoryListingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live contents of [dirPath]: an initial listing plus a refresh whenever the
  /// OS reports a change in that folder. One instance per expanded tree node.

  DirectoryListingProvider call(String dirPath) =>
      DirectoryListingProvider._(argument: dirPath, from: this);

  @override
  String toString() => r'directoryListingProvider';
}
