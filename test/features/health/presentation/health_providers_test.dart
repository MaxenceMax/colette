import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/firebase/firebase_providers.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/appointment_proximity.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../health_factories.dart';

void main() {
  const code = 'ABCDEFGH';

  test('medicalVisitsProvider lit les visites du foyer', () async {
    final db = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: code),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(medicalRepositoryProvider)
        .saveVisit(code, makeVisit(MedicalStageId.m2, note: 'x'));
    final sub = container.listen(medicalVisitsProvider, (_, _) {});
    addTearDown(sub.close);

    expect(
      (await container.read(medicalVisitsProvider.future)).single.stageId,
      MedicalStageId.m2,
    );
  });

  test(
    'medicalTimelineProvider attend visites et RDV libres avant de calculer',
    () async {
      final visits = StreamController<List<MedicalVisit>>();
      addTearDown(visits.close);
      final appointments = StreamController<List<CustomAppointment>>();
      addTearDown(appointments.close);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 10, 20))),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          babyProfileProvider.overrideWith(
            (ref) => Stream.value(
              BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
            ),
          ),
          medicalVisitsProvider.overrideWith((ref) => visits.stream),
          medicalAppointmentsProvider.overrideWith(
            (ref) => appointments.stream,
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(medicalTimelineProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(babyProfileProvider.future);

      expect(container.read(medicalTimelineProvider), isNull);

      visits.add(const []);
      await container.read(medicalVisitsProvider.future);
      expect(container.read(medicalTimelineProvider), isNull);

      appointments.add([makeAppointment()]);
      await container.read(medicalAppointmentsProvider.future);
      expect(container.read(medicalTimelineProvider)?.entries, isNotEmpty);
      expect(
        container.read(medicalTimelineProvider)?.appointments,
        hasLength(1),
      );
    },
  );

  group('nextAppointmentProximityProvider', () {
    ProviderContainer containerWith(MedicalTimeline? timeline) {
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(
            FixedClock(DateTime(2026, 10, 20, 9)),
          ),
          minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
          medicalTimelineProvider.overrideWithValue(timeline),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('null sans frise ou sans RDV programmé', () {
      expect(
        containerWith(null).read(nextAppointmentProximityProvider),
        isNull,
      );
      final noRdv = MedicalTimeline(
        entries: [entry(MedicalStageId.m2, MedicalStageStatus.due)],
      );
      expect(
        containerWith(noRdv).read(nextAppointmentProximityProvider),
        isNull,
      );
    });

    test('proximité du prochain RDV programmé', () {
      final timeline = MedicalTimeline(
        entries: [
          entry(
            MedicalStageId.m2,
            MedicalStageStatus.scheduled,
            appointmentAt: DateTime(2026, 10, 23, 10),
          ),
        ],
      );
      expect(
        containerWith(timeline).read(nextAppointmentProximityProvider),
        AppointmentProximity.soon,
      );
    });
  });
}
