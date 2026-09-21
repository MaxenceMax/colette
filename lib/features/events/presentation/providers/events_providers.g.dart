// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventsRepository)
final eventsRepositoryProvider = EventsRepositoryProvider._();

final class EventsRepositoryProvider
    extends
        $FunctionalProvider<
          EventsRepository,
          EventsRepository,
          EventsRepository
        >
    with $Provider<EventsRepository> {
  EventsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventsRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventsRepository create(Ref ref) {
    return eventsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventsRepository>(value),
    );
  }
}

String _$eventsRepositoryHash() => r'3b1b29b6dee0c197e91e4fe29949e8b2051bc018';

/// Événements du jour civil courant, du plus récent au plus ancien.

@ProviderFor(todayEvents)
final todayEventsProvider = TodayEventsProvider._();

/// Événements du jour civil courant, du plus récent au plus ancien.

final class TodayEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CareEvent>>,
          List<CareEvent>,
          Stream<List<CareEvent>>
        >
    with $FutureModifier<List<CareEvent>>, $StreamProvider<List<CareEvent>> {
  /// Événements du jour civil courant, du plus récent au plus ancien.
  TodayEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<CareEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CareEvent>> create(Ref ref) {
    return todayEvents(ref);
  }
}

String _$todayEventsHash() => r'19b85cc59901c1eb9903b7a28bf107821ff46388';

/// Dernier bain enregistré, toutes dates confondues.

@ProviderFor(latestBath)
final latestBathProvider = LatestBathProvider._();

/// Dernier bain enregistré, toutes dates confondues.

final class LatestBathProvider
    extends
        $FunctionalProvider<
          AsyncValue<CareEvent?>,
          CareEvent?,
          Stream<CareEvent?>
        >
    with $FutureModifier<CareEvent?>, $StreamProvider<CareEvent?> {
  /// Dernier bain enregistré, toutes dates confondues.
  LatestBathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestBathProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestBathHash();

  @$internal
  @override
  $StreamProviderElement<CareEvent?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<CareEvent?> create(Ref ref) {
    return latestBath(ref);
  }
}

String _$latestBathHash() => r'3a16d359dc82fb99ad9ec0103b43d8561cff38e7';

/// Dernier biberon enregistré, toutes dates confondues.

@ProviderFor(latestBottle)
final latestBottleProvider = LatestBottleProvider._();

/// Dernier biberon enregistré, toutes dates confondues.

final class LatestBottleProvider
    extends
        $FunctionalProvider<
          AsyncValue<CareEvent?>,
          CareEvent?,
          Stream<CareEvent?>
        >
    with $FutureModifier<CareEvent?>, $StreamProvider<CareEvent?> {
  /// Dernier biberon enregistré, toutes dates confondues.
  LatestBottleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'latestBottleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$latestBottleHash();

  @$internal
  @override
  $StreamProviderElement<CareEvent?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<CareEvent?> create(Ref ref) {
    return latestBottle(ref);
  }
}

String _$latestBottleHash() => r'd0fc1f02cfc5b64cba03d7ec7888fc263f67c7b5';

/// Nombre d'événements demandés au journal ; grandit par pages.

@ProviderFor(TimelineLimit)
final timelineLimitProvider = TimelineLimitProvider._();

/// Nombre d'événements demandés au journal ; grandit par pages.
final class TimelineLimitProvider
    extends $NotifierProvider<TimelineLimit, int> {
  /// Nombre d'événements demandés au journal ; grandit par pages.
  TimelineLimitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timelineLimitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineLimitHash();

  @$internal
  @override
  TimelineLimit create() => TimelineLimit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$timelineLimitHash() => r'93cf26cd06a2cd8eb512ab419b1a27656975e708';

/// Nombre d'événements demandés au journal ; grandit par pages.

abstract class _$TimelineLimit extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Événements du journal, limités par [TimelineLimit].

@ProviderFor(timelineEvents)
final timelineEventsProvider = TimelineEventsProvider._();

/// Événements du journal, limités par [TimelineLimit].

final class TimelineEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CareEvent>>,
          List<CareEvent>,
          Stream<List<CareEvent>>
        >
    with $FutureModifier<List<CareEvent>>, $StreamProvider<List<CareEvent>> {
  /// Événements du journal, limités par [TimelineLimit].
  TimelineEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timelineEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<CareEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CareEvent>> create(Ref ref) {
    return timelineEvents(ref);
  }
}

String _$timelineEventsHash() => r'77b315c3d84ada1aaa5d2c231a7f089cee15fe8f';
