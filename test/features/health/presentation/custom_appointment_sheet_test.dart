import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/custom_appointment.dart';
import 'package:colette/features/health/domain/entities/custom_vaccine.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/widgets/custom_appointment_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../health_factories.dart';

class MockMedicalRepository extends Mock implements MedicalRepository {}

void main() {
  late MockMedicalRepository repo;
  final now = DateTime(2026, 11, 10, 12);

  setUpAll(() => registerFallbackValue(makeAppointment()));

  setUp(() {
    repo = MockMedicalRepository();
    when(() => repo.saveAppointment(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => repo.deleteAppointment(any(), any()))
        .thenAnswer((_) async => right(null));
  });

  List<Override> overrides() => [
    clockProvider.overrideWithValue(FixedClock(now)),
    idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new-id')),
    babyProfileProvider.overrideWith(
      (ref) => Stream.value(
        BabyProfile(name: 'Colette', birthDate: DateTime(2026, 9, 1)),
      ),
    ),
    medicalRepositoryProvider.overrideWithValue(repo),
    healthSyncProvider.overrideWithValue(const NoopHealthSync()),
    householdLocalStoreProvider.overrideWithValue(
      InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
    ),
  ];

  CustomAppointment saved() =>
      verify(() => repo.saveAppointment('ABCDEFGH', captureAny()))
              .captured
              .single
          as CustomAppointment;

  Finder sheetScrollable() => find
      .descendant(
        of: find.byKey(const Key('customAppointmentSheetList')),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> tapAfterScroll(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 300, scrollable: sheetScrollable());
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'création : titre vide refusé, puis enregistré avec l\'id généré',
    (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: CustomAppointmentSheet()),
        overrides: overrides(),
      );
      expect(find.text('Nouveau rendez-vous'), findsOneWidget);
      await tapAfterScroll(tester, find.text('Enregistrer'));
      verifyNever(() => repo.saveAppointment(any(), any()));

      final titleField = find.widgetWithText(
        TextField,
        'Titre (ostéopathe, ORL, pédiatre…)',
      );
      await tester.scrollUntilVisible(
        titleField,
        -300,
        scrollable: sheetScrollable(),
      );
      await tester.pumpAndSettle();
      await tester.enterText(titleField, 'Ostéopathe');
      await tapAfterScroll(tester, find.text('Enregistrer'));
      final rdv = saved();
      expect(rdv.id, 'new-id');
      expect(rdv.title, 'Ostéopathe');
      expect(rdv.appointmentAt, DateTime(2026, 11, 10, 13));
    },
  );

  testWidgets('vaccin connu et vaccin libre, visite faite', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: CustomAppointmentSheet(
          initial: makeAppointment(appointmentAt: DateTime(2026, 11, 3, 10)),
        ),
      ),
      overrides: overrides(),
    );
    await tapAfterScroll(
      tester,
      find.text('ROR (rougeole, oreillons, rubéole)'),
    );
    await tapAfterScroll(tester, find.text('Ajouter un autre vaccin'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du vaccin'),
      'Grippe',
    );
    await tapAfterScroll(tester, find.text('Marquer comme faite'));
    await tapAfterScroll(tester, find.text('Enregistrer'));
    final rdv = saved();
    expect(rdv.doneAt, DateTime(2026, 11, 3, 10));
    expect(rdv.vaccines, [
      CustomVaccine(code: VaccineCode.mmr, givenAt: DateTime(2026, 11, 3, 10)),
      CustomVaccine(name: 'Grippe', givenAt: DateTime(2026, 11, 3, 10)),
    ]);
  });

  testWidgets('suppression confirmée', (tester) async {
    await pumpApp(
      tester,
      Scaffold(body: CustomAppointmentSheet(initial: makeAppointment())),
      overrides: overrides(),
    );
    await tapAfterScroll(tester, find.text('Supprimer'));
    expect(find.text('Supprimer ce rendez-vous ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.deleteAppointment(any(), any()));

    await tapAfterScroll(tester, find.text('Supprimer'));
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer').last);
    await tester.pumpAndSettle();
    verify(() => repo.deleteAppointment('ABCDEFGH', 'rdv-1')).called(1);
  });

  testWidgets('bouton inactif pendant l\'écriture', (tester) async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.saveAppointment(any(), any()))
        .thenAnswer((_) => completer.future);
    await pumpApp(
      tester,
      Scaffold(body: CustomAppointmentSheet(initial: makeAppointment())),
      overrides: overrides(),
    );
    await tapAfterScroll(tester, find.text('Enregistrer'));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    completer.complete(right(null));
    await tester.pumpAndSettle();
  });
}
