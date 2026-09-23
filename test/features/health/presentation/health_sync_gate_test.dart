import 'dart:async';

import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/widgets/health_sync_gate.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

class MockHealthSync extends Mock implements HealthSync {}

void main() {
  testWidgets(
    'relance la sync à chaque émission des visites ou des RDV libres',
    (tester) async {
      final sync = MockHealthSync();
      when(sync.sync).thenAnswer((_) async {});
      final visits = StreamController<List<MedicalVisit>>();
      addTearDown(visits.close);
      final appointments = StreamController<List<CustomAppointment>>();
      addTearDown(appointments.close);

      await pumpApp(
        tester,
        const HealthSyncGate(child: SizedBox.shrink()),
        overrides: [
          // Sans foyer : seule l'écoute des visites peut lancer la sync.
          householdLocalStoreProvider.overrideWithValue(
            InMemoryHouseholdLocalStore(),
          ),
          healthSyncProvider.overrideWithValue(sync),
          medicalVisitsProvider.overrideWith((ref) => visits.stream),
          medicalAppointmentsProvider.overrideWith(
            (ref) => appointments.stream,
          ),
        ],
      );
      verifyNever(sync.sync);

      visits.add(const []);
      await tester.pump();
      verify(sync.sync).called(1);

      visits.add([makeVisit(MedicalStageId.m2, note: 'x')]);
      await tester.pump();
      verify(sync.sync).called(1);

      appointments.add([makeAppointment()]);
      await tester.pump();
      verify(sync.sync).called(1);
    },
  );
}
