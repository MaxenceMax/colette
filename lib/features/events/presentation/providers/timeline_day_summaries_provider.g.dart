// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_day_summaries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Bilan de chaque jour affiché par le Journal, sur la journée entière :
/// ignore le filtre et la coupure de pagination. `from` suit le plus ancien
/// soin ou sommeil chargé, sinon aujourd'hui à minuit. Un seul provider,
/// comme [timelineSleepsProvider], pour garder le bilan précédent pendant le
/// rechargement.

@ProviderFor(timelineDaySummaries)
final timelineDaySummariesProvider = TimelineDaySummariesProvider._();

/// Bilan de chaque jour affiché par le Journal, sur la journée entière :
/// ignore le filtre et la coupure de pagination. `from` suit le plus ancien
/// soin ou sommeil chargé, sinon aujourd'hui à minuit. Un seul provider,
/// comme [timelineSleepsProvider], pour garder le bilan précédent pendant le
/// rechargement.

final class TimelineDaySummariesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, CareDaySummary>>,
          Map<DateTime, CareDaySummary>,
          Stream<Map<DateTime, CareDaySummary>>
        >
    with
        $FutureModifier<Map<DateTime, CareDaySummary>>,
        $StreamProvider<Map<DateTime, CareDaySummary>> {
  /// Bilan de chaque jour affiché par le Journal, sur la journée entière :
  /// ignore le filtre et la coupure de pagination. `from` suit le plus ancien
  /// soin ou sommeil chargé, sinon aujourd'hui à minuit. Un seul provider,
  /// comme [timelineSleepsProvider], pour garder le bilan précédent pendant le
  /// rechargement.
  TimelineDaySummariesProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'timelineDaySummariesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineDaySummariesHash();

  @$internal
  @override
  $StreamProviderElement<Map<DateTime, CareDaySummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<DateTime, CareDaySummary>> create(Ref ref) {
    return timelineDaySummaries(ref);
  }
}

String _$timelineDaySummariesHash() =>
    r'f373dbce52510d64bdb7937bcef4bdc548e4cd44';
