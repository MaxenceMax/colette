// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sans état : `keepAlive` car lu par `healthSyncProvider` (keepAlive).

@ProviderFor(medicalRepository)
final medicalRepositoryProvider = MedicalRepositoryProvider._();

/// Sans état : `keepAlive` car lu par `healthSyncProvider` (keepAlive).

final class MedicalRepositoryProvider
    extends
        $FunctionalProvider<
          MedicalRepository,
          MedicalRepository,
          MedicalRepository
        >
    with $Provider<MedicalRepository> {
  /// Sans état : `keepAlive` car lu par `healthSyncProvider` (keepAlive).
  MedicalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicalRepositoryHash();

  @$internal
  @override
  $ProviderElement<MedicalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MedicalRepository create(Ref ref) {
    return medicalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicalRepository>(value),
    );
  }
}

String _$medicalRepositoryHash() => r'8ebd90567d97281d191bd3962dbd0cbe0b2b8dad';

/// Pont Swift du Calendrier iOS.

@ProviderFor(calendarRepository)
final calendarRepositoryProvider = CalendarRepositoryProvider._();

/// Pont Swift du Calendrier iOS.

final class CalendarRepositoryProvider
    extends
        $FunctionalProvider<
          CalendarRepository,
          CalendarRepository,
          CalendarRepository
        >
    with $Provider<CalendarRepository> {
  /// Pont Swift du Calendrier iOS.
  CalendarRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalendarRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalendarRepository create(Ref ref) {
    return calendarRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarRepository>(value),
    );
  }
}

String _$calendarRepositoryHash() =>
    r'5404927964acbe43dbdb57de5920de61e4afa3be';

/// Visites médicales du foyer courant.

@ProviderFor(medicalVisits)
final medicalVisitsProvider = MedicalVisitsProvider._();

/// Visites médicales du foyer courant.

final class MedicalVisitsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MedicalVisit>>,
          List<MedicalVisit>,
          Stream<List<MedicalVisit>>
        >
    with
        $FutureModifier<List<MedicalVisit>>,
        $StreamProvider<List<MedicalVisit>> {
  /// Visites médicales du foyer courant.
  MedicalVisitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'medicalVisitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicalVisitsHash();

  @$internal
  @override
  $StreamProviderElement<List<MedicalVisit>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MedicalVisit>> create(Ref ref) {
    return medicalVisits(ref);
  }
}

String _$medicalVisitsHash() => r'b4d185df76a166b161f9570afc29918cff3e2bd3';

/// RDV libres du foyer courant.

@ProviderFor(medicalAppointments)
final medicalAppointmentsProvider = MedicalAppointmentsProvider._();

/// RDV libres du foyer courant.

final class MedicalAppointmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CustomAppointment>>,
          List<CustomAppointment>,
          Stream<List<CustomAppointment>>
        >
    with
        $FutureModifier<List<CustomAppointment>>,
        $StreamProvider<List<CustomAppointment>> {
  /// RDV libres du foyer courant.
  MedicalAppointmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'medicalAppointmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicalAppointmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<CustomAppointment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CustomAppointment>> create(Ref ref) {
    return medicalAppointments(ref);
  }
}

String _$medicalAppointmentsHash() =>
    r'5b81eea43ad21feabad595afe7af8ab9b155832f';

/// Frise du suivi médical ; `null` sans profil ou tant que visites et RDV
/// libres ne sont pas lus (sinon « En retard » s'afficherait un instant au
/// démarrage).

@ProviderFor(medicalTimeline)
final medicalTimelineProvider = MedicalTimelineProvider._();

/// Frise du suivi médical ; `null` sans profil ou tant que visites et RDV
/// libres ne sont pas lus (sinon « En retard » s'afficherait un instant au
/// démarrage).

final class MedicalTimelineProvider
    extends
        $FunctionalProvider<
          MedicalTimeline?,
          MedicalTimeline?,
          MedicalTimeline?
        >
    with $Provider<MedicalTimeline?> {
  /// Frise du suivi médical ; `null` sans profil ou tant que visites et RDV
  /// libres ne sont pas lus (sinon « En retard » s'afficherait un instant au
  /// démarrage).
  MedicalTimelineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicalTimelineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicalTimelineHash();

  @$internal
  @override
  $ProviderElement<MedicalTimeline?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MedicalTimeline? create(Ref ref) {
    return medicalTimeline(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicalTimeline? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicalTimeline?>(value),
    );
  }
}

String _$medicalTimelineHash() => r'd3c2615d87b3fb0a1619249723e497cbcbcb5c8a';

/// Proximité du prochain RDV programmé ; `null` sans frise ou sans RDV.
/// Suit [todayProvider] et le prochain RDV : change au changement de jour ou
/// de RDV.

@ProviderFor(nextAppointmentProximity)
final nextAppointmentProximityProvider = NextAppointmentProximityProvider._();

/// Proximité du prochain RDV programmé ; `null` sans frise ou sans RDV.
/// Suit [todayProvider] et le prochain RDV : change au changement de jour ou
/// de RDV.

final class NextAppointmentProximityProvider
    extends
        $FunctionalProvider<
          AppointmentProximity?,
          AppointmentProximity?,
          AppointmentProximity?
        >
    with $Provider<AppointmentProximity?> {
  /// Proximité du prochain RDV programmé ; `null` sans frise ou sans RDV.
  /// Suit [todayProvider] et le prochain RDV : change au changement de jour ou
  /// de RDV.
  NextAppointmentProximityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextAppointmentProximityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextAppointmentProximityHash();

  @$internal
  @override
  $ProviderElement<AppointmentProximity?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppointmentProximity? create(Ref ref) {
    return nextAppointmentProximity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppointmentProximity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppointmentProximity?>(value),
    );
  }
}

String _$nextAppointmentProximityHash() =>
    r'ac494b876d29139c42772ff64afeab3fd599bbcc';
