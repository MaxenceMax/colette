// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `keepAlive` : lu avant un `await` par des contrôleurs autoDispose.

@ProviderFor(healthSync)
final healthSyncProvider = HealthSyncProvider._();

/// `keepAlive` : lu avant un `await` par des contrôleurs autoDispose.

final class HealthSyncProvider
    extends $FunctionalProvider<HealthSync, HealthSync, HealthSync>
    with $Provider<HealthSync> {
  /// `keepAlive` : lu avant un `await` par des contrôleurs autoDispose.
  HealthSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthSyncHash();

  @$internal
  @override
  $ProviderElement<HealthSync> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthSync create(Ref ref) {
    return healthSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthSync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthSync>(value),
    );
  }
}

String _$healthSyncHash() => r'ffc543ae2a18f98526a87408e5f667b49e4b2dfe';
