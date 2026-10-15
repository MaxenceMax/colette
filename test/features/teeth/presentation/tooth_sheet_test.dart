import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/baby/domain/entities/baby_profile.dart';
import 'package:colette/features/baby/presentation/providers/baby_providers.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/teeth/domain/entities/tooth_id.dart';
import 'package:colette/features/teeth/domain/entities/tooth_record.dart';
import 'package:colette/features/teeth/presentation/providers/teeth_providers.dart';
import 'package:colette/features/teeth/presentation/widgets/tooth_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../../../helpers/pump_app.dart';
import '../teeth_factories.dart';

void main() {
  late MockTeethRepository repo;

  setUpAll(() {
    registerFallbackValue(makeTooth(51));
    registerFallbackValue(tooth(51));
  });

  setUp(() {
    repo = MockTeethRepository();
    when(() => repo.saveTooth(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => repo.deleteTooth(any(), any()))
        .thenAnswer((_) async => right(null));
  });

  Future<void> pumpSheet(
    WidgetTester tester,
    ToothId id, {
    ToothRecord? initial,
  }) => pumpApp(
    tester,
    Scaffold(
      body: ToothSheet(toothId: id, initial: initial),
    ),
    viewSize: const Size(390, 1200),
    overrides: [
      teethRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(FixedClock(DateTime(2027, 3, 10, 9))),
      householdLocalStoreProvider.overrideWithValue(
        InMemoryHouseholdLocalStore(householdCode: 'ABCDEFGH'),
      ),
      babyProfileProvider.overrideWith(
        (ref) => Stream.value(
          BabyProfile(name: 'C', birthDate: DateTime(2026, 9, 1)),
        ),
      ),
    ],
  );

  testWidgets('dent de lait vide : repère, sortie du jour et note', (
    tester,
  ) async {
    await pumpSheet(tester, tooth(71));
    expect(find.text('Incisive centrale du bas, à gauche'), findsOneWidget);
    expect(find.text('Dent n° 71'), findsOneWidget);
    expect(
      find.text('Sortie habituelle : 6-10 mois. Chute habituelle : 6-7 ans.'),
      findsOneWidget,
    );
    expect(find.text('Ajouter la date de chute'), findsOneWidget);
    await tester.tap(find.text('Ajouter la date de sortie'));
    await tester.pumpAndSettle();
    expect(find.text('10 mars 2027'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nuit agitée');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveTooth('ABCDEFGH', captureAny())).captured.single
            as ToothRecord;
    expect(saved.eruptedAt, DateTime(2027, 3, 10, 12));
    expect(saved.lostAt, isNull);
    expect(saved.note, 'Nuit agitée');
  });

  testWidgets('dent définitive : pas de date de chute', (tester) async {
    await pumpSheet(tester, tooth(36));
    expect(find.text('Sortie habituelle : 6-7 ans.'), findsOneWidget);
    expect(find.text('Ajouter la date de chute'), findsNothing);
    expect(find.text('Tout effacer'), findsNothing);
  });

  testWidgets('retirer la date de sortie', (tester) async {
    await pumpSheet(
      tester,
      tooth(71),
      initial: makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
    );
    expect(find.text('10 janv. 2027'), findsOneWidget);
    await tester.tap(find.text('Retirer la date de sortie'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter la date de sortie'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveTooth('ABCDEFGH', captureAny())).captured.single
            as ToothRecord;
    expect(saved.eruptedAt, isNull);
  });

  testWidgets('sortie proposée à la date de chute si elle est déjà notée', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      tooth(71),
      initial: makeTooth(71, lostAt: DateTime(2027, 2, 1, 12)),
    );
    await tester.tap(find.text('Ajouter la date de sortie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final saved =
        verify(() => repo.saveTooth('ABCDEFGH', captureAny())).captured.single
            as ToothRecord;
    expect(saved.eruptedAt, DateTime(2027, 2, 1, 12));
    expect(saved.lostAt, DateTime(2027, 2, 1, 12));
  });

  testWidgets('échec d\'écriture affiché', (tester) async {
    when(() => repo.saveTooth(any(), any()))
        .thenAnswer((_) async => left(const NetworkFailure()));
    await pumpSheet(tester, tooth(71));
    await tester.tap(find.text('Ajouter la date de sortie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final message = S.of(tester.element(find.byType(ToothSheet))).errorNetwork;
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('erreur de validation affichée, rien n\'est écrit', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      tooth(71),
      initial: makeTooth(
        71,
        eruptedAt: DateTime(2027, 3, 1, 12),
        lostAt: DateTime(2027, 2, 1, 12),
      ),
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.text('La chute ne peut pas précéder la sortie.'),
      findsOneWidget,
    );
    verifyNever(() => repo.saveTooth(any(), any()));
  });

  testWidgets('tout effacer demande confirmation puis supprime', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      tooth(71),
      initial: makeTooth(71, eruptedAt: DateTime(2027, 1, 10, 12)),
    );
    await tester.tap(find.text('Tout effacer'));
    await tester.pumpAndSettle();
    expect(find.text('Effacer cette dent ?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Tout effacer'),
      ),
    );
    await tester.pumpAndSettle();
    verify(() => repo.deleteTooth('ABCDEFGH', tooth(71))).called(1);
  });
}
