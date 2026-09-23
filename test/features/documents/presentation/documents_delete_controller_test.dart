import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_delete_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(
      documentsDeleteControllerProvider('Ordonnances'),
      (_, _) {},
    );
  });

  test('delete transmet le chemin et revient au repos', () async {
    when(() => repo.delete('Ordonnances/a.pdf'))
        .thenAnswer((_) async => right(null));
    await container
        .read(documentsDeleteControllerProvider('Ordonnances').notifier)
        .delete('Ordonnances/a.pdf');
    verify(() => repo.delete('Ordonnances/a.pdf')).called(1);
    expect(
      container.read(documentsDeleteControllerProvider('Ordonnances')),
      const AsyncData<void>(null),
    );
  });

  test('io passe en erreur', () async {
    when(
      () => repo.delete('Ordonnances/a.pdf'),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await container
        .read(documentsDeleteControllerProvider('Ordonnances').notifier)
        .delete('Ordonnances/a.pdf');
    expect(
      container.read(documentsDeleteControllerProvider('Ordonnances')).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
