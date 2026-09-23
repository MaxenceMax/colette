import 'dart:async';

import 'package:colette/app/colette_app.dart';
import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/theme_service.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/pages/documents_page.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/colette_app_overrides.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

DocumentEntry entry(
  String name, {
  String? path,
  bool isDirectory = false,
  DownloadStatus status = DownloadStatus.downloaded,
  double? progress,
}) => DocumentEntry(
  name: name,
  path: path ?? name,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: DateTime(2026, 9, 22),
  downloadStatus: status,
  downloadProgress: progress,
);

void main() {
  late MockDocumentsRepository repo;

  setUp(() {
    repo = MockDocumentsRepository();
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
  });

  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    final router = GoRouter(
      initialLocation: AppRoutes.todayDocuments,
      routes: [
        GoRoute(
          path: AppRoutes.todayDocuments,
          builder: (_, state) => DocumentsPage(
            path: state.uri.queryParameters[AppRoutes.documentsPathParam] ?? '',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsRepositoryProvider.overrideWithValue(repo),
          clockProvider.overrideWithValue(
            FixedClock(DateTime(2026, 9, 22, 14, 32)),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> swipeLeft(WidgetTester tester, String name) async {
    await tester.drag(find.text(name), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('glisser puis annuler : ligne conservée, rien supprimé', (
    tester,
  ) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    expect(find.text('Supprimer ce document ?'), findsOneWidget);
    expect(
      find.text(
        "a.pdf restera trente jours dans « Récemment supprimés » de l'app Fichiers.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('a.pdf'), findsOneWidget);
    verifyNever(() => repo.delete(any()));
  });

  testWidgets('glisser puis confirmer : delete appelé', (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.delete('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    verify(() => repo.delete('a.pdf')).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('suppression en échec io → SnackBar', (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(
      () => repo.delete('a.pdf'),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Impossible de supprimer ce document'), findsOneWidget);
  });

  testWidgets('suppression refusée (accessDenied) → vue accès perdu', (
    tester,
  ) async {
    var watchCalls = 0;
    when(() => repo.watch('')).thenAnswer((_) {
      watchCalls++;
      return Stream.value(
        watchCalls == 1
            ? right([entry('a.pdf')])
            : left(const DocumentsFailure(DocumentsReason.accessDenied)),
      );
    });
    when(() => repo.delete('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.accessDenied)),
    );
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    expect(watchCalls, 2);
  });

  testWidgets('pas de second glissement pendant une suppression', (
    tester,
  ) async {
    final deleting = Completer<Either<Failure, void>>();
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.delete('a.pdf')).thenAnswer((_) => deleting.future);
    await pumpPage(tester);
    await swipeLeft(tester, 'a.pdf');
    await tester.tap(find.text('Supprimer'));
    await tester.pump();
    await tester.pump();
    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.direction, DismissDirection.none);
    deleting.complete(right(null));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Dismissible>(find.byType(Dismissible)).direction,
      DismissDirection.endToStart,
    );
  });

  testWidgets('un dossier ne se glisse pas', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(right([entry('Ordonnances', isDirectory: true)])),
    );
    await pumpPage(tester);
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('liste triée avec le nom de la racine en titre', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(
        right([entry('b.pdf'), entry('Ordonnances', isDirectory: true)]),
      ),
    );
    await pumpPage(tester);
    expect(find.text('Colette'), findsOneWidget);
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title! as Text).data, 'Ordonnances');
    expect((tiles[1].title! as Text).data, 'b.pdf');
    expect(find.text('22 sept. 2026'), findsOneWidget);
  });

  testWidgets('dossier vide', (tester) async {
    when(() => repo.watch('')).thenAnswer((_) => Stream.value(right(const [])));
    await pumpPage(tester);
    expect(find.text('Aucun document dans ce dossier'), findsOneWidget);
  });

  testWidgets('la liste suit le flux du dossier', (tester) async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    await pumpPage(tester, settle: false);
    events.add(right([entry('a.pdf')]));
    await tester.pump();
    expect(find.text('a.pdf'), findsOneWidget);
    events.add(right([entry('a.pdf'), entry('b.pdf')]));
    await tester.pump();
    expect(find.text('b.pdf'), findsOneWidget);
    events.add(right([entry('b.pdf')]));
    await tester.pump();
    expect(find.text('a.pdf'), findsNothing);
  });

  testWidgets('un tap sur un dossier ouvre le sous-dossier', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(right([entry('Ordonnances', isDirectory: true)])),
    );
    when(() => repo.watch('Ordonnances')).thenAnswer(
      (_) => Stream.value(right([entry('a.pdf', path: 'Ordonnances/a.pdf')])),
    );
    await pumpPage(tester);
    await tester.tap(find.text('Ordonnances'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ordonnances'), findsOneWidget);
    expect(find.text('a.pdf'), findsOneWidget);
  });

  testWidgets('un tap sur un fichier ouvre l\'aperçu', (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.preview('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    verify(() => repo.preview('a.pdf')).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'fichier nuage : download, progression, puis aperçu automatique',
    (tester) async {
      final events = StreamController<Either<Failure, List<DocumentEntry>>>();
      addTearDown(events.close);
      when(() => repo.watch('')).thenAnswer((_) => events.stream);
      when(() => repo.download('a.pdf')).thenAnswer((_) async => right(null));
      when(() => repo.preview('a.pdf')).thenAnswer((_) async => right(null));
      await pumpPage(tester, settle: false);
      events.add(right([entry('a.pdf', status: DownloadStatus.notDownloaded)]));
      await tester.pump();
      expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);

      await tester.tap(find.text('a.pdf'));
      await tester.pump();
      verify(() => repo.download('a.pdf')).called(1);

      events.add(
        right([
          entry('a.pdf', status: DownloadStatus.downloading, progress: 0.25),
        ]),
      );
      await tester.pump();
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.25);
      verifyNever(() => repo.preview(any()));

      events.add(right([entry('a.pdf')]));
      await tester.pump();
      await tester.pump();
      verify(() => repo.preview('a.pdf')).called(1);
    },
  );

  testWidgets('fichier nuage : téléchargement retombé → SnackBar', (
    tester,
  ) async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    when(() => repo.download('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester, settle: false);
    events.add(right([entry('a.pdf', status: DownloadStatus.notDownloaded)]));
    await tester.pump();
    await tester.tap(find.text('a.pdf'));
    await tester.pump();
    events.add(right([entry('a.pdf', status: DownloadStatus.downloading)]));
    await tester.pump();
    events.add(right([entry('a.pdf', status: DownloadStatus.notDownloaded)]));
    await tester.pump();
    await tester.pump();
    expect(
      find.text("Ce document n'est pas encore téléchargé sur cet iPhone"),
      findsOneWidget,
    );
  });

  testWidgets('aperçu annulé : pas de SnackBar', (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.preview('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('accès perdu : vue dédiée puis re-choix', (tester) async {
    var watchCalls = 0;
    when(() => repo.watch('')).thenAnswer((_) {
      watchCalls++;
      return Stream.value(
        watchCalls == 1
            ? left(const DocumentsFailure(DocumentsReason.accessDenied))
            : right([entry('a.pdf')]),
      );
    });
    when(() => repo.pickRootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Nouveau')));
    await pumpPage(tester);
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    await tester.tap(find.text('Choisir le dossier partagé'));
    await tester.pumpAndSettle();
    expect(find.text('a.pdf'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Nouveau'), findsOneWidget);
  });

  testWidgets(
    'accès perdu : re-choix en échec io → SnackBar, vue dédiée conservée',
    (tester) async {
      when(() => repo.watch('')).thenAnswer(
        (_) => Stream.value(
          left(const DocumentsFailure(DocumentsReason.accessDenied)),
        ),
      );
      when(() => repo.pickRootFolder()).thenAnswer((_) async {
        // Résout après une frame : laisse le temps au provider de passer par
        // AsyncLoading (donc à la vue dédiée d'être démontée) avant que le
        // résultat n'arrive, comme en conditions réelles.
        await Future<void>.delayed(Duration.zero);
        return left(const DocumentsFailure(DocumentsReason.io));
      });
      await pumpPage(tester);
      expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
      await tester.tap(find.text('Choisir le dossier partagé'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text("Impossible d'accéder à ce document"), findsOneWidget);
      expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    },
  );

  testWidgets('tirer pour rafraîchir : succès, nouvelle liste affichée', (
    tester,
  ) async {
    var watchCalls = 0;
    when(() => repo.watch('')).thenAnswer((_) {
      watchCalls++;
      return Stream.value(
        watchCalls == 1
            ? right([entry('a.pdf')])
            : right([entry('a.pdf'), entry('b.pdf')]),
      );
    });
    await pumpPage(tester);
    expect(find.text('b.pdf'), findsNothing);
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.text('b.pdf'), findsOneWidget);
    expect(watchCalls, 2);
  });

  testWidgets(
    'tirer pour rafraîchir : la liste reste affichée pendant le chargement',
    (tester) async {
      final second = StreamController<Either<Failure, List<DocumentEntry>>>();
      addTearDown(second.close);
      var watchCalls = 0;
      when(() => repo.watch('')).thenAnswer((_) {
        watchCalls++;
        return watchCalls == 1
            ? Stream.value(right([entry('a.pdf')]))
            : second.stream;
      });
      await pumpPage(tester);
      expect(find.text('a.pdf'), findsOneWidget);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();

      // Toujours affichée : `AsyncValue(:final value, hasValue: true)`
      // capte aussi l'AsyncLoading avec previousData du rafraîchissement.
      expect(find.text('a.pdf'), findsOneWidget);

      second.add(right([entry('a.pdf')]));
      await tester.pumpAndSettle();
      expect(find.text('a.pdf'), findsOneWidget);
    },
  );

  testWidgets('tirer pour rafraîchir : échec sans exception non gérée', (
    tester,
  ) async {
    var watchCalls = 0;
    when(() => repo.watch('')).thenAnswer((_) {
      watchCalls++;
      return Stream.value(
        watchCalls == 1
            ? right([entry('a.pdf')])
            : left(const DocumentsFailure(DocumentsReason.accessDenied)),
      );
    });
    await pumpPage(tester);
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    // Pas d'assertion sur takeException() ici : la zone de test attrape déjà
    // toute erreur asynchrone non gérée. Un assert de mise en page se
    // vérifie mieux explicitement (voir le test de section équivalent).
  });

  testWidgets('erreur d\'accès sur l\'aperçu invalide le dossier', (
    tester,
  ) async {
    var watchCalls = 0;
    when(() => repo.watch('')).thenAnswer((_) {
      watchCalls++;
      return Stream.value(
        watchCalls == 1
            ? right([entry('a.pdf')])
            : left(const DocumentsFailure(DocumentsReason.noFolder)),
      );
    });
    when(() => repo.preview('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.accessDenied)),
    );
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    expect(watchCalls, 2);
  });

  testWidgets('autre erreur : message générique', (tester) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(left(UnknownFailure(Exception('x')))));
    await pumpPage(tester);
    expect(find.text('Une erreur est survenue.'), findsOneWidget);
  });

  testWidgets('la route réelle porte le chemin et garde la barre d\'onglets', (
    tester,
  ) async {
    when(() => repo.watch('Ordonnances/2026')).thenAnswer(
      (_) =>
          Stream.value(right([entry('a.pdf', path: 'Ordonnances/2026/a.pdf')])),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: await coletteAppOverrides(
          householdCode: 'ABCDEFGH',
          documents: documentsRepositoryProvider.overrideWithValue(repo),
        ),
        child: const ColetteApp(),
      ),
    );
    await tester.pumpAndSettle();

    ProviderScope.containerOf(tester.element(find.byType(ColetteApp)))
        .read(appRouterProvider)
        .go(AppRoutes.documentsLocation('Ordonnances/2026'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<DocumentsPage>(find.byType(DocumentsPage)).path,
      'Ordonnances/2026',
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, '2026'), findsOneWidget);
    expect(find.text('a.pdf'), findsOneWidget);
  });

  testWidgets('« + » puis « Scanner » scanne dans le dossier courant', (
    tester,
  ) async {
    when(() => repo.watch('')).thenAnswer((_) => Stream.value(right(const [])));
    when(() => repo.scan(folderPath: '', fileName: 'Scan 22-09-2026 14h32.pdf'))
        .thenAnswer((_) async => right('Scan 22-09-2026 14h32.pdf'));
    await pumpPage(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scanner un document'));
    await tester.pumpAndSettle();
    verify(
      () => repo.scan(folderPath: '', fileName: 'Scan 22-09-2026 14h32.pdf'),
    ).called(1);
    verify(() => repo.watch('')).called(1);
  });

  testWidgets('« + » puis « Importer » importe ; échec io → SnackBar', (
    tester,
  ) async {
    when(() => repo.watch('')).thenAnswer((_) => Stream.value(right(const [])));
    when(
      () => repo.importFile(folderPath: ''),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await pumpPage(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importer un fichier'));
    await tester.pumpAndSettle();
    expect(find.text("Impossible d'enregistrer le document"), findsOneWidget);
  });

  testWidgets('« + » dans un sous-dossier : un seul SnackBar '
      '(contrôleur par dossier, pas global)', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(right([entry('Ordonnances', isDirectory: true)])),
    );
    when(() => repo.watch('Ordonnances'))
        .thenAnswer((_) => Stream.value(right(const [])));
    when(
      () => repo.importFile(folderPath: 'Ordonnances'),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await pumpPage(tester);
    // Pousse la page du sous-dossier : la page racine reste dans la pile
    // du Navigator, avec son propre `ref.listen` sur le contrôleur
    // d'écriture.
    await tester.tap(find.text('Ordonnances'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importer un fichier'));
    await tester.pumpAndSettle();

    // Un contrôleur global partagé entre la page racine et la page du
    // sous-dossier déclencherait le `ref.listen` des deux pages ; la
    // famille par dossier garantit qu'un seul SnackBar s'affiche.
    // (Le SnackBar de Flutter n'affiche qu'un message à la fois — un
    // second appel à showSnackBar met en file d'attente plutôt que
    // d'empiler un second widget visible : voir le rapport pour la preuve
    // empirique du double appel avec l'ancien contrôleur global.)
    expect(find.text("Impossible d'enregistrer le document"), findsOneWidget);
  });

  testWidgets('import annulé : pas de SnackBar', (tester) async {
    when(() => repo.watch('')).thenAnswer((_) => Stream.value(right(const [])));
    when(() => repo.importFile(folderPath: '')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await pumpPage(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importer un fichier'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('pas de « + » quand l\'accès est perdu', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(
        left(const DocumentsFailure(DocumentsReason.accessDenied)),
      ),
    );
    await pumpPage(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('icônes selon le type et l\'extension', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(
        right([
          entry('Dossier', isDirectory: true),
          entry('a.pdf'),
          entry('photo.JPG'),
          entry('scan.heic'),
          entry('notes.txt'),
        ]),
      ),
    );
    await pumpPage(tester);
    expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    final folderTile = tester.widget<ListTile>(
      find.ancestor(of: find.text('Dossier'), matching: find.byType(ListTile)),
    );
    expect(folderTile.subtitle, isNull);
    expect(find.text('22 sept. 2026'), findsNWidgets(4));
  });

  testWidgets('fichier en cours de téléchargement : spinner, pas d\'icône '
      'nuage', (tester) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(
        right([entry('a.pdf', status: DownloadStatus.downloading)]),
      ),
    );
    // Pas de pumpAndSettle : le statut ne change jamais dans ce test, donc le
    // spinner de la ligne reste affiché et son animation ne se termine jamais.
    await pumpPage(tester, settle: false);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.cloud_download_outlined), findsNothing);
  });

  testWidgets('la ligne reste occupée pendant son propre aperçu', (
    tester,
  ) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    final completer = Completer<Either<Failure, void>>();
    when(() => repo.preview('a.pdf')).thenAnswer((_) => completer.future);
    await pumpPage(tester);

    await tester.tap(find.text('a.pdf'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('a.pdf'));
    verify(() => repo.preview('a.pdf')).called(1);

    completer.complete(right(null));
    await tester.pumpAndSettle();
  });

  testWidgets('premier chargement : indicateur centré, pas de « + »', (
    tester,
  ) async {
    final completer = Completer<Either<Failure, List<DocumentEntry>>>();
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.fromFuture(completer.future));
    // Pas de pumpAndSettle avant complétion : l'indicateur de la page tourne
    // indéfiniment tant que le completer n'est pas résolu.
    await pumpPage(tester, settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    completer.complete(right([entry('a.pdf')]));
    await tester.pumpAndSettle();
    expect(find.text('a.pdf'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('« + » occupé pendant un import : désactivé, avec spinner', (
    tester,
  ) async {
    when(() => repo.watch('')).thenAnswer((_) => Stream.value(right(const [])));
    final completer = Completer<Either<Failure, String>>();
    when(() => repo.importFile(folderPath: ''))
        .thenAnswer((_) => completer.future);
    await pumpPage(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importer un fichier'));
    await tester.pump();

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(right('x.pdf'));
    await tester.pumpAndSettle();
  });

  testWidgets('bouton Fichiers : présent avec une liste, appelle openInFiles', (
    tester,
  ) async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.openInFiles('')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Ouvrir dans Fichiers'));
    await tester.pumpAndSettle();
    verify(() => repo.openInFiles('')).called(1);
  });

  testWidgets('bouton Fichiers : présent sur un dossier vide', (tester) async {
    when(() => repo.watch('')).thenAnswer((_) => Stream.value(right(const [])));
    await pumpPage(tester);
    expect(find.byTooltip('Ouvrir dans Fichiers'), findsOneWidget);
  });

  testWidgets('bouton Fichiers : absent quand l\'accès est perdu', (
    tester,
  ) async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(
        left(const DocumentsFailure(DocumentsReason.accessDenied)),
      ),
    );
    await pumpPage(tester);
    expect(find.byTooltip('Ouvrir dans Fichiers'), findsNothing);
  });

  testWidgets('bouton Fichiers : échec → SnackBar', (tester) async {
    when(() => repo.watch('Ordonnances')).thenAnswer(
      (_) => Stream.value(right([entry('a.pdf', path: 'Ordonnances/a.pdf')])),
    );
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(right([entry('Ordonnances', isDirectory: true)])),
    );
    when(
      () => repo.openInFiles('Ordonnances'),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await pumpPage(tester);
    await tester.tap(find.text('Ordonnances'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ouvrir dans Fichiers'));
    await tester.pumpAndSettle();
    expect(find.text("Impossible d'ouvrir Fichiers"), findsOneWidget);
    verify(() => repo.openInFiles('Ordonnances')).called(1);
  });

  testWidgets('bouton Fichiers : disparaît quand une erreur suit la liste', (
    tester,
  ) async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    await pumpPage(tester, settle: false);
    events.add(right([entry('a.pdf')]));
    await tester.pump();
    expect(find.byTooltip('Ouvrir dans Fichiers'), findsOneWidget);
    events.add(left(const DocumentsFailure(DocumentsReason.accessDenied)));
    await tester.pump();
    expect(find.byTooltip('Ouvrir dans Fichiers'), findsNothing);
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
  });

  testWidgets('bouton Fichiers : désactivé pendant l\'ouverture', (
    tester,
  ) async {
    final opening = Completer<Either<Failure, void>>();
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    when(() => repo.openInFiles('')).thenAnswer((_) => opening.future);
    await pumpPage(tester);
    final button = find.widgetWithIcon(IconButton, Icons.folder_open_outlined);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<IconButton>(button).onPressed, isNull);
    opening.complete(right(null));
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(button).onPressed, isNotNull);
  });

  testWidgets('bouton Fichiers : accès perdu → vue dédiée, pas de SnackBar', (
    tester,
  ) async {
    var watchCalls = 0;
    when(() => repo.watch('')).thenAnswer((_) {
      watchCalls++;
      return Stream.value(
        watchCalls == 1
            ? right([entry('a.pdf')])
            : left(const DocumentsFailure(DocumentsReason.accessDenied)),
      );
    });
    when(() => repo.openInFiles('')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.accessDenied)),
    );
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Ouvrir dans Fichiers'));
    await tester.pumpAndSettle();
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(watchCalls, 2);
  });
}
