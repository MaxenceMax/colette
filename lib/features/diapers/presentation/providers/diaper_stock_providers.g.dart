// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diaper_stock_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état : `keepAlive` comme les autres repositories.

@ProviderFor(diaperStockRepository)
final diaperStockRepositoryProvider = DiaperStockRepositoryProvider._();

/// Sans état : `keepAlive` comme les autres repositories.

final class DiaperStockRepositoryProvider
    extends
        $FunctionalProvider<
          DiaperStockRepository,
          DiaperStockRepository,
          DiaperStockRepository
        >
    with $Provider<DiaperStockRepository> {
  /// Sans état : `keepAlive` comme les autres repositories.
  DiaperStockRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaperStockRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaperStockRepositoryHash();

  @$internal
  @override
  $ProviderElement<DiaperStockRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaperStockRepository create(Ref ref) {
    return diaperStockRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaperStockRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaperStockRepository>(value),
    );
  }
}

String _$diaperStockRepositoryHash() =>
    r'655f5ba911fcfe2232ce8347f2ac0977c7134571';

/// Stock du foyer courant ; `null` sans foyer ou tant qu'il n'est pas renseigné.

@ProviderFor(diaperStock)
final diaperStockProvider = DiaperStockProvider._();

/// Stock du foyer courant ; `null` sans foyer ou tant qu'il n'est pas renseigné.

final class DiaperStockProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaperStock?>,
          DiaperStock?,
          Stream<DiaperStock?>
        >
    with $FutureModifier<DiaperStock?>, $StreamProvider<DiaperStock?> {
  /// Stock du foyer courant ; `null` sans foyer ou tant qu'il n'est pas renseigné.
  DiaperStockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaperStockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaperStockHash();

  @$internal
  @override
  $StreamProviderElement<DiaperStock?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DiaperStock?> create(Ref ref) {
    return diaperStock(ref);
  }
}

String _$diaperStockHash() => r'3326ac8b1c664000bd322368884d3ce41bf359ef';

/// Restant et alerte ; `null` tant que le stock n'est pas renseigné.

@ProviderFor(diaperStockStatus)
final diaperStockStatusProvider = DiaperStockStatusProvider._();

/// Restant et alerte ; `null` tant que le stock n'est pas renseigné.

final class DiaperStockStatusProvider
    extends
        $FunctionalProvider<
          DiaperStockStatus?,
          DiaperStockStatus?,
          DiaperStockStatus?
        >
    with $Provider<DiaperStockStatus?> {
  /// Restant et alerte ; `null` tant que le stock n'est pas renseigné.
  DiaperStockStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaperStockStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaperStockStatusHash();

  @$internal
  @override
  $ProviderElement<DiaperStockStatus?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaperStockStatus? create(Ref ref) {
    return diaperStockStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaperStockStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaperStockStatus?>(value),
    );
  }
}

String _$diaperStockStatusHash() => r'83d7d71f9e78defdbafb6ffdfcdcb76368527f78';
