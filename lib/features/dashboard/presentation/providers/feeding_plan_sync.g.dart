// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_plan_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedingPlanSync)
final feedingPlanSyncProvider = FeedingPlanSyncProvider._();

final class FeedingPlanSyncProvider
    extends
        $FunctionalProvider<FeedingPlanSync, FeedingPlanSync, FeedingPlanSync>
    with $Provider<FeedingPlanSync> {
  FeedingPlanSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedingPlanSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedingPlanSyncHash();

  @$internal
  @override
  $ProviderElement<FeedingPlanSync> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeedingPlanSync create(Ref ref) {
    return feedingPlanSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedingPlanSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedingPlanSync>(value),
    );
  }
}

String _$feedingPlanSyncHash() => r'9f3376d5260dd1c2fcc87b5c3ed72512f83ac24b';
