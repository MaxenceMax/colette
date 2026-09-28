// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottle_timer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Minuteur de biberon lancé ; `null` au repos.

@ProviderFor(BottleTimerController)
final bottleTimerControllerProvider = BottleTimerControllerProvider._();

/// Minuteur de biberon lancé ; `null` au repos.
final class BottleTimerControllerProvider
    extends $NotifierProvider<BottleTimerController, BottleTimerRun?> {
  /// Minuteur de biberon lancé ; `null` au repos.
  BottleTimerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleTimerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleTimerControllerHash();

  @$internal
  @override
  BottleTimerController create() => BottleTimerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BottleTimerRun? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BottleTimerRun?>(value),
    );
  }
}

String _$bottleTimerControllerHash() =>
    r'2ab9ec90773d33119722c9c6775dc672e57ee113';

/// Minuteur de biberon lancé ; `null` au repos.

abstract class _$BottleTimerController extends $Notifier<BottleTimerRun?> {
  BottleTimerRun? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BottleTimerRun?, BottleTimerRun?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BottleTimerRun?, BottleTimerRun?>,
              BottleTimerRun?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Heure courante, émise chaque seconde tant qu'un minuteur est lancé.

@ProviderFor(bottleTimerTick)
final bottleTimerTickProvider = BottleTimerTickProvider._();

/// Heure courante, émise chaque seconde tant qu'un minuteur est lancé.

final class BottleTimerTickProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Heure courante, émise chaque seconde tant qu'un minuteur est lancé.
  BottleTimerTickProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleTimerTickProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleTimerTickHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return bottleTimerTick(ref);
  }
}

String _$bottleTimerTickHash() => r'55be20281acbf89a24639ec47a350ef65c21ca8f';

/// Phase courante du minuteur de biberon ; `null` au repos.

@ProviderFor(bottleTimerPhase)
final bottleTimerPhaseProvider = BottleTimerPhaseProvider._();

/// Phase courante du minuteur de biberon ; `null` au repos.

final class BottleTimerPhaseProvider
    extends
        $FunctionalProvider<
          BottleTimerPhase?,
          BottleTimerPhase?,
          BottleTimerPhase?
        >
    with $Provider<BottleTimerPhase?> {
  /// Phase courante du minuteur de biberon ; `null` au repos.
  BottleTimerPhaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleTimerPhaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleTimerPhaseHash();

  @$internal
  @override
  $ProviderElement<BottleTimerPhase?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BottleTimerPhase? create(Ref ref) {
    return bottleTimerPhase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BottleTimerPhase? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BottleTimerPhase?>(value),
    );
  }
}

String _$bottleTimerPhaseHash() => r'fc630676cd665425fb7af29c7fbff18b64105375';

/// Écran maintenu allumé, sons et vibrations aux transitions du minuteur ;
/// Live Activity et notifications tenues à jour. À sa destruction (fermeture
/// du formulaire) : écran relâché, activité fermée, session effacée.

@ProviderFor(bottleTimerEffects)
final bottleTimerEffectsProvider = BottleTimerEffectsProvider._();

/// Écran maintenu allumé, sons et vibrations aux transitions du minuteur ;
/// Live Activity et notifications tenues à jour. À sa destruction (fermeture
/// du formulaire) : écran relâché, activité fermée, session effacée.

final class BottleTimerEffectsProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Écran maintenu allumé, sons et vibrations aux transitions du minuteur ;
  /// Live Activity et notifications tenues à jour. À sa destruction (fermeture
  /// du formulaire) : écran relâché, activité fermée, session effacée.
  BottleTimerEffectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleTimerEffectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleTimerEffectsHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return bottleTimerEffects(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$bottleTimerEffectsHash() =>
    r'81e588fc09e14ae467d9ac2b6af0042e205ead83';
