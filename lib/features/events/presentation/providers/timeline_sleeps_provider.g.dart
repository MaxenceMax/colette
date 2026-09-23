// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_sleeps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sommeils du Journal : un seul provider (pas de famille par `from`) pour
/// que Riverpod garde la liste précédente pendant le rechargement au lieu de
/// démarrer un nouveau flux vide à chaque élargissement de la fenêtre.
/// `from` suit le plus ancien soin déjà chargé par [timelineEventsProvider],
/// sinon J−7 à minuit.

@ProviderFor(timelineSleeps)
final timelineSleepsProvider = TimelineSleepsProvider._();

/// Sommeils du Journal : un seul provider (pas de famille par `from`) pour
/// que Riverpod garde la liste précédente pendant le rechargement au lieu de
/// démarrer un nouveau flux vide à chaque élargissement de la fenêtre.
/// `from` suit le plus ancien soin déjà chargé par [timelineEventsProvider],
/// sinon J−7 à minuit.

final class TimelineSleepsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SleepSession>>,
          List<SleepSession>,
          Stream<List<SleepSession>>
        >
    with
        $FutureModifier<List<SleepSession>>,
        $StreamProvider<List<SleepSession>> {
  /// Sommeils du Journal : un seul provider (pas de famille par `from`) pour
  /// que Riverpod garde la liste précédente pendant le rechargement au lieu de
  /// démarrer un nouveau flux vide à chaque élargissement de la fenêtre.
  /// `from` suit le plus ancien soin déjà chargé par [timelineEventsProvider],
  /// sinon J−7 à minuit.
  TimelineSleepsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'timelineSleepsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineSleepsHash();

  @$internal
  @override
  $StreamProviderElement<List<SleepSession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SleepSession>> create(Ref ref) {
    return timelineSleeps(ref);
  }
}

String _$timelineSleepsHash() => r'3dc392ab3538d1ca98e85c9b74b9e103cef434a1';
