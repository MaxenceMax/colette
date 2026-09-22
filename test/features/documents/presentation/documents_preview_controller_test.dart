import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_preview_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;
  const path = 'Ordonnances/a.pdf';

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(documentsPreviewControllerProvider(path), (_, _) {});
  });

  test('preview appelle le repository avec le chemin', () async {
    when(() => repo.preview(path)).thenAnswer((_) async => right(null));
    await container
        .read(documentsPreviewControllerProvider(path).notifier)
        .preview();
    verify(() => repo.preview(path)).called(1);
    expect(
      container.read(documentsPreviewControllerProvider(path)),
      const AsyncData<void>(null),
    );
  });

  test('cancelled ne produit pas d\'erreur', () async {
    when(() => repo.preview(path)).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await container
        .read(documentsPreviewControllerProvider(path).notifier)
        .preview();
    expect(
      container.read(documentsPreviewControllerProvider(path)).hasError,
      isFalse,
    );
  });

  test('io passe en erreur', () async {
    when(
      () => repo.preview(path),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await container
        .read(documentsPreviewControllerProvider(path).notifier)
        .preview();
    expect(
      container.read(documentsPreviewControllerProvider(path)).error,
      const DocumentsFailure(DocumentsReason.io),
    );
  });
}
