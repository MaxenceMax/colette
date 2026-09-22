// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).

@ProviderFor(babyRepository)
final babyRepositoryProvider = BabyRepositoryProvider._();

/// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).

final class BabyRepositoryProvider
    extends $FunctionalProvider<BabyRepository, BabyRepository, BabyRepository>
    with $Provider<BabyRepository> {
  /// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).
  BabyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'babyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$babyRepositoryHash();

  @$internal
  @override
  $ProviderElement<BabyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BabyRepository create(Ref ref) {
    return babyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BabyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BabyRepository>(value),
    );
  }
}

String _$babyRepositoryHash() => r'b9dbbd5bd63907f9746fbd7f58070938a73afc5f';

/// Profil du bébé du foyer courant.

@ProviderFor(babyProfile)
final babyProfileProvider = BabyProfileProvider._();

/// Profil du bébé du foyer courant.

final class BabyProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<BabyProfile?>,
          BabyProfile?,
          Stream<BabyProfile?>
        >
    with $FutureModifier<BabyProfile?>, $StreamProvider<BabyProfile?> {
  /// Profil du bébé du foyer courant.
  BabyProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'babyProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$babyProfileHash();

  @$internal
  @override
  $StreamProviderElement<BabyProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<BabyProfile?> create(Ref ref) {
    return babyProfile(ref);
  }
}

String _$babyProfileHash() => r'e8ac72c64d29a0776c6ae015d1f697d94ad7e5ab';

/// Pesées du foyer courant, de la plus récente à la plus ancienne.

@ProviderFor(weights)
final weightsProvider = WeightsProvider._();

/// Pesées du foyer courant, de la plus récente à la plus ancienne.

final class WeightsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WeightEntry>>,
          List<WeightEntry>,
          Stream<List<WeightEntry>>
        >
    with
        $FutureModifier<List<WeightEntry>>,
        $StreamProvider<List<WeightEntry>> {
  /// Pesées du foyer courant, de la plus récente à la plus ancienne.
  WeightsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightsHash();

  @$internal
  @override
  $StreamProviderElement<List<WeightEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WeightEntry>> create(Ref ref) {
    return weights(ref);
  }
}

String _$weightsHash() => r'8a9634588c2e5480383bc287b4d9cef911c16a92';

/// Pesée la plus récente, ou `null`.

@ProviderFor(latestWeight)
final latestWeightProvider = LatestWeightProvider._();

/// Pesée la plus récente, ou `null`.

final class LatestWeightProvider
    extends $FunctionalProvider<WeightEntry?, WeightEntry?, WeightEntry?>
    with $Provider<WeightEntry?> {
  /// Pesée la plus récente, ou `null`.
  LatestWeightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestWeightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestWeightHash();

  @$internal
  @override
  $ProviderElement<WeightEntry?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeightEntry? create(Ref ref) {
    return latestWeight(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeightEntry? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeightEntry?>(value),
    );
  }
}

String _$latestWeightHash() => r'149e6fb6f54389b1d5a8a0f8b665f8bcd4e12ad1';
