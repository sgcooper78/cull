// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active [ArchiveReader]. Tests override with an in-memory fake.

@ProviderFor(archiveReader)
final archiveReaderProvider = ArchiveReaderProvider._();

/// The active [ArchiveReader]. Tests override with an in-memory fake.

final class ArchiveReaderProvider
    extends $FunctionalProvider<ArchiveReader, ArchiveReader, ArchiveReader>
    with $Provider<ArchiveReader> {
  /// The active [ArchiveReader]. Tests override with an in-memory fake.
  ArchiveReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveReaderHash();

  @$internal
  @override
  $ProviderElement<ArchiveReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveReader create(Ref ref) {
    return archiveReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveReader>(value),
    );
  }
}

String _$archiveReaderHash() => r'aeb9ecd20616d956be61b31bd8023590d24595aa';

/// The active [ArchiveWriter] for repackage-on-delete.

@ProviderFor(archiveWriter)
final archiveWriterProvider = ArchiveWriterProvider._();

/// The active [ArchiveWriter] for repackage-on-delete.

final class ArchiveWriterProvider
    extends $FunctionalProvider<ArchiveWriter, ArchiveWriter, ArchiveWriter>
    with $Provider<ArchiveWriter> {
  /// The active [ArchiveWriter] for repackage-on-delete.
  ArchiveWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveWriterHash();

  @$internal
  @override
  $ProviderElement<ArchiveWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveWriter create(Ref ref) {
    return archiveWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveWriter>(value),
    );
  }
}

String _$archiveWriterHash() => r'7aa232e0e8e5965375f6af02e7cf8173c2c151af';
