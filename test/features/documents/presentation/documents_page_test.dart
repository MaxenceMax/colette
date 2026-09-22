import 'package:colette/app/colette_app.dart';
import 'package:colette/app/router/app_router.dart';
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
}) => DocumentEntry(
  name: name,
  path: path ?? name,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: DateTime(2026, 9, 22),
  downloadStatus: status,
);

void main() {
  late MockDocumentsRepository repo;

  setUp(() {
    repo = MockDocumentsRepository();
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
  });

  Future<void> pumpPage(WidgetTester tester) async {
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
  }

  testWidgets('liste triée avec le nom de la racine en titre', (tester) async {
    when(() => repo.list('')).thenAnswer(
      (_) async =>
          right([entry('b.pdf'), entry('Ordonnances', isDirectory: true)]),
    );
    await pumpPage(tester);
    expect(find.text('Colette'), findsOneWidget);
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles[0].title! as Text).data, 'Ordonnances');
    expect((tiles[1].title! as Text).data, 'b.pdf');
    expect(find.text('22 sept. 2026'), findsOneWidget);
  });

  testWidgets('dossier vide', (tester) async {
    when(() => repo.list('')).thenAnswer((_) async => right(const []));
    await pumpPage(tester);
    expect(find.text('Aucun document dans ce dossier'), findsOneWidget);
  });

  testWidgets('un tap sur un dossier ouvre le sous-dossier', (tester) async {
    when(
      () => repo.list(''),
    ).thenAnswer((_) async => right([entry('Ordonnances', isDirectory: true)]));
    when(() => repo.list('Ordonnances')).thenAnswer(
      (_) async => right([entry('a.pdf', path: 'Ordonnances/a.pdf')]),
    );
    await pumpPage(tester);
    await tester.tap(find.text('Ordonnances'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ordonnances'), findsOneWidget);
    expect(find.text('a.pdf'), findsOneWidget);
  });

  testWidgets('un tap sur un fichier ouvre l\'aperçu', (tester) async {
    when(() => repo.list('')).thenAnswer((_) async => right([entry('a.pdf')]));
    when(() => repo.preview('a.pdf')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    verify(() => repo.preview('a.pdf')).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('fichier nuage : icône, et échec io → SnackBar', (tester) async {
    when(() => repo.list('')).thenAnswer(
      (_) async =>
          right([entry('a.pdf', status: DownloadStatus.notDownloaded)]),
    );
    when(
      () => repo.preview('a.pdf'),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await pumpPage(tester);
    expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(
      find.text("Ce document n'est pas encore téléchargé sur cet iPhone"),
      findsOneWidget,
    );
  });

  testWidgets('aperçu annulé : pas de SnackBar', (tester) async {
    when(() => repo.list('')).thenAnswer((_) async => right([entry('a.pdf')]));
    when(() => repo.preview('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('accès perdu : vue dédiée puis re-choix', (tester) async {
    var listCalls = 0;
    when(() => repo.list('')).thenAnswer((_) async {
      listCalls++;
      return listCalls == 1
          ? left(const DocumentsFailure(DocumentsReason.accessDenied))
          : right([entry('a.pdf')]);
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

  testWidgets('tirer pour rafraîchir : succès, nouvelle liste affichée', (
    tester,
  ) async {
    var listCalls = 0;
    when(() => repo.list('')).thenAnswer((_) async {
      listCalls++;
      return listCalls == 1
          ? right([entry('a.pdf')])
          : right([entry('a.pdf'), entry('b.pdf')]);
    });
    await pumpPage(tester);
    expect(find.text('b.pdf'), findsNothing);
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.text('b.pdf'), findsOneWidget);
    expect(listCalls, 2);
  });

  testWidgets('tirer pour rafraîchir : échec sans exception non gérée', (
    tester,
  ) async {
    var listCalls = 0;
    when(() => repo.list('')).thenAnswer((_) async {
      listCalls++;
      return listCalls == 1
          ? right([entry('a.pdf')])
          : left(const DocumentsFailure(DocumentsReason.accessDenied));
    });
    await pumpPage(tester);
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erreur d\'accès sur l\'aperçu invalide le dossier', (
    tester,
  ) async {
    var listCalls = 0;
    when(() => repo.list('')).thenAnswer((_) async {
      listCalls++;
      return listCalls == 1
          ? right([entry('a.pdf')])
          : left(const DocumentsFailure(DocumentsReason.noFolder));
    });
    when(() => repo.preview('a.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.accessDenied)),
    );
    await pumpPage(tester);
    await tester.tap(find.text('a.pdf'));
    await tester.pumpAndSettle();
    expect(find.text("Colette n'a plus accès au dossier"), findsOneWidget);
    expect(listCalls, 2);
  });

  testWidgets('autre erreur : message générique', (tester) async {
    when(() => repo.list(''))
        .thenAnswer((_) async => left(UnknownFailure(Exception('x'))));
    await pumpPage(tester);
    expect(find.text('Une erreur est survenue.'), findsOneWidget);
  });

  testWidgets('la route réelle porte le chemin et garde la barre d\'onglets', (
    tester,
  ) async {
    when(() => repo.list('Ordonnances/2026')).thenAnswer(
      (_) async => right([entry('a.pdf', path: 'Ordonnances/2026/a.pdf')]),
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
}
