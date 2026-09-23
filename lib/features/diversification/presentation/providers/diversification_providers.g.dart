// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diversification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état et partagé : `keepAlive`.

@ProviderFor(foodCatalogRepository)
final foodCatalogRepositoryProvider = FoodCatalogRepositoryProvider._();

/// Sans état et partagé : `keepAlive`.

final class FoodCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          FoodCatalogRepository,
          FoodCatalogRepository,
          FoodCatalogRepository
        >
    with $Provider<FoodCatalogRepository> {
  /// Sans état et partagé : `keepAlive`.
  FoodCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodCatalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodCatalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<FoodCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FoodCatalogRepository create(Ref ref) {
    return foodCatalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodCatalogRepository>(value),
    );
  }
}

String _$foodCatalogRepositoryHash() =>
    r'8a7c2b787d7400f919afaaf3f44b883768b65da5';

/// Sans état et partagé : `keepAlive`.

@ProviderFor(tastingsRepository)
final tastingsRepositoryProvider = TastingsRepositoryProvider._();

/// Sans état et partagé : `keepAlive`.

final class TastingsRepositoryProvider
    extends
        $FunctionalProvider<
          TastingsRepository,
          TastingsRepository,
          TastingsRepository
        >
    with $Provider<TastingsRepository> {
  /// Sans état et partagé : `keepAlive`.
  TastingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tastingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tastingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TastingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TastingsRepository create(Ref ref) {
    return tastingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TastingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TastingsRepository>(value),
    );
  }
}

String _$tastingsRepositoryHash() =>
    r'd55ba2a800077404df04b6746e4c1b80def032cb';

/// Sans état et partagé : `keepAlive`.

@ProviderFor(customFoodsRepository)
final customFoodsRepositoryProvider = CustomFoodsRepositoryProvider._();

/// Sans état et partagé : `keepAlive`.

final class CustomFoodsRepositoryProvider
    extends
        $FunctionalProvider<
          CustomFoodsRepository,
          CustomFoodsRepository,
          CustomFoodsRepository
        >
    with $Provider<CustomFoodsRepository> {
  /// Sans état et partagé : `keepAlive`.
  CustomFoodsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customFoodsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customFoodsRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomFoodsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomFoodsRepository create(Ref ref) {
    return customFoodsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomFoodsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomFoodsRepository>(value),
    );
  }
}

String _$customFoodsRepositoryHash() =>
    r'cef3bb05448aae6d3b7479164071991544fb1889';

/// Catalogue embarqué, chargé une fois ; la `Failure` éventuelle devient l'erreur.

@ProviderFor(foodCatalog)
final foodCatalogProvider = FoodCatalogProvider._();

/// Catalogue embarqué, chargé une fois ; la `Failure` éventuelle devient l'erreur.

final class FoodCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<FoodCatalog>,
          FoodCatalog,
          FutureOr<FoodCatalog>
        >
    with $FutureModifier<FoodCatalog>, $FutureProvider<FoodCatalog> {
  /// Catalogue embarqué, chargé une fois ; la `Failure` éventuelle devient l'erreur.
  FoodCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'foodCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodCatalogHash();

  @$internal
  @override
  $FutureProviderElement<FoodCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FoodCatalog> create(Ref ref) {
    return foodCatalog(ref);
  }
}

String _$foodCatalogHash() => r'8fe100de849af30a2824c9d63286b616d36ba00a';

/// Dégustations du foyer courant, de la plus récente à la plus ancienne.

@ProviderFor(tastings)
final tastingsProvider = TastingsProvider._();

/// Dégustations du foyer courant, de la plus récente à la plus ancienne.

final class TastingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tasting>>,
          List<Tasting>,
          Stream<List<Tasting>>
        >
    with $FutureModifier<List<Tasting>>, $StreamProvider<List<Tasting>> {
  /// Dégustations du foyer courant, de la plus récente à la plus ancienne.
  TastingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'tastingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tastingsHash();

  @$internal
  @override
  $StreamProviderElement<List<Tasting>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Tasting>> create(Ref ref) {
    return tastings(ref);
  }
}

String _$tastingsHash() => r'be92ef9068f57ac2197f8b4e3be1c08842e7dfbc';

/// Aliments perso du foyer courant.

@ProviderFor(customFoods)
final customFoodsProvider = CustomFoodsProvider._();

/// Aliments perso du foyer courant.

final class CustomFoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Food>>,
          List<Food>,
          Stream<List<Food>>
        >
    with $FutureModifier<List<Food>>, $StreamProvider<List<Food>> {
  /// Aliments perso du foyer courant.
  CustomFoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'customFoodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customFoodsHash();

  @$internal
  @override
  $StreamProviderElement<List<Food>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Food>> create(Ref ref) {
    return customFoods(ref);
  }
}

String _$customFoodsHash() => r'e15906d7ba13ba44692e88479600fb5bebe38929';

/// Catalogue et aliments perso indexés par id ; en erreur si l'une des sources l'est.

@ProviderFor(foods)
final foodsProvider = FoodsProvider._();

/// Catalogue et aliments perso indexés par id ; en erreur si l'une des sources l'est.

final class FoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Food>>,
          AsyncValue<Map<String, Food>>,
          AsyncValue<Map<String, Food>>
        >
    with $Provider<AsyncValue<Map<String, Food>>> {
  /// Catalogue et aliments perso indexés par id ; en erreur si l'une des sources l'est.
  FoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<String, Food>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<String, Food>> create(Ref ref) {
    return foods(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Map<String, Food>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Map<String, Food>>>(
        value,
      ),
    );
  }
}

String _$foodsHash() => r'65f7712c26d3350a68f667029f23442a36f3d17f';

/// Phase et âge de diversification ; `null` sans profil.

@ProviderFor(diversificationTimeline)
final diversificationTimelineProvider = DiversificationTimelineProvider._();

/// Phase et âge de diversification ; `null` sans profil.

final class DiversificationTimelineProvider
    extends
        $FunctionalProvider<
          DiversificationTimeline?,
          DiversificationTimeline?,
          DiversificationTimeline?
        >
    with $Provider<DiversificationTimeline?> {
  /// Phase et âge de diversification ; `null` sans profil.
  DiversificationTimelineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diversificationTimelineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diversificationTimelineHash();

  @$internal
  @override
  $ProviderElement<DiversificationTimeline?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiversificationTimeline? create(Ref ref) {
    return diversificationTimeline(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiversificationTimeline? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiversificationTimeline?>(value),
    );
  }
}

String _$diversificationTimelineHash() =>
    r'0b4101558e0ceef2dc8341c14572ec2c59fc6531';
