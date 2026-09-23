import 'dart:async';

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

  test('documentsFolder trie chaque liste reçue', () async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('Ordonnances')).thenAnswer((_) => events.stream);
    final seen = <List<String>>[];
    container.listen(documentsFolderProvider('Ordonnances'), (_, next) {
      if (next case AsyncData(:final value)) {
        seen.add(value.map((e) => e.name).toList());
      }
    });

    events.add(right([entry('z.pdf'), entry('Sous', isDirectory: true)]));
    await Future<void>.delayed(Duration.zero);
    events.add(right([entry('a.pdf')]));
    await Future<void>.delayed(Duration.zero);

    expect(seen, [
      ['Sous', 'z.pdf'],
      ['a.pdf'],
    ]);
  });

  test('documentsFolder relance la failure', () async {
    when(() => repo.watch('')).thenAnswer(
      (_) => Stream.value(left(const DocumentsFailure(DocumentsReason.io))),
    );
    // autoDispose : sans écouteur, le provider serait détruit avant la
    // première émission du flux.
    container.listen(documentsFolderProvider(''), (_, _) {});
    await expectLater(
      container.read(documentsFolderProvider('').future),
      throwsA(const DocumentsFailure(DocumentsReason.io)),
    );
  });

  test('documentsFolder garde la dernière liste après un Left', () async {
    final events = StreamController<Either<Failure, List<DocumentEntry>>>();
    addTearDown(events.close);
    when(() => repo.watch('')).thenAnswer((_) => events.stream);
    container.listen(documentsFolderProvider(''), (_, _) {});

    events.add(right([entry('a.pdf')]));
    await Future<void>.delayed(Duration.zero);
    events.add(left(const DocumentsFailure(DocumentsReason.accessDenied)));
    await Future<void>.delayed(Duration.zero);

    final state = container.read(documentsFolderProvider(''));
    expect(state.hasError, isTrue);
    expect(state.value?.single.name, 'a.pdf');
  });

  test('invalider réabonne le flux', () async {
    when(() => repo.watch(''))
        .thenAnswer((_) => Stream.value(right([entry('a.pdf')])));
    container.listen(documentsFolderProvider(''), (_, _) {});
    await container.read(documentsFolderProvider('').future);
    container.invalidate(documentsFolderProvider(''));
    await container.read(documentsFolderProvider('').future);
    verify(() => repo.watch('')).called(2);
  });
}
