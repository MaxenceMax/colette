import 'dart:async';

import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/widgets/documents_card.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;

  setUp(() => repo = MockDocumentsRepository());

  Future<void> pumpCard(WidgetTester tester) => pumpApp(
    tester,
    const Scaffold(body: DocumentsCard()),
    overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
  );

  testWidgets('sans dossier : invitation à choisir', (tester) async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    await pumpCard(tester);
    expect(find.text('Retrouvez vos ordonnances et documents'), findsOneWidget);
    expect(find.text('Choisir le dossier partagé'), findsOneWidget);
  });

  testWidgets('en erreur : même rendu que sans dossier', (tester) async {
    when(
      () => repo.rootFolder(),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await pumpCard(tester);
    expect(find.text('Choisir le dossier partagé'), findsOneWidget);
  });

  testWidgets('« Choisir » ouvre le sélecteur puis affiche le dossier', (
    tester,
  ) async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    when(() => repo.pickRootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    await pumpCard(tester);
    await tester.tap(find.text('Choisir le dossier partagé'));
    await tester.pumpAndSettle();
    verify(() => repo.pickRootFolder()).called(1);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Colette'), findsOneWidget);
  });

  testWidgets('« Choisir » en échec : SnackBar et carte de choix conservée', (
    tester,
  ) async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    when(() => repo.pickRootFolder()).thenAnswer((_) async {
      // Résout après une frame : laisse le temps au provider de passer par
      // AsyncLoading (donc à _PickCard d'être remplacée par _LoadingCard)
      // avant que le résultat n'arrive, comme en conditions réelles.
      await Future<void>.delayed(Duration.zero);
      return left(const DocumentsFailure(DocumentsReason.io));
    });
    await pumpCard(tester);
    await tester.tap(find.text('Choisir le dossier partagé'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text("Impossible d'accéder à ce document"), findsOneWidget);
    expect(find.text('Choisir le dossier partagé'), findsOneWidget);
  });

  testWidgets('avec dossier : un tap ouvre la page Documents', (tester) async {
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: DocumentsCard()),
        ),
        GoRoute(
          path: AppRoutes.todayDocuments,
          builder: (_, _) => const Scaffold(body: Text('documents-marker')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ColetteCardSurface));
    await tester.pumpAndSettle();
    expect(find.text('documents-marker'), findsOneWidget);
  });

  testWidgets('pendant le chargement : indicateur, titre, pas de tap', (
    tester,
  ) async {
    final completer = Completer<Either<Failure, DocumentRoot?>>();
    when(() => repo.rootFolder()).thenAnswer((_) => completer.future);
    // Pas de pumpApp/pumpAndSettle : l'indicateur de la carte tourne
    // indéfiniment tant que le completer n'est pas résolu.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const Scaffold(body: DocumentsCard()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(
      tester.widget<ColetteCardSurface>(find.byType(ColetteCardSurface)).onTap,
      isNull,
    );

    completer.complete(right(const DocumentRoot(name: 'Colette')));
    await tester.pumpAndSettle();
  });
}
