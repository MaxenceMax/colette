// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottle_timer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Heure de lancement du minuteur de biberon ; `null` au repos.

@ProviderFor(BottleTimerController)
final bottleTimerControllerProvider = BottleTimerControllerProvider._();

/// Heure de lancement du minuteur de biberon ; `null` au repos.
final class BottleTimerControllerProvider
    extends $NotifierProvider<BottleTimerController, DateTime?> {
  /// Heure de lancement du minuteur de biberon ; `null` au repos.
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
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$bottleTimerControllerHash() =>
    r'f589cade9140e81c63c5ada7d4a62d906f99d0b7';

/// Heure de lancement du minuteur de biberon ; `null` au repos.

abstract class _$BottleTimerController extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
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

String _$bottleTimerPhaseHash() => r'5fc68f9d6cef6a8f4df002a0935c03c082c19bca';
