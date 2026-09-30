// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'id_generator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Générateur d'identifiants de l'app. Sans état : `keepAlive` car consommé
/// par `BroadcastLists` (keepAlive).

@ProviderFor(idGenerator)
final idGeneratorProvider = IdGeneratorProvider._();

/// Générateur d'identifiants de l'app. Sans état : `keepAlive` car consommé
/// par `BroadcastLists` (keepAlive).

final class IdGeneratorProvider
    extends $FunctionalProvider<IdGenerator, IdGenerator, IdGenerator>
    with $Provider<IdGenerator> {
  /// Générateur d'identifiants de l'app. Sans état : `keepAlive` car consommé
  /// par `BroadcastLists` (keepAlive).
  IdGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idGeneratorHash();

  @$internal
  @override
  $ProviderElement<IdGenerator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IdGenerator create(Ref ref) {
    return idGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdGenerator>(value),
    );
  }
}

String _$idGeneratorHash() => r'd55eadccc5a017e0c06fc9f75a5620e9b9ae0ab8';
