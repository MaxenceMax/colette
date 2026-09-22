import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_write_controller.dart';
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
    when(() => repo.list(any())).thenAnswer((_) async => right(const []));
    container = ProviderContainer(
      overrides: [
        documentsRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(
          FixedClock(DateTime(2026, 9, 22, 14, 32)),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(documentsWriteControllerProvider, (_, _) {});
    container.listen(documentsFolderProvider('Ordonnances'), (_, _) {});
  });

  DocumentsWriteController controller() =>
      container.read(documentsWriteControllerProvider.notifier);

  test(
    'scan nomme le fichier avec l\'horloge et rafraîchit la liste',
    () async {
      when(
        () => repo.scan(
          folderPath: 'Ordonnances',
          fileName: 'Scan 22-09-2026 14h32.pdf',
        ),
      ).thenAnswer((_) async => right('Scan 22-09-2026 14h32.pdf'));
      await container.read(documentsFolderProvider('Ordonnances').future);

      await controller().scan('Ordonnances');

      await container.read(documentsFolderProvider('Ordonnances').future);
      verify(() => repo.list('Ordonnances')).called(2);
      expect(
        container.read(documentsWriteControllerProvider).hasError,
        isFalse,
      );
    },
  );

  test('importFile transmet le dossier et rafraîchit la liste', () async {
    when(() => repo.importFile(folderPath: 'Ordonnances'))
        .thenAnswer((_) async => right('facture.pdf'));
    await container.read(documentsFolderProvider('Ordonnances').future);

    await controller().importFile('Ordonnances');

    await container.read(documentsFolderProvider('Ordonnances').future);
    verify(() => repo.list('Ordonnances')).called(2);
  });

  test('cancelled ne rafraîchit pas et ne produit pas d\'erreur', () async {
    when(() => repo.importFile(folderPath: '')).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await controller().importFile('');
    expect(container.read(documentsWriteControllerProvider).hasError, isFalse);
  });

  test('io passe en erreur', () async {
    when(
      () => repo.importFile(folderPath: ''),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await controller().importFile('');
    expect(
      container.read(documentsWriteControllerProvider).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
