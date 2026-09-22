import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

DocumentEntry entry(String name, {bool isDirectory = false}) => DocumentEntry(
  name: name,
  path: name,
  isDirectory: isDirectory,
  size: 0,
  modifiedAt: DateTime(2026, 9, 1),
  downloadStatus: DownloadStatus.downloaded,
);

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockDocumentsRepository();
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('documentsFolder liste puis trie', () async {
    when(() => repo.list('Ordonnances')).thenAnswer(
      (_) async => right([entry('z.pdf'), entry('Sous', isDirectory: true)]),
    );
    final entries = await container.read(
      documentsFolderProvider('Ordonnances').future,
    );
    expect(entries.map((e) => e.name).toList(), ['Sous', 'z.pdf']);
  });

  test('documentsFolder relance la failure', () async {
    when(
      () => repo.list(''),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    expect(
      container.read(documentsFolderProvider('').future),
      throwsA(const DocumentsFailure(DocumentsReason.io)),
    );
  });
}
