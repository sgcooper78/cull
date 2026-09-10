// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_stats.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recomputes whenever the marks change. A per-path metadata cache keeps the
/// cost to one `stat` per file for its lifetime, so repeated re-marking stays
/// cheap.

@ProviderFor(DeletionStatsController)
final deletionStatsControllerProvider = DeletionStatsControllerProvider._();

/// Recomputes whenever the marks change. A per-path metadata cache keeps the
/// cost to one `stat` per file for its lifetime, so repeated re-marking stays
/// cheap.
final class DeletionStatsControllerProvider
    extends $AsyncNotifierProvider<DeletionStatsController, DeletionStats> {
  /// Recomputes whenever the marks change. A per-path metadata cache keeps the
  /// cost to one `stat` per file for its lifetime, so repeated re-marking stays
  /// cheap.
  DeletionStatsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletionStatsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletionStatsControllerHash();

  @$internal
  @override
  DeletionStatsController create() => DeletionStatsController();
}

String _$deletionStatsControllerHash() =>
    r'080287aeb19152265dd9a949d016107b96d49299';

/// Recomputes whenever the marks change. A per-path metadata cache keeps the
/// cost to one `stat` per file for its lifetime, so repeated re-marking stays
/// cheap.

abstract class _$DeletionStatsController extends $AsyncNotifier<DeletionStats> {
  FutureOr<DeletionStats> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DeletionStats>, DeletionStats>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DeletionStats>, DeletionStats>,
              AsyncValue<DeletionStats>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
