// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_filter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recherche et filtres du catalogue, partagés entre la carte Allergènes et la liste.

@ProviderFor(CatalogFilter)
final catalogFilterProvider = CatalogFilterProvider._();

/// Recherche et filtres du catalogue, partagés entre la carte Allergènes et la liste.
final class CatalogFilterProvider
    extends $NotifierProvider<CatalogFilter, FoodFilter> {
  /// Recherche et filtres du catalogue, partagés entre la carte Allergènes et la liste.
  CatalogFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogFilterHash();

  @$internal
  @override
  CatalogFilter create() => CatalogFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodFilter>(value),
    );
  }
}

String _$catalogFilterHash() => r'0f633faf005ee8a07b94b2b968744dfc1e1d3167';

/// Recherche et filtres du catalogue, partagés entre la carte Allergènes et la liste.

abstract class _$CatalogFilter extends $Notifier<FoodFilter> {
  FoodFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FoodFilter, FoodFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FoodFilter, FoodFilter>,
              FoodFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
