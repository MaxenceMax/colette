// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottle_timer_session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stockage local de la session du minuteur ; remplacé en test.

@ProviderFor(bottleTimerSessionRepository)
final bottleTimerSessionRepositoryProvider =
    BottleTimerSessionRepositoryProvider._();

/// Stockage local de la session du minuteur ; remplacé en test.

final class BottleTimerSessionRepositoryProvider
    extends
        $FunctionalProvider<
          BottleTimerSessionRepository,
          BottleTimerSessionRepository,
          BottleTimerSessionRepository
        >
    with $Provider<BottleTimerSessionRepository> {
  /// Stockage local de la session du minuteur ; remplacé en test.
  BottleTimerSessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleTimerSessionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleTimerSessionRepositoryHash();

  @$internal
  @override
  $ProviderElement<BottleTimerSessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BottleTimerSessionRepository create(Ref ref) {
    return bottleTimerSessionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BottleTimerSessionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BottleTimerSessionRepository>(value),
    );
  }
}

String _$bottleTimerSessionRepositoryHash() =>
    r'7a189e6e034bce7771f5c781edadcc7a36463543';

/// Session interrompue à rouvrir sur Aujourd'hui, posée au démarrage par
/// `BottleTimerResumeGate` et consommée par `DashboardPage`.

@ProviderFor(BottleTimerResume)
final bottleTimerResumeProvider = BottleTimerResumeProvider._();

/// Session interrompue à rouvrir sur Aujourd'hui, posée au démarrage par
/// `BottleTimerResumeGate` et consommée par `DashboardPage`.
final class BottleTimerResumeProvider
    extends $NotifierProvider<BottleTimerResume, BottleTimerSession?> {
  /// Session interrompue à rouvrir sur Aujourd'hui, posée au démarrage par
  /// `BottleTimerResumeGate` et consommée par `DashboardPage`.
  BottleTimerResumeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bottleTimerResumeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bottleTimerResumeHash();

  @$internal
  @override
  BottleTimerResume create() => BottleTimerResume();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BottleTimerSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BottleTimerSession?>(value),
    );
  }
}

String _$bottleTimerResumeHash() => r'1894788481c2acaea5853aa38e09f48f92791f6c';

/// Session interrompue à rouvrir sur Aujourd'hui, posée au démarrage par
/// `BottleTimerResumeGate` et consommée par `DashboardPage`.

abstract class _$BottleTimerResume extends $Notifier<BottleTimerSession?> {
  BottleTimerSession? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BottleTimerSession?, BottleTimerSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BottleTimerSession?, BottleTimerSession?>,
              BottleTimerSession?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
