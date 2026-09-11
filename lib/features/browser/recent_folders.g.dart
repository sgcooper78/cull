// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_folders.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recently opened root folders, most-recent first. Starts empty, swaps in
/// the persisted list once loaded (same pattern as [SortSettingsController]),
/// and writes every change back.

@ProviderFor(RecentFolders)
final recentFoldersProvider = RecentFoldersProvider._();

/// Recently opened root folders, most-recent first. Starts empty, swaps in
/// the persisted list once loaded (same pattern as [SortSettingsController]),
/// and writes every change back.
final class RecentFoldersProvider
    extends $NotifierProvider<RecentFolders, List<String>> {
  /// Recently opened root folders, most-recent first. Starts empty, swaps in
  /// the persisted list once loaded (same pattern as [SortSettingsController]),
  /// and writes every change back.
  RecentFoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentFoldersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentFoldersHash();

  @$internal
  @override
  RecentFolders create() => RecentFolders();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$recentFoldersHash() => r'77b9016ed742b72f0c2ac765d7248b2add598fcc';

/// Recently opened root folders, most-recent first. Starts empty, swaps in
/// the persisted list once loaded (same pattern as [SortSettingsController]),
/// and writes every change back.

abstract class _$RecentFolders extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
