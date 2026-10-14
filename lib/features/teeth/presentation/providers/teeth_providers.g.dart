// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teeth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état : `keepAlive` comme les autres dépôts Firestore.

@ProviderFor(teethRepository)
final teethRepositoryProvider = TeethRepositoryProvider._();

/// Sans état : `keepAlive` comme les autres dépôts Firestore.

final class TeethRepositoryProvider
    extends
        $FunctionalProvider<TeethRepository, TeethRepository, TeethRepository>
    with $Provider<TeethRepository> {
  /// Sans état : `keepAlive` comme les autres dépôts Firestore.
  TeethRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teethRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teethRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeethRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeethRepository create(Ref ref) {
    return teethRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeethRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeethRepository>(value),
    );
  }
}

String _$teethRepositoryHash() => r'732ceb4ef37a6772efcb7a5fbd3026e2a277e632';

/// Dents notées du foyer courant, indexées par numéro.

@ProviderFor(teeth)
final teethProvider = TeethProvider._();

/// Dents notées du foyer courant, indexées par numéro.

final class TeethProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<ToothId, ToothRecord>>,
          Map<ToothId, ToothRecord>,
          Stream<Map<ToothId, ToothRecord>>
        >
    with
        $FutureModifier<Map<ToothId, ToothRecord>>,
        $StreamProvider<Map<ToothId, ToothRecord>> {
  /// Dents notées du foyer courant, indexées par numéro.
  TeethProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'teethProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teethHash();

  @$internal
  @override
  $StreamProviderElement<Map<ToothId, ToothRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<ToothId, ToothRecord>> create(Ref ref) {
    return teeth(ref);
  }
}

String _$teethHash() => r'd9251f0c248d7d2324ab522179dfc9e33c37983b';

/// Résumé pour la carte Santé ; `null` tant que les dents ne sont pas lues.

@ProviderFor(teethSummary)
final teethSummaryProvider = TeethSummaryProvider._();

/// Résumé pour la carte Santé ; `null` tant que les dents ne sont pas lues.

final class TeethSummaryProvider
    extends $FunctionalProvider<TeethSummary?, TeethSummary?, TeethSummary?>
    with $Provider<TeethSummary?> {
  /// Résumé pour la carte Santé ; `null` tant que les dents ne sont pas lues.
  TeethSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teethSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teethSummaryHash();

  @$internal
  @override
  $ProviderElement<TeethSummary?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeethSummary? create(Ref ref) {
    return teethSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeethSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeethSummary?>(value),
    );
  }
}

String _$teethSummaryHash() => r'c9a3e086d8982e42bb55ed37444c6cf786fec16a';
