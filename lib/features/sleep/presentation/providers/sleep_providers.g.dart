// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dépôt des sommeils du foyer.

@ProviderFor(sleepRepository)
final sleepRepositoryProvider = SleepRepositoryProvider._();

/// Dépôt des sommeils du foyer.

final class SleepRepositoryProvider
    extends
        $FunctionalProvider<SleepRepository, SleepRepository, SleepRepository>
    with $Provider<SleepRepository> {
  /// Dépôt des sommeils du foyer.
  SleepRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepRepositoryHash();

  @$internal
  @override
  $ProviderElement<SleepRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SleepRepository create(Ref ref) {
    return sleepRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SleepRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SleepRepository>(value),
    );
  }
}

String _$sleepRepositoryHash() => r'227915cfa42431fe3293ba08de0feb5bff50bca9';

/// Sommeils commencés depuis minuit il y a deux jours (couvre les 24 h
/// glissantes, un sommeil durant au plus 24 h). Borne stable sur la journée.

@ProviderFor(recentSleeps)
final recentSleepsProvider = RecentSleepsProvider._();

/// Sommeils commencés depuis minuit il y a deux jours (couvre les 24 h
/// glissantes, un sommeil durant au plus 24 h). Borne stable sur la journée.

final class RecentSleepsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SleepSession>>,
          List<SleepSession>,
          Stream<List<SleepSession>>
        >
    with
        $FutureModifier<List<SleepSession>>,
        $StreamProvider<List<SleepSession>> {
  /// Sommeils commencés depuis minuit il y a deux jours (couvre les 24 h
  /// glissantes, un sommeil durant au plus 24 h). Borne stable sur la journée.
  RecentSleepsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'recentSleepsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentSleepsHash();

  @$internal
  @override
  $StreamProviderElement<List<SleepSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SleepSession>> create(Ref ref) {
    return recentSleeps(ref);
  }
}

String _$recentSleepsHash() => r'7a4fd7561d2c281f6a2ba15df7ebb7b4734d3c16';

/// Dernier sommeil, toutes dates confondues.

@ProviderFor(latestSleep)
final latestSleepProvider = LatestSleepProvider._();

/// Dernier sommeil, toutes dates confondues.

final class LatestSleepProvider
    extends
        $FunctionalProvider<
          AsyncValue<SleepSession?>,
          SleepSession?,
          Stream<SleepSession?>
        >
    with $FutureModifier<SleepSession?>, $StreamProvider<SleepSession?> {
  /// Dernier sommeil, toutes dates confondues.
  LatestSleepProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'latestSleepProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestSleepHash();

  @$internal
  @override
  $StreamProviderElement<SleepSession?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SleepSession?> create(Ref ref) {
    return latestSleep(ref);
  }
}

String _$latestSleepHash() => r'd639caa71f9e108e625441bb65aa7b23d00439e3';

/// État actuel et total sur 24 h ; `null` tant que les flux chargent ou sont
/// en erreur (l'erreur reste exposée via `recentSleepsProvider`/`latestSleepProvider`).

@ProviderFor(sleepSummary)
final sleepSummaryProvider = SleepSummaryProvider._();

/// État actuel et total sur 24 h ; `null` tant que les flux chargent ou sont
/// en erreur (l'erreur reste exposée via `recentSleepsProvider`/`latestSleepProvider`).

final class SleepSummaryProvider
    extends $FunctionalProvider<SleepSummary?, SleepSummary?, SleepSummary?>
    with $Provider<SleepSummary?> {
  /// État actuel et total sur 24 h ; `null` tant que les flux chargent ou sont
  /// en erreur (l'erreur reste exposée via `recentSleepsProvider`/`latestSleepProvider`).
  SleepSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepSummaryHash();

  @$internal
  @override
  $ProviderElement<SleepSummary?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SleepSummary? create(Ref ref) {
    return sleepSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SleepSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SleepSummary?>(value),
    );
  }
}

String _$sleepSummaryHash() => r'926ff0c0f400572f9d5f5e957284059ba9d5f743';

/// Repère OMS selon l'âge ; `null` sans profil ou à partir de 2 ans.

@ProviderFor(sleepAgeBand)
final sleepAgeBandProvider = SleepAgeBandProvider._();

/// Repère OMS selon l'âge ; `null` sans profil ou à partir de 2 ans.

final class SleepAgeBandProvider
    extends $FunctionalProvider<SleepAgeBand?, SleepAgeBand?, SleepAgeBand?>
    with $Provider<SleepAgeBand?> {
  /// Repère OMS selon l'âge ; `null` sans profil ou à partir de 2 ans.
  SleepAgeBandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepAgeBandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepAgeBandHash();

  @$internal
  @override
  $ProviderElement<SleepAgeBand?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SleepAgeBand? create(Ref ref) {
    return sleepAgeBand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SleepAgeBand? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SleepAgeBand?>(value),
    );
  }
}

String _$sleepAgeBandHash() => r'94a09e92c6a38bbeb4cd3d8dad7efba3208ceb5f';

/// Sommeils commencés depuis J−7 (la veille du premier jour affiché couvre les
/// nuits qui débordent sur J−6).

@ProviderFor(weekSleeps)
final weekSleepsProvider = WeekSleepsProvider._();

/// Sommeils commencés depuis J−7 (la veille du premier jour affiché couvre les
/// nuits qui débordent sur J−6).

final class WeekSleepsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SleepSession>>,
          List<SleepSession>,
          Stream<List<SleepSession>>
        >
    with
        $FutureModifier<List<SleepSession>>,
        $StreamProvider<List<SleepSession>> {
  /// Sommeils commencés depuis J−7 (la veille du premier jour affiché couvre les
  /// nuits qui débordent sur J−6).
  WeekSleepsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'weekSleepsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekSleepsHash();

  @$internal
  @override
  $StreamProviderElement<List<SleepSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SleepSession>> create(Ref ref) {
    return weekSleeps(ref);
  }
}

String _$weekSleepsHash() => r'4ee60b97fd90bf2e4da785c962c84d3a48d86982';

/// Les 7 jours de la page Sommeil ; `null` tant que le flux charge ou est en
/// erreur (l'erreur reste exposée via `weekSleepsProvider`, pour la page).

@ProviderFor(sleepWeek)
final sleepWeekProvider = SleepWeekProvider._();

/// Les 7 jours de la page Sommeil ; `null` tant que le flux charge ou est en
/// erreur (l'erreur reste exposée via `weekSleepsProvider`, pour la page).

final class SleepWeekProvider
    extends
        $FunctionalProvider<List<SleepDay>?, List<SleepDay>?, List<SleepDay>?>
    with $Provider<List<SleepDay>?> {
  /// Les 7 jours de la page Sommeil ; `null` tant que le flux charge ou est en
  /// erreur (l'erreur reste exposée via `weekSleepsProvider`, pour la page).
  SleepWeekProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepWeekProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepWeekHash();

  @$internal
  @override
  $ProviderElement<List<SleepDay>?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<SleepDay>? create(Ref ref) {
    return sleepWeek(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SleepDay>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SleepDay>?>(value),
    );
  }
}

String _$sleepWeekHash() => r'bcf27b15aa7f6a8b4c374d89272dc376c022a19b';
