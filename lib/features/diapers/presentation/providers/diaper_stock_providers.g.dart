// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diaper_stock_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état et partagé : `keepAlive`.

@ProviderFor(diaperStockRepository)
final diaperStockRepositoryProvider = DiaperStockRepositoryProvider._();

/// Sans état et partagé : `keepAlive`.

final class DiaperStockRepositoryProvider
    extends
        $FunctionalProvider<
          DiaperStockRepository,
          DiaperStockRepository,
          DiaperStockRepository
        >
    with $Provider<DiaperStockRepository> {
  /// Sans état et partagé : `keepAlive`.
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
        retry: noRetry,
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

String _$diaperStockHash() => r'3bf0bed99e16ad0406dccbe3cb7e37b2eb318b47';

/// Restant et alerte. `AsyncData(null)` tant que le stock n'est pas renseigné ;
/// `AsyncLoading` ou `AsyncError` tant que le stock ou le comptage des changes
/// n'est pas disponible, pour ne jamais afficher ni écrire un restant faux.

@ProviderFor(diaperStockStatus)
final diaperStockStatusProvider = DiaperStockStatusProvider._();

/// Restant et alerte. `AsyncData(null)` tant que le stock n'est pas renseigné ;
/// `AsyncLoading` ou `AsyncError` tant que le stock ou le comptage des changes
/// n'est pas disponible, pour ne jamais afficher ni écrire un restant faux.

final class DiaperStockStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaperStockStatus?>,
          AsyncValue<DiaperStockStatus?>,
          AsyncValue<DiaperStockStatus?>
        >
    with $Provider<AsyncValue<DiaperStockStatus?>> {
  /// Restant et alerte. `AsyncData(null)` tant que le stock n'est pas renseigné ;
  /// `AsyncLoading` ou `AsyncError` tant que le stock ou le comptage des changes
  /// n'est pas disponible, pour ne jamais afficher ni écrire un restant faux.
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
  $ProviderElement<AsyncValue<DiaperStockStatus?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<DiaperStockStatus?> create(Ref ref) {
    return diaperStockStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<DiaperStockStatus?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<DiaperStockStatus?>>(
        value,
      ),
    );
  }
}

String _$diaperStockStatusHash() => r'8b7641897e12d8f928a1c213a0c9918ac19f6a4b';
