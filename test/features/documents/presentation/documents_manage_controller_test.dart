import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_manage_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
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
  late ProviderContainer container;
  final provider = documentsManageControllerProvider('Santé');

  DocumentsManageController controller() => container.read(provider.notifier);

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
  });

  test('delete transmet le chemin et revient au repos', () async {
    when(() => repo.delete('Santé/a.pdf')).thenAnswer((_) async => right(null));
    await controller().delete('Santé/a.pdf');
    verify(() => repo.delete('Santé/a.pdf')).called(1);
    expect(container.read(provider), const AsyncData<void>(null));
  });

  test('io passe en erreur', () async {
    when(
      () => repo.delete('Santé/a.pdf'),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await controller().delete('Santé/a.pdf');
    expect(
      container.read(provider).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });

  test('createFolder valide le nom et crée dans le dossier', () async {
    when(() => repo.createFolder(folderPath: 'Santé', name: 'Vaccins'))
        .thenAnswer((_) async => right('Vaccins'));
    await controller().createFolder('  Vaccins ');
    verify(() => repo.createFolder(folderPath: 'Santé', name: 'Vaccins'))
        .called(1);
    expect(container.read(provider), const AsyncData<void>(null));
  });

  test('createFolder refuse un nom invalide sans appeler le repo', () async {
    await controller().createFolder('a/b');
    expect(
      container.read(provider).error,
      isA<ValidationFailure>().having(
        (f) => f.reason,
        'reason',
        ValidationReason.invalidDocumentName,
      ),
    );
    verifyZeroInteractions(repo);
  });

  test('rename d\'un fichier garde l\'extension', () async {
    when(() => repo.rename(path: 'Santé/a.pdf', newName: 'ordonnance.pdf'))
        .thenAnswer((_) async => right('ordonnance.pdf'));
    await controller().rename(_entry('Santé/a.pdf'), 'ordonnance');
    verify(() => repo.rename(path: 'Santé/a.pdf', newName: 'ordonnance.pdf'))
        .called(1);
  });

  test('rename d\'un dossier prend le nom tel quel', () async {
    when(() => repo.rename(path: 'Santé/Vaccins', newName: 'Vaccins 2026'))
        .thenAnswer((_) async => right('Vaccins 2026'));
    await controller().rename(
      _entry('Santé/Vaccins', isDirectory: true),
      'Vaccins 2026',
    );
    verify(() => repo.rename(path: 'Santé/Vaccins', newName: 'Vaccins 2026'))
        .called(1);
  });

  test('rename vers un nom pris passe en erreur nameTaken', () async {
    when(() => repo.rename(path: 'Santé/a.pdf', newName: 'b.pdf')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.nameTaken)),
    );
    await controller().rename(_entry('Santé/a.pdf'), 'b');
    expect(
      container.read(provider).error,
      const DocumentsFailure(DocumentsReason.nameTaken),
    );
  });

  test('rename sans changement : aucun appel', () async {
    await controller().rename(_entry('Santé/a.pdf'), 'a');
    verifyZeroInteractions(repo);
    expect(container.read(provider), const AsyncData<void>(null));
  });

  test('move transmet la destination', () async {
    when(() => repo.move(path: 'Santé/a.pdf', destinationFolderPath: ''))
        .thenAnswer((_) async => right('a.pdf'));
    await controller().move(_entry('Santé/a.pdf'), '');
    verify(() => repo.move(path: 'Santé/a.pdf', destinationFolderPath: ''))
        .called(1);
  });

  test('move vers un descendant : aucun appel', () async {
    await controller().move(
      _entry('Santé/Vaccins', isDirectory: true),
      'Santé/Vaccins/2026',
    );
    verifyZeroInteractions(repo);
  });

  test('une seule opération à la fois', () async {
    final deleting = Completer<Either<Failure, void>>();
    when(() => repo.delete(any())).thenAnswer((_) => deleting.future);
    unawaited(controller().delete('Santé/a.pdf'));
    await controller().delete('Santé/b.pdf');
    deleting.complete(right(null));
    verify(() => repo.delete('Santé/a.pdf')).called(1);
    verifyNever(() => repo.delete('Santé/b.pdf'));
  });
}
