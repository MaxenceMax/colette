// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plan biberons du jour ; `null` sans profil.

@ProviderFor(feedingPlan)
final feedingPlanProvider = FeedingPlanProvider._();

/// Plan biberons du jour ; `null` sans profil.

final class FeedingPlanProvider
    extends $FunctionalProvider<FeedingPlan?, FeedingPlan?, FeedingPlan?>
    with $Provider<FeedingPlan?> {
  /// Plan biberons du jour ; `null` sans profil.
  FeedingPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedingPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedingPlanHash();

  @$internal
  @override
  $ProviderElement<FeedingPlan?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeedingPlan? create(Ref ref) {
    return feedingPlan(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeedingPlan? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeedingPlan?>(value),
    );
  }
}

String _$feedingPlanHash() => r'abc57d5aa8e84acdc5367099a655624b40df6dae';

/// Biberons des dernières 24 h glissantes.

@ProviderFor(rollingIntake)
final rollingIntakeProvider = RollingIntakeProvider._();

/// Biberons des dernières 24 h glissantes.

final class RollingIntakeProvider
    extends $FunctionalProvider<RollingIntake, RollingIntake, RollingIntake>
    with $Provider<RollingIntake> {
  /// Biberons des dernières 24 h glissantes.
  RollingIntakeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rollingIntakeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rollingIntakeHash();

  @$internal
  @override
  $ProviderElement<RollingIntake> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RollingIntake create(Ref ref) {
    return rollingIntake(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RollingIntake value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RollingIntake>(value),
    );
  }
}

String _$rollingIntakeHash() => r'453011fddb9e4c69660eea2c6632a9e6ce83dd1f';

/// Soins attendus aujourd'hui.

@ProviderFor(dailyCareTasks)
final dailyCareTasksProvider = DailyCareTasksProvider._();

/// Soins attendus aujourd'hui.

final class DailyCareTasksProvider
    extends $FunctionalProvider<List<CareTask>, List<CareTask>, List<CareTask>>
    with $Provider<List<CareTask>> {
  /// Soins attendus aujourd'hui.
  DailyCareTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyCareTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyCareTasksHash();

  @$internal
  @override
  $ProviderElement<List<CareTask>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<CareTask> create(Ref ref) {
    return dailyCareTasks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CareTask> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CareTask>>(value),
    );
  }
}

String _$dailyCareTasksHash() => r'9e2da3e811d732fd2c2fcce224457909641c3c85';

@ProviderFor(dayCounters)
final dayCountersProvider = DayCountersProvider._();

final class DayCountersProvider
    extends $FunctionalProvider<DayCounters, DayCounters, DayCounters>
    with $Provider<DayCounters> {
  DayCountersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dayCountersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dayCountersHash();

  @$internal
  @override
  $ProviderElement<DayCounters> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DayCounters create(Ref ref) {
    return dayCounters(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DayCounters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DayCounters>(value),
    );
  }
}

String _$dayCountersHash() => r'7f6fe9212c8dd8c2fbd57f499d0c0b144fdfeda9';

/// Âge du bébé ; `null` sans profil.

@ProviderFor(babyAge)
final babyAgeProvider = BabyAgeProvider._();

/// Âge du bébé ; `null` sans profil.

final class BabyAgeProvider
    extends $FunctionalProvider<BabyAge?, BabyAge?, BabyAge?>
    with $Provider<BabyAge?> {
  /// Âge du bébé ; `null` sans profil.
  BabyAgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'babyAgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$babyAgeHash();

  @$internal
  @override
  $ProviderElement<BabyAge?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BabyAge? create(Ref ref) {
    return babyAge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BabyAge? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BabyAge?>(value),
    );
  }
}

String _$babyAgeHash() => r'159fb93971f0e54583c81edcb5b1a66ba60b5e8f';
