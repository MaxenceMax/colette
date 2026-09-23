import 'dart:async';

import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/health/domain/entities/medical_stage.dart';
import 'package:colette/features/health/domain/entities/medical_stage_status.dart';
import 'package:colette/features/health/domain/entities/medical_timeline.dart';
import 'package:colette/features/health/domain/entities/medical_visit.dart';
import 'package:colette/features/health/domain/entities/vaccine_code.dart';
import 'package:colette/features/health/domain/reference/medical_schedule.dart';
import 'package:colette/features/health/domain/repositories/medical_repository.dart';
import 'package:colette/features/health/domain/use_cases/reconcile_calendar.dart';
import 'package:colette/features/health/presentation/providers/health_providers.dart';
import 'package:colette/features/health/presentation/providers/health_sync.dart';
import 'package:colette/features/health/presentation/widgets/medical_stage_sheet.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter/cupertino.dart';
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

  setUpAll(() {
    registerFallbackValue(makeVisit(MedicalStageId.day8));
    registerFallbackValue(MedicalStageId.day8);
  });

  setUp(() {
    repo = MockMedicalRepository();
    when(() => repo.saveVisit(any(), any()))
        .thenAnswer((_) async => right(null));
  });

  List<Override> overrides() => [
    clockProvider.overrideWithValue(FixedClock(now)),
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

  MedicalTimelineEntry m2Entry([MedicalVisit? visit]) => MedicalTimelineEntry(
    stage: stageById(MedicalStageId.m2),
    dueFrom: DateTime(2026, 11, 1),
    dueUntil: DateTime(2026, 12, 1),
    status: MedicalStageStatus.due,
    visit: visit,
  );

  MedicalVisit saved() =>
      verify(() => repo.saveVisit('ABCDEFGH', captureAny())).captured.single
          as MedicalVisit;

  // La feuille et le champ « Note » (multiligne) ont chacun leur propre
  // Scrollable ; celui de la feuille est le premier descendant de la
  // `ListView` clé, stable même quand le contenu défile hors champ.
  Finder sheetScrollable() => find
      .descendant(
        of: find.byKey(const Key('medicalStageSheetList')),
        matching: find.byType(Scrollable),
      )
      .first;

  testWidgets('affiche les vaccins attendus, recommandés signalés', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(body: MedicalStageSheet(entry: m2Entry())),
      overrides: overrides(),
    );
    expect(find.text('Examen et vaccins des 2 mois'), findsOneWidget);
    expect(find.text('Hexavalent (DTCaP-Hib-HépB)'), findsOneWidget);
    expect(find.text('Pneumocoque'), findsOneWidget);
    expect(find.textContaining('recommandé'), findsOneWidget);
  });

  testWidgets('le RDV ne dépasse pas la fenêtre du calendrier', (tester) async {
    await pumpApp(
      tester,
      Scaffold(body: MedicalStageSheet(entry: m2Entry())),
      overrides: overrides(),
    );
    await tester.tap(find.text('Choisir la date du RDV'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.maximumDate, ReconcileCalendar.windowEnd(now));
  });

  testWidgets('cocher un vaccin avec son lot puis marquer faite', (
    tester,
  ) async {
    await pumpApp(
      tester,
      Scaffold(body: MedicalStageSheet(entry: m2Entry())),
      overrides: overrides(),
    );
    await tester.tap(find.text('Hexavalent (DTCaP-Hib-HépB)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'N° de lot (facultatif)'),
      'A123',
    );
    await tester.scrollUntilVisible(
      find.text('Marquer comme faite'),
      300,
      scrollable: sheetScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marquer comme faite'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Enregistrer'),
      300,
      scrollable: sheetScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final visit = saved();
    expect(visit.doneAt, now);
    expect(visit.vaccines[VaccineCode.hexavalent]!.lot, 'A123');
    expect(visit.vaccines[VaccineCode.hexavalent]!.givenAt, now);
    expect(visit.vaccines.containsKey(VaccineCode.pneumococcal), isFalse);
  });

  testWidgets('préremplit le praticien et retire le RDV', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: MedicalStageSheet(
          entry: m2Entry(
            makeVisit(
              MedicalStageId.m2,
              appointmentAt: DateTime(2026, 11, 20, 10),
              practitioner: 'Dr Martin',
              // Le praticien seul ne suffit pas à rendre la visite non vide
              // (`MedicalVisit.isEmpty`) : sans autre donnée, retirer le RDV
              // viderait totalement la visite et déclencherait une
              // suppression plutôt qu'un enregistrement.
              note: 'À rappeler pour le vaccin suivant',
            ),
          ),
        ),
      ),
      overrides: overrides(),
    );
    expect(find.text('Dr Martin'), findsOneWidget);
    await tester.tap(find.text('Retirer le RDV'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Enregistrer'),
      300,
      scrollable: sheetScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved().appointmentAt, isNull);
  });

  testWidgets('bouton inactif pendant l\'écriture', (tester) async {
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.saveVisit(any(), any()))
        .thenAnswer((_) => completer.future);
    await pumpApp(
      tester,
      Scaffold(
        body: MedicalStageSheet(
          entry: m2Entry(makeVisit(MedicalStageId.m2, note: 'x')),
        ),
      ),
      overrides: overrides(),
    );
    await tester.scrollUntilVisible(
      find.text('Enregistrer'),
      300,
      scrollable: sheetScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Enregistrer'),
          )
          .onPressed,
      isNull,
    );
    completer.complete(right(null));
    await tester.pumpAndSettle();
  });
}
