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
        retry: noRetry,
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

String _$babyProfileHash() => r'7ff12b0325173288e7813bffae05a5b327992c77';

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
        retry: noRetry,
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

String _$weightsHash() => r'53476379617c8179dbdb8dd2528a8d579cc76650';

/// Mesures de croissance du foyer courant, de la plus récente à la plus ancienne.

@ProviderFor(measurements)
final measurementsProvider = MeasurementsProvider._();

/// Mesures de croissance du foyer courant, de la plus récente à la plus ancienne.

final class MeasurementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GrowthMeasurement>>,
          List<GrowthMeasurement>,
          Stream<List<GrowthMeasurement>>
        >
    with
        $FutureModifier<List<GrowthMeasurement>>,
        $StreamProvider<List<GrowthMeasurement>> {
  /// Mesures de croissance du foyer courant, de la plus récente à la plus ancienne.
  MeasurementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'measurementsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measurementsHash();

  @$internal
  @override
  $StreamProviderElement<List<GrowthMeasurement>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GrowthMeasurement>> create(Ref ref) {
    return measurements(ref);
  }
}

String _$measurementsHash() => r'42332fc3c3db8ea1a45c5034bbde13a07fe248de';

/// Mesure avec poids la plus récente, ou `null`.

@ProviderFor(latestWeight)
final latestWeightProvider = LatestWeightProvider._();

/// Mesure avec poids la plus récente, ou `null`.

final class LatestWeightProvider
    extends
        $FunctionalProvider<
          GrowthMeasurement?,
          GrowthMeasurement?,
          GrowthMeasurement?
        >
    with $Provider<GrowthMeasurement?> {
  /// Mesure avec poids la plus récente, ou `null`.
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
  $ProviderElement<GrowthMeasurement?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GrowthMeasurement? create(Ref ref) {
    return latestWeight(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrowthMeasurement? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrowthMeasurement?>(value),
    );
  }
}

String _$latestWeightHash() => r'ce4b856c33a86f87da0978ed32b5acef821bf39e';

/// Dernière valeur de [metric] et évolution depuis la précédente, ou `null`.

@ProviderFor(growthTrend)
final growthTrendProvider = GrowthTrendFamily._();

/// Dernière valeur de [metric] et évolution depuis la précédente, ou `null`.

final class GrowthTrendProvider
    extends $FunctionalProvider<GrowthTrend?, GrowthTrend?, GrowthTrend?>
    with $Provider<GrowthTrend?> {
  /// Dernière valeur de [metric] et évolution depuis la précédente, ou `null`.
  GrowthTrendProvider._({
    required GrowthTrendFamily super.from,
    required GrowthMetric super.argument,
  }) : super(
         retry: null,
         name: r'growthTrendProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$growthTrendHash();

  @override
  String toString() {
    return r'growthTrendProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<GrowthTrend?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GrowthTrend? create(Ref ref) {
    final argument = this.argument as GrowthMetric;
    return growthTrend(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GrowthTrend? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GrowthTrend?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GrowthTrendProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$growthTrendHash() => r'ec5925d06bbfd9d0802778208514df30a8f3799a';

/// Dernière valeur de [metric] et évolution depuis la précédente, ou `null`.

final class GrowthTrendFamily extends $Family
    with $FunctionalFamilyOverride<GrowthTrend?, GrowthMetric> {
  GrowthTrendFamily._()
    : super(
        retry: null,
        name: r'growthTrendProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Dernière valeur de [metric] et évolution depuis la précédente, ou `null`.

  GrowthTrendProvider call(GrowthMetric metric) =>
      GrowthTrendProvider._(argument: metric, from: this);

  @override
  String toString() => r'growthTrendProvider';
}

/// Percentiles OMS de [metric] sur la période de ses mesures, une journée de
/// marge de chaque côté ; vide sans mesure, sans profil ou sans sexe renseigné.

@ProviderFor(whoReference)
final whoReferenceProvider = WhoReferenceFamily._();

/// Percentiles OMS de [metric] sur la période de ses mesures, une journée de
/// marge de chaque côté ; vide sans mesure, sans profil ou sans sexe renseigné.

final class WhoReferenceProvider
    extends
        $FunctionalProvider<
          List<WhoPercentiles>,
          List<WhoPercentiles>,
          List<WhoPercentiles>
        >
    with $Provider<List<WhoPercentiles>> {
  /// Percentiles OMS de [metric] sur la période de ses mesures, une journée de
  /// marge de chaque côté ; vide sans mesure, sans profil ou sans sexe renseigné.
  WhoReferenceProvider._({
    required WhoReferenceFamily super.from,
    required GrowthMetric super.argument,
  }) : super(
         retry: null,
         name: r'whoReferenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$whoReferenceHash();

  @override
  String toString() {
    return r'whoReferenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<WhoPercentiles>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<WhoPercentiles> create(Ref ref) {
    final argument = this.argument as GrowthMetric;
    return whoReference(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<WhoPercentiles> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<WhoPercentiles>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WhoReferenceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$whoReferenceHash() => r'f6e8cb041cbf0da1144430ab42031215233fed21';

/// Percentiles OMS de [metric] sur la période de ses mesures, une journée de
/// marge de chaque côté ; vide sans mesure, sans profil ou sans sexe renseigné.

final class WhoReferenceFamily extends $Family
    with $FunctionalFamilyOverride<List<WhoPercentiles>, GrowthMetric> {
  WhoReferenceFamily._()
    : super(
        retry: null,
        name: r'whoReferenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Percentiles OMS de [metric] sur la période de ses mesures, une journée de
  /// marge de chaque côté ; vide sans mesure, sans profil ou sans sexe renseigné.

  WhoReferenceProvider call(GrowthMetric metric) =>
      WhoReferenceProvider._(argument: metric, from: this);

  @override
  String toString() => r'whoReferenceProvider';
}

/// Dernière pesée et évolution depuis la précédente, ou `null` sans pesée.

@ProviderFor(weightTrend)
final weightTrendProvider = WeightTrendProvider._();

/// Dernière pesée et évolution depuis la précédente, ou `null` sans pesée.

final class WeightTrendProvider
    extends $FunctionalProvider<WeightTrend?, WeightTrend?, WeightTrend?>
    with $Provider<WeightTrend?> {
  /// Dernière pesée et évolution depuis la précédente, ou `null` sans pesée.
  WeightTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightTrendHash();

  @$internal
  @override
  $ProviderElement<WeightTrend?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeightTrend? create(Ref ref) {
    return weightTrend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeightTrend? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeightTrend?>(value),
    );
  }
}

String _$weightTrendHash() => r'9e49640f580b5863ebef9b99544fd3acb848d052';

/// Percentiles OMS sur la période des pesées, une journée de marge de chaque
/// côté ; vide sans pesée, sans profil ou sans sexe renseigné.

@ProviderFor(whoWeightReference)
final whoWeightReferenceProvider = WhoWeightReferenceProvider._();

/// Percentiles OMS sur la période des pesées, une journée de marge de chaque
/// côté ; vide sans pesée, sans profil ou sans sexe renseigné.

final class WhoWeightReferenceProvider
    extends
        $FunctionalProvider<
          List<WhoWeightPercentiles>,
          List<WhoWeightPercentiles>,
          List<WhoWeightPercentiles>
        >
    with $Provider<List<WhoWeightPercentiles>> {
  /// Percentiles OMS sur la période des pesées, une journée de marge de chaque
  /// côté ; vide sans pesée, sans profil ou sans sexe renseigné.
  WhoWeightReferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whoWeightReferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whoWeightReferenceHash();

  @$internal
  @override
  $ProviderElement<List<WhoWeightPercentiles>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<WhoWeightPercentiles> create(Ref ref) {
    return whoWeightReference(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<WhoWeightPercentiles> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<WhoWeightPercentiles>>(value),
    );
  }
}

String _$whoWeightReferenceHash() =>
    r'5e32ae3fcc1288753372f81fe6ec531937f92cfb';
