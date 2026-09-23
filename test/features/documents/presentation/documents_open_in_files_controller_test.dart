import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_open_in_files_controller.dart';
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
      documentsOpenInFilesControllerProvider('Ordonnances'),
      (_, _) {},
    );
  });

  test('open transmet le chemin', () async {
    when(() => repo.openInFiles('Ordonnances'))
        .thenAnswer((_) async => right(null));
    await container
        .read(documentsOpenInFilesControllerProvider('Ordonnances').notifier)
        .open();
    verify(() => repo.openInFiles('Ordonnances')).called(1);
    expect(
      container.read(documentsOpenInFilesControllerProvider('Ordonnances')),
      const AsyncData<void>(null),
    );
  });

  test('io passe en erreur', () async {
    when(
      () => repo.openInFiles('Ordonnances'),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await container
        .read(documentsOpenInFilesControllerProvider('Ordonnances').notifier)
        .open();
    expect(
      container
          .read(documentsOpenInFilesControllerProvider('Ordonnances'))
          .error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
