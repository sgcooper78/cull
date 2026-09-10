// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_entry_file.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Extracts one archive entry ([virtualPath] carries the `!/` separator) to a
/// file in the OS temp area and returns that real path, so the existing
/// path-based viewers (image / media / pdf / text / hex) can open it
/// unchanged. Cached per entry; a giant archive browsed page by page grows the
/// cache — eviction is a TODO, same as `data/thumbs`.

@ProviderFor(archiveEntryFile)
final archiveEntryFileProvider = ArchiveEntryFileFamily._();

/// Extracts one archive entry ([virtualPath] carries the `!/` separator) to a
/// file in the OS temp area and returns that real path, so the existing
/// path-based viewers (image / media / pdf / text / hex) can open it
/// unchanged. Cached per entry; a giant archive browsed page by page grows the
/// cache — eviction is a TODO, same as `data/thumbs`.

final class ArchiveEntryFileProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Extracts one archive entry ([virtualPath] carries the `!/` separator) to a
  /// file in the OS temp area and returns that real path, so the existing
  /// path-based viewers (image / media / pdf / text / hex) can open it
  /// unchanged. Cached per entry; a giant archive browsed page by page grows the
  /// cache — eviction is a TODO, same as `data/thumbs`.
  ArchiveEntryFileProvider._({
    required ArchiveEntryFileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'archiveEntryFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$archiveEntryFileHash();

  @override
  String toString() {
    return r'archiveEntryFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return archiveEntryFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArchiveEntryFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$archiveEntryFileHash() => r'd548622e1b672f531887a630108fd5d298e97df0';

/// Extracts one archive entry ([virtualPath] carries the `!/` separator) to a
/// file in the OS temp area and returns that real path, so the existing
/// path-based viewers (image / media / pdf / text / hex) can open it
/// unchanged. Cached per entry; a giant archive browsed page by page grows the
/// cache — eviction is a TODO, same as `data/thumbs`.

final class ArchiveEntryFileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  ArchiveEntryFileFamily._()
    : super(
        retry: null,
        name: r'archiveEntryFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Extracts one archive entry ([virtualPath] carries the `!/` separator) to a
  /// file in the OS temp area and returns that real path, so the existing
  /// path-based viewers (image / media / pdf / text / hex) can open it
  /// unchanged. Cached per entry; a giant archive browsed page by page grows the
  /// cache — eviction is a TODO, same as `data/thumbs`.

  ArchiveEntryFileProvider call(String virtualPath) =>
      ArchiveEntryFileProvider._(argument: virtualPath, from: this);

  @override
  String toString() => r'archiveEntryFileProvider';
}
