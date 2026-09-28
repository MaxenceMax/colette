// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottle_timer_system.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pont du minuteur hors de l'app ; remplacé par un faux dans les tests.

@ProviderFor(bottleTimerSystem)
final bottleTimerSystemProvider = BottleTimerSystemProvider._();

/// Pont du minuteur hors de l'app ; remplacé par un faux dans les tests.

final class BottleTimerSystemProvider
    extends
        $FunctionalProvider<
          BottleTimerSystem,
          BottleTimerSystem,
          BottleTimerSystem
        >
    with $Provider<BottleTimerSystem> {
  /// Pont du minuteur hors de l'app ; remplacé par un faux dans les tests.
  BottleTimerSystemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleTimerSystemProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleTimerSystemHash();

  @$internal
  @override
  $ProviderElement<BottleTimerSystem> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BottleTimerSystem create(Ref ref) {
    return bottleTimerSystem(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BottleTimerSystem value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BottleTimerSystem>(value),
    );
  }
}

String _$bottleTimerSystemHash() => r'60775d0c1b3fa684e76ef5afaf217e68efea3503';
