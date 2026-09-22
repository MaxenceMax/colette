import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/widgets/documents_root_section.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;

  setUp(() => repo = MockDocumentsRepository());

  Future<void> pumpSection(WidgetTester tester) => pumpApp(
    tester,
    Scaffold(
      body: ListView(
        padding: AppSpacing.md.horizontal,
        children: const [ColetteCardSurface(child: DocumentsRootSection())],
      ),
    ),
    overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    viewSize: const Size(375, 812),
  );

  testWidgets('sans dossier : « Aucun dossier choisi » et bouton', (
    tester,
  ) async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    await pumpSection(tester);
    expect(find.text('Aucun dossier choisi'), findsOneWidget);
    expect(find.text('Choisir le dossier partagé'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avec dossier : nom, changer et oublier', (tester) async {
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    await pumpSection(tester);
    expect(find.text('Dossier documents'), findsOneWidget);
    expect(find.text('Colette'), findsOneWidget);
    expect(find.text('Changer de dossier'), findsOneWidget);
    expect(find.text('Oublier le dossier'), findsOneWidget);
  });

  testWidgets('changer ouvre le sélecteur', (tester) async {
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    when(() => repo.pickRootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Autre')));
    await pumpSection(tester);
    await tester.tap(find.text('Changer de dossier'));
    await tester.pumpAndSettle();
    expect(find.text('Autre'), findsOneWidget);
  });

  testWidgets('oublier demande confirmation puis oublie', (tester) async {
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    when(() => repo.forgetRootFolder()).thenAnswer((_) async => right(null));
    await pumpSection(tester);
    await tester.tap(find.text('Oublier le dossier'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Colette n'affichera plus ce dossier. Vos fichiers ne sont pas supprimés.",
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(TextButton, 'Oublier le dossier').last,
    );
    await tester.pumpAndSettle();
    verify(() => repo.forgetRootFolder()).called(1);
    expect(find.text('Aucun dossier choisi'), findsOneWidget);
  });

  testWidgets(
    'changer en échec : SnackBar et le dossier précédent reste affiché',
    (tester) async {
      when(() => repo.rootFolder())
          .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
      when(() => repo.pickRootFolder()).thenAnswer((_) async {
        // Résout après une frame : laisse le temps au provider de passer par
        // AsyncLoading (donc à _RootRow d'être remplacée par l'indicateur)
        // avant que le résultat n'arrive, comme en conditions réelles.
        await Future<void>.delayed(Duration.zero);
        return left(const DocumentsFailure(DocumentsReason.io));
      });
      await pumpSection(tester);
      await tester.tap(find.text('Changer de dossier'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text("Impossible d'accéder à ce document"), findsOneWidget);
      expect(find.text('Colette'), findsOneWidget);
    },
  );

  testWidgets('oublier en échec : SnackBar et le dossier reste affiché', (
    tester,
  ) async {
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    when(() => repo.forgetRootFolder()).thenAnswer((_) async {
      // Résout après une frame : laisse le temps au provider de passer par
      // AsyncLoading (donc à _RootRow d'être remplacée par l'indicateur)
      // avant que le résultat n'arrive, comme en conditions réelles.
      await Future<void>.delayed(Duration.zero);
      return left(const DocumentsFailure(DocumentsReason.io));
    });
    await pumpSection(tester);
    await tester.tap(find.text('Oublier le dossier'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(TextButton, 'Oublier le dossier').last,
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text("Impossible d'accéder à ce document"), findsOneWidget);
    expect(find.text('Colette'), findsOneWidget);
  });

  testWidgets('annuler la confirmation ne fait rien', (tester) async {
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    await pumpSection(tester);
    await tester.tap(find.text('Oublier le dossier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    verifyNever(() => repo.forgetRootFolder());
    expect(find.text('Colette'), findsOneWidget);
  });
}
