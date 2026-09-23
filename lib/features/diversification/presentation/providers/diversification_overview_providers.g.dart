// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diversification_overview_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Nombre de dégustations par aliment.

@ProviderFor(tastingCounts)
final tastingCountsProvider = TastingCountsProvider._();

/// Nombre de dégustations par aliment.

final class TastingCountsProvider
    extends
        $FunctionalProvider<
          Map<String, int>,
          Map<String, int>,
          Map<String, int>
        >
    with $Provider<Map<String, int>> {
  /// Nombre de dégustations par aliment.
  TastingCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tastingCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tastingCountsHash();

  @$internal
  @override
  $ProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, int> create(Ref ref) {
    return tastingCounts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$tastingCountsHash() => r'1891283fd7ffb3e2549bcb06c5d4b373520c7aeb';

/// Dégustations d'un aliment, de la plus récente à la plus ancienne.

@ProviderFor(tastingsForFood)
final tastingsForFoodProvider = TastingsForFoodFamily._();

/// Dégustations d'un aliment, de la plus récente à la plus ancienne.

final class TastingsForFoodProvider
    extends $FunctionalProvider<List<Tasting>, List<Tasting>, List<Tasting>>
    with $Provider<List<Tasting>> {
  /// Dégustations d'un aliment, de la plus récente à la plus ancienne.
  TastingsForFoodProvider._({
    required TastingsForFoodFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tastingsForFoodProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tastingsForFoodHash();

  @override
  String toString() {
    return r'tastingsForFoodProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Tasting>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Tasting> create(Ref ref) {
    final argument = this.argument as String;
    return tastingsForFood(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Tasting> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Tasting>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TastingsForFoodProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tastingsForFoodHash() => r'17a0b1b698665dd11e66fb4690c0ee7a6a617dd6';

/// Dégustations d'un aliment, de la plus récente à la plus ancienne.

final class TastingsForFoodFamily extends $Family
    with $FunctionalFamilyOverride<List<Tasting>, String> {
  TastingsForFoodFamily._()
    : super(
        retry: null,
        name: r'tastingsForFoodProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Dégustations d'un aliment, de la plus récente à la plus ancienne.

  TastingsForFoodProvider call(String foodId) =>
      TastingsForFoodProvider._(argument: foodId, from: this);

  @override
  String toString() => r'tastingsForFoodProvider';
}

/// Groupes OMS couverts aujourd'hui.

@ProviderFor(dailyDiversity)
final dailyDiversityProvider = DailyDiversityProvider._();

/// Groupes OMS couverts aujourd'hui.

final class DailyDiversityProvider
    extends $FunctionalProvider<DailyDiversity, DailyDiversity, DailyDiversity>
    with $Provider<DailyDiversity> {
  /// Groupes OMS couverts aujourd'hui.
  DailyDiversityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyDiversityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyDiversityHash();

  @$internal
  @override
  $ProviderElement<DailyDiversity> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DailyDiversity create(Ref ref) {
    return dailyDiversity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyDiversity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyDiversity>(value),
    );
  }
}

String _$dailyDiversityHash() => r'59d19337bbed82854c1a6f826e03e5eb9f7abf40';

/// État des 9 allergènes suivis.

@ProviderFor(allergenProgress)
final allergenProgressProvider = AllergenProgressProvider._();

/// État des 9 allergènes suivis.

final class AllergenProgressProvider
    extends
        $FunctionalProvider<
          Map<Allergen, AllergenState>,
          Map<Allergen, AllergenState>,
          Map<Allergen, AllergenState>
        >
    with $Provider<Map<Allergen, AllergenState>> {
  /// État des 9 allergènes suivis.
  AllergenProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allergenProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allergenProgressHash();

  @$internal
  @override
  $ProviderElement<Map<Allergen, AllergenState>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<Allergen, AllergenState> create(Ref ref) {
    return allergenProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<Allergen, AllergenState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<Allergen, AllergenState>>(value),
    );
  }
}

String _$allergenProgressHash() => r'be333193cc6120c89419db86895d0ab8274d6265';

/// Aliments à reproposer.

@ProviderFor(foodsToRetry)
final foodsToRetryProvider = FoodsToRetryProvider._();

/// Aliments à reproposer.

final class FoodsToRetryProvider
    extends
        $FunctionalProvider<List<RetryItem>, List<RetryItem>, List<RetryItem>>
    with $Provider<List<RetryItem>> {
  /// Aliments à reproposer.
  FoodsToRetryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodsToRetryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodsToRetryHash();

  @$internal
  @override
  $ProviderElement<List<RetryItem>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<RetryItem> create(Ref ref) {
    return foodsToRetry(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RetryItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RetryItem>>(value),
    );
  }
}

String _$foodsToRetryHash() => r'59368fd5bf680ae40e4a4dbfe1eeeda72c0e570c';

/// Statut de chaque aliment pour l'âge courant (sans âge si pas de profil).

@ProviderFor(foodStatuses)
final foodStatusesProvider = FoodStatusesProvider._();

/// Statut de chaque aliment pour l'âge courant (sans âge si pas de profil).

final class FoodStatusesProvider
    extends
        $FunctionalProvider<
          Map<String, FoodStatus>,
          Map<String, FoodStatus>,
          Map<String, FoodStatus>
        >
    with $Provider<Map<String, FoodStatus>> {
  /// Statut de chaque aliment pour l'âge courant (sans âge si pas de profil).
  FoodStatusesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodStatusesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodStatusesHash();

  @$internal
  @override
  $ProviderElement<Map<String, FoodStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, FoodStatus> create(Ref ref) {
    return foodStatuses(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, FoodStatus> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, FoodStatus>>(value),
    );
  }
}

String _$foodStatusesHash() => r'3deaf12a481449fc7778ba1dbaf32550bb666744';

/// Catalogue filtré par [CatalogFilter], groupé par groupe OMS.

@ProviderFor(filteredCatalog)
final filteredCatalogProvider = FilteredCatalogProvider._();

/// Catalogue filtré par [CatalogFilter], groupé par groupe OMS.

final class FilteredCatalogProvider
    extends
        $FunctionalProvider<
          List<FoodGroupSection>,
          List<FoodGroupSection>,
          List<FoodGroupSection>
        >
    with $Provider<List<FoodGroupSection>> {
  /// Catalogue filtré par [CatalogFilter], groupé par groupe OMS.
  FilteredCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredCatalogHash();

  @$internal
  @override
  $ProviderElement<List<FoodGroupSection>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FoodGroupSection> create(Ref ref) {
    return filteredCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FoodGroupSection> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FoodGroupSection>>(value),
    );
  }
}

String _$filteredCatalogHash() => r'8e7ea79b3db66c023ef6d4ca94cc67e7d0d462e9';
