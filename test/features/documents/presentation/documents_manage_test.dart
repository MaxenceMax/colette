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
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

DocumentEntry _entry(String path, {bool isDirectory = false}) => DocumentEntry(
  name: path.split('/').last,
  path: path,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: DateTime(2026, 9, 24),
  downloadStatus: DownloadStatus.downloaded,
);

void main() {
  late MockDocumentsRepository repo;

  setUp(() {
    repo = MockDocumentsRepository();
    when(() => repo.rootFolder())
        .thenAnswer((_) async => right(const DocumentRoot(name: 'Colette')));
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(
        right([
          _entry('Santé', isDirectory: true),
          _entry('Papiers', isDirectory: true),
          _entry('a.pdf'),
        ]),
      ),
    );
    when(() => repo.watch('Santé')).thenAnswer(
      (_) => Stream.value(right([_entry('Santé/Vaccins', isDirectory: true)])),
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: const ThemeService().light(),
          locale: const Locale('fr'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const DocumentsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> longPressAction(
    WidgetTester tester,
    String name,
    String action,
  ) async {
    await tester.longPress(find.text(name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  TextButton button(WidgetTester tester, String label) => tester.widget(
    find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
  );

  testWidgets('« + » puis « Nouveau dossier » crée dans le dossier courant', (
    tester,
  ) async {
    when(() => repo.createFolder(folderPath: '', name: 'Vaccins'))
        .thenAnswer((_) async => right('Vaccins'));
    await pumpPage(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouveau dossier'));
    await tester.pumpAndSettle();
    expect(button(tester, 'Créer').onPressed, isNull);
    await tester.enterText(find.byType(TextField), ' Vaccins ');
    await tester.pump();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    verify(() => repo.createFolder(folderPath: '', name: 'Vaccins')).called(1);
  });

  testWidgets('nom invalide : message et bouton inactif', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouveau dossier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a/b');
    await tester.pump();
    expect(find.textContaining('Nom invalide'), findsOneWidget);
    expect(button(tester, 'Créer').onPressed, isNull);
  });

  testWidgets('appui long puis « Renommer » garde l\'extension', (
    tester,
  ) async {
    when(() => repo.rename(path: 'a.pdf', newName: 'ordonnance.pdf'))
        .thenAnswer((_) async => right('ordonnance.pdf'));
    await pumpPage(tester);
    await longPressAction(tester, 'a.pdf', 'Renommer');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'a');
    expect(field.decoration!.suffixText, '.pdf');
    await tester.enterText(find.byType(TextField), 'ordonnance');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    verify(() => repo.rename(path: 'a.pdf', newName: 'ordonnance.pdf'))
        .called(1);
  });

  testWidgets('renommer vers un nom pris → SnackBar', (tester) async {
    when(() => repo.rename(path: 'Santé', newName: 'Papiers')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.nameTaken)),
    );
    await pumpPage(tester);
    await longPressAction(tester, 'Santé', 'Renommer');
    await tester.enterText(find.byType(TextField), 'Papiers');
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Un élément porte déjà ce nom'), findsOneWidget);
  });

  testWidgets('appui long puis « Supprimer » sur un dossier', (tester) async {
    when(() => repo.delete('Santé')).thenAnswer((_) async => right(null));
    await pumpPage(tester);
    await longPressAction(tester, 'Santé', 'Supprimer');
    expect(find.text('Supprimer ce dossier ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    verify(() => repo.delete('Santé')).called(1);
  });

  group('déplacer', () {
    FilledButton moveHere(WidgetTester tester) =>
        tester.widget(find.widgetWithText(FilledButton, 'Déplacer ici'));

    testWidgets('choisir un sous-dossier puis « Déplacer ici »', (
      tester,
    ) async {
      when(() => repo.move(path: 'a.pdf', destinationFolderPath: 'Santé'))
          .thenAnswer((_) async => right('a.pdf'));
      await pumpPage(tester);
      await longPressAction(tester, 'a.pdf', 'Déplacer');
      // Racine : dossier actuel du fichier, déplacement impossible.
      expect(moveHere(tester).onPressed, isNull);
      expect(find.text('a.pdf'), findsNothing);
      await tester.tap(find.text('Santé'));
      await tester.pumpAndSettle();
      expect(find.text('Vaccins'), findsOneWidget);
      await tester.tap(find.text('Déplacer ici'));
      await tester.pumpAndSettle();
      verify(() => repo.move(path: 'a.pdf', destinationFolderPath: 'Santé'))
          .called(1);
      expect(find.text('Déplacer ici'), findsNothing);
    });

    testWidgets('un dossier ne se propose pas lui-même', (tester) async {
      await pumpPage(tester);
      await longPressAction(tester, 'Santé', 'Déplacer');
      expect(find.text('Santé'), findsNothing);
      expect(find.text('Papiers'), findsOneWidget);
      expect(moveHere(tester).onPressed, isNull);
    });

    testWidgets('retour : remonte d\'un niveau, puis annule sans déplacer', (
      tester,
    ) async {
      await pumpPage(tester);
      await longPressAction(tester, 'a.pdf', 'Déplacer');
      await tester.tap(find.text('Santé'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Papiers'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      verifyNever(
        () => repo.move(
          path: any(named: 'path'),
          destinationFolderPath: any(named: 'destinationFolderPath'),
        ),
      );
    });

    testWidgets('créer un dossier depuis la destination', (tester) async {
      when(() => repo.createFolder(folderPath: 'Santé', name: '2026'))
          .thenAnswer((_) async => right('2026'));
      await pumpPage(tester);
      await longPressAction(tester, 'a.pdf', 'Déplacer');
      await tester.tap(find.text('Santé'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2026');
      await tester.pump();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      verify(() => repo.createFolder(folderPath: 'Santé', name: '2026'))
          .called(1);
    });

    testWidgets('échec de création à la racine : un seul SnackBar', (
      tester,
    ) async {
      when(() => repo.createFolder(folderPath: '', name: 'X')).thenAnswer(
        (_) async => left(const DocumentsFailure(DocumentsReason.io)),
      );
      await pumpPage(tester);
      await longPressAction(tester, 'a.pdf', 'Déplacer');
      await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'X');
      await tester.pump();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Impossible de modifier le dossier iCloud'),
        findsOneWidget,
      );
    });
  });
}
