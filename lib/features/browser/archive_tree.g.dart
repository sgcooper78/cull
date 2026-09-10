// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_tree.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Flat entry list of an on-disk archive, cached until invalidated (after a
/// repackage-on-delete). Throws [ArchiveListingException] on any failure.

@ProviderFor(archiveEntries)
final archiveEntriesProvider = ArchiveEntriesFamily._();

/// Flat entry list of an on-disk archive, cached until invalidated (after a
/// repackage-on-delete). Throws [ArchiveListingException] on any failure.

final class ArchiveEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ArchiveEntry>>,
          List<ArchiveEntry>,
          FutureOr<List<ArchiveEntry>>
        >
    with
        $FutureModifier<List<ArchiveEntry>>,
        $FutureProvider<List<ArchiveEntry>> {
  /// Flat entry list of an on-disk archive, cached until invalidated (after a
  /// repackage-on-delete). Throws [ArchiveListingException] on any failure.
  ArchiveEntriesProvider._({
    required ArchiveEntriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'archiveEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$archiveEntriesHash();

  @override
  String toString() {
    return r'archiveEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ArchiveEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ArchiveEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return archiveEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArchiveEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$archiveEntriesHash() => r'cc89ce5ca77500f96010400d6f77bccad54fec02';

/// Flat entry list of an on-disk archive, cached until invalidated (after a
/// repackage-on-delete). Throws [ArchiveListingException] on any failure.

final class ArchiveEntriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ArchiveEntry>>, String> {
  ArchiveEntriesFamily._()
    : super(
        retry: null,
        name: r'archiveEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Flat entry list of an on-disk archive, cached until invalidated (after a
  /// repackage-on-delete). Throws [ArchiveListingException] on any failure.

  ArchiveEntriesProvider call(String archivePath) =>
      ArchiveEntriesProvider._(argument: archivePath, from: this);

  @override
  String toString() => r'archiveEntriesProvider';
}

/// Direct children of a tree container that lives inside an archive.
/// [containerPath] is either the on-disk archive path (`C:\d\a.zip`) or an
/// archive-member directory (`C:\d\a.zip!/photos`). Children come back as
/// [FsEntry] with [archivePathSeparator] paths so the rest of the tree, the
/// selection, and the mark store treat them like any other row.

@ProviderFor(archiveChildren)
final archiveChildrenProvider = ArchiveChildrenFamily._();

/// Direct children of a tree container that lives inside an archive.
/// [containerPath] is either the on-disk archive path (`C:\d\a.zip`) or an
/// archive-member directory (`C:\d\a.zip!/photos`). Children come back as
/// [FsEntry] with [archivePathSeparator] paths so the rest of the tree, the
/// selection, and the mark store treat them like any other row.

final class ArchiveChildrenProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FsEntry>>,
          List<FsEntry>,
          FutureOr<List<FsEntry>>
        >
    with $FutureModifier<List<FsEntry>>, $FutureProvider<List<FsEntry>> {
  /// Direct children of a tree container that lives inside an archive.
  /// [containerPath] is either the on-disk archive path (`C:\d\a.zip`) or an
  /// archive-member directory (`C:\d\a.zip!/photos`). Children come back as
  /// [FsEntry] with [archivePathSeparator] paths so the rest of the tree, the
  /// selection, and the mark store treat them like any other row.
  ArchiveChildrenProvider._({
    required ArchiveChildrenFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'archiveChildrenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$archiveChildrenHash();

  @override
  String toString() {
    return r'archiveChildrenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FsEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FsEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return archiveChildren(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArchiveChildrenProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$archiveChildrenHash() => r'eda00ebd67ae45b0dbf02031916bce3dc05c4cbf';

/// Direct children of a tree container that lives inside an archive.
/// [containerPath] is either the on-disk archive path (`C:\d\a.zip`) or an
/// archive-member directory (`C:\d\a.zip!/photos`). Children come back as
/// [FsEntry] with [archivePathSeparator] paths so the rest of the tree, the
/// selection, and the mark store treat them like any other row.

final class ArchiveChildrenFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FsEntry>>, String> {
  ArchiveChildrenFamily._()
    : super(
        retry: null,
        name: r'archiveChildrenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Direct children of a tree container that lives inside an archive.
  /// [containerPath] is either the on-disk archive path (`C:\d\a.zip`) or an
  /// archive-member directory (`C:\d\a.zip!/photos`). Children come back as
  /// [FsEntry] with [archivePathSeparator] paths so the rest of the tree, the
  /// selection, and the mark store treat them like any other row.

  ArchiveChildrenProvider call(String containerPath) =>
      ArchiveChildrenProvider._(argument: containerPath, from: this);

  @override
  String toString() => r'archiveChildrenProvider';
}
