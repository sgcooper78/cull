// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active [FileSource]. Desktop uses [IoFileSource]; tests override this.

@ProviderFor(fileSource)
final fileSourceProvider = FileSourceProvider._();

/// The active [FileSource]. Desktop uses [IoFileSource]; tests override this.

final class FileSourceProvider
    extends $FunctionalProvider<FileSource, FileSource, FileSource>
    with $Provider<FileSource> {
  /// The active [FileSource]. Desktop uses [IoFileSource]; tests override this.
  FileSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileSourceHash();

  @$internal
  @override
  $ProviderElement<FileSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileSource create(Ref ref) {
    return fileSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileSource>(value),
    );
  }
}

String _$fileSourceHash() => r'9b1dc9707b4a1b9f787e5ef46278e56e6c7bbd06';
