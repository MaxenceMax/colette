import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;
  const root = DocumentRoot(name: 'Colette');

  setUp(() {
    repo = MockDocumentsRepository();
    when(() => repo.list(any())).thenAnswer((_) async => right(const []));
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  DocumentsRoot notifier() => container.read(documentsRootProvider.notifier);

  test('build lit le dossier racine', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(root));
    expect(await container.read(documentsRootProvider.future), root);
  });

  test('pick choisit le dossier et invalide les listes', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    when(() => repo.pickRootFolder()).thenAnswer((_) async => right(root));
    await container.read(documentsRootProvider.future);
    container.listen(documentsFolderProvider(''), (_, _) {});
    await container.read(documentsFolderProvider('').future);

    expect(await notifier().pick(), isTrue);

    expect(container.read(documentsRootProvider).value, root);
    await container.read(documentsFolderProvider('').future);
    verify(() => repo.list('')).called(2);
  });

  test('pick annulé restaure l\'état précédent', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(root));
    when(() => repo.pickRootFolder()).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await container.read(documentsRootProvider.future);

    expect(await notifier().pick(), isFalse);

    expect(
      container.read(documentsRootProvider),
      const AsyncData<DocumentRoot?>(root),
    );
  });

  test('pick en échec passe en erreur', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(null));
    when(
      () => repo.pickRootFolder(),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await container.read(documentsRootProvider.future);

    expect(await notifier().pick(), isFalse);

    expect(container.read(documentsRootProvider).hasError, isTrue);
  });

  test('forget oublie le dossier', () async {
    when(() => repo.rootFolder()).thenAnswer((_) async => right(root));
    when(() => repo.forgetRootFolder()).thenAnswer((_) async => right(null));
    await container.read(documentsRootProvider.future);

    await notifier().forget();

    expect(
      container.read(documentsRootProvider),
      const AsyncData<DocumentRoot?>(null),
    );
    verify(() => repo.forgetRootFolder()).called(1);
  });
}
