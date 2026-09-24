// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).

@ProviderFor(eventsRepository)
final eventsRepositoryProvider = EventsRepositoryProvider._();

/// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).

final class EventsRepositoryProvider
    extends
        $FunctionalProvider<
          EventsRepository,
          EventsRepository,
          EventsRepository
        >
    with $Provider<EventsRepository> {
  /// Sans état : `keepAlive` car consommé par `feedingPlanSyncProvider` (keepAlive).
  EventsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventsRepositoryProvider',
        isAutoDispose: false,
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

String _$eventsRepositoryHash() => r'bfba188f8d2e0c011dc6fab96e60d689a69bc71f';

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
        retry: noRetry,
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

String _$todayEventsHash() => r'f359f0ca324ebdeff433c4f843d1195b7a6ca4cf';

/// Événements d'hier et d'aujourd'hui (couvre toujours les 24 h glissantes).

@ProviderFor(recentEvents)
final recentEventsProvider = RecentEventsProvider._();

/// Événements d'hier et d'aujourd'hui (couvre toujours les 24 h glissantes).

final class RecentEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CareEvent>>,
          List<CareEvent>,
          Stream<List<CareEvent>>
        >
    with $FutureModifier<List<CareEvent>>, $StreamProvider<List<CareEvent>> {
  /// Événements d'hier et d'aujourd'hui (couvre toujours les 24 h glissantes).
  RecentEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'recentEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<CareEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CareEvent>> create(Ref ref) {
    return recentEvents(ref);
  }
}

String _$recentEventsHash() => r'5bdafd61775f31d407098848cfbe93fb1810e9fc';

/// Événements des 7 derniers jours civils, aujourd'hui inclus : suffisant pour savoir
/// si un soin espacé d'au plus [CareFrequency.maxEveryDays] jours est dû.

@ProviderFor(weekEvents)
final weekEventsProvider = WeekEventsProvider._();

/// Événements des 7 derniers jours civils, aujourd'hui inclus : suffisant pour savoir
/// si un soin espacé d'au plus [CareFrequency.maxEveryDays] jours est dû.

final class WeekEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CareEvent>>,
          List<CareEvent>,
          Stream<List<CareEvent>>
        >
    with $FutureModifier<List<CareEvent>>, $StreamProvider<List<CareEvent>> {
  /// Événements des 7 derniers jours civils, aujourd'hui inclus : suffisant pour savoir
  /// si un soin espacé d'au plus [CareFrequency.maxEveryDays] jours est dû.
  WeekEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'weekEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<CareEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CareEvent>> create(Ref ref) {
    return weekEvents(ref);
  }
}

String _$weekEventsHash() => r'3809598357a51a7a179bc23e547eccd7f2c4786c';

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
        retry: noRetry,
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

String _$latestBottleHash() => r'ee913ae507f3a582d397351c51232361d01c9fcd';

/// Nombre de changes enregistrés depuis [from] ; `0` sans foyer.
/// [from] doit être une valeur stable (`stock.countedAt`), jamais `DateTime.now()` :
/// chaque valeur distincte ouvre un listener Firestore séparé.

@ProviderFor(diaperChangesSince)
final diaperChangesSinceProvider = DiaperChangesSinceFamily._();

/// Nombre de changes enregistrés depuis [from] ; `0` sans foyer.
/// [from] doit être une valeur stable (`stock.countedAt`), jamais `DateTime.now()` :
/// chaque valeur distincte ouvre un listener Firestore séparé.

final class DiaperChangesSinceProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Nombre de changes enregistrés depuis [from] ; `0` sans foyer.
  /// [from] doit être une valeur stable (`stock.countedAt`), jamais `DateTime.now()` :
  /// chaque valeur distincte ouvre un listener Firestore séparé.
  DiaperChangesSinceProvider._({
    required DiaperChangesSinceFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: noRetry,
         name: r'diaperChangesSinceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaperChangesSinceHash();

  @override
  String toString() {
    return r'diaperChangesSinceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaperChangesSince(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaperChangesSinceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaperChangesSinceHash() =>
    r'0c7de1c0b4894a6529307922ba84c5186c76108b';

/// Nombre de changes enregistrés depuis [from] ; `0` sans foyer.
/// [from] doit être une valeur stable (`stock.countedAt`), jamais `DateTime.now()` :
/// chaque valeur distincte ouvre un listener Firestore séparé.

final class DiaperChangesSinceFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, DateTime> {
  DiaperChangesSinceFamily._()
    : super(
        retry: noRetry,
        name: r'diaperChangesSinceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Nombre de changes enregistrés depuis [from] ; `0` sans foyer.
  /// [from] doit être une valeur stable (`stock.countedAt`), jamais `DateTime.now()` :
  /// chaque valeur distincte ouvre un listener Firestore séparé.

  DiaperChangesSinceProvider call(DateTime from) =>
      DiaperChangesSinceProvider._(argument: from, from: this);

  @override
  String toString() => r'diaperChangesSinceProvider';
}

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
        retry: noRetry,
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

String _$timelineEventsHash() => r'fd3a923bca4e0a9a54eae8fa66cb4ed03135337b';
