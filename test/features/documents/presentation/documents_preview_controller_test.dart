import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/presentation/providers/documents_preview_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

DocumentEntry entry(DownloadStatus status, {double? progress}) => DocumentEntry(
  name: 'a.pdf',
  path: 'Ordonnances/a.pdf',
  isDirectory: false,
  size: 0,
  modifiedAt: DateTime(2026, 9, 1),
  downloadStatus: status,
  downloadProgress: progress,
);

void main() {
  late MockDocumentsRepository repo;
  late ProviderContainer container;
  late StreamController<Either<Failure, List<DocumentEntry>>> folder;
  const path = 'Ordonnances/a.pdf';

  setUp(() {
    repo = MockDocumentsRepository();
    folder = StreamController<Either<Failure, List<DocumentEntry>>>();
    // Sans écouteur (aperçu direct, échec du download), le Future de close()
    // ne se complète jamais : on ne l'attend pas.
    addTearDown(() => unawaited(folder.close()));
    when(() => repo.watch('Ordonnances')).thenAnswer((_) => folder.stream);
    container = ProviderContainer(
      overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(documentsPreviewControllerProvider(path), (_, _) {});
  });

  DocumentsPreviewController controller() =>
      container.read(documentsPreviewControllerProvider(path).notifier);

  AsyncValue<void> state() =>
      container.read(documentsPreviewControllerProvider(path));

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('fichier téléchargé : aperçu direct, sans download', () async {
    when(() => repo.preview(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.downloaded));
    verify(() => repo.preview(path)).called(1);
    verifyNever(() => repo.download(any()));
    expect(state(), const AsyncData<void>(null));
  });

  test(
    'fichier nuage : download, puis aperçu quand le flux le dit téléchargé',
    () async {
      when(() => repo.download(path)).thenAnswer((_) async => right(null));
      when(() => repo.preview(path)).thenAnswer((_) async => right(null));

      await controller().open(entry(DownloadStatus.notDownloaded));
      verify(() => repo.download(path)).called(1);
      verifyNever(() => repo.preview(any()));
      expect(state().isLoading, isTrue);

      folder.add(right([entry(DownloadStatus.downloading, progress: 0.3)]));
      await settle();
      verifyNever(() => repo.preview(any()));
      expect(state().isLoading, isTrue);

      folder.add(right([entry(DownloadStatus.downloaded)]));
      await settle();
      verify(() => repo.preview(path)).called(1);
      expect(state(), const AsyncData<void>(null));
    },
  );

  test('retour à notDownloaded après downloading → erreur io', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.notDownloaded));
    folder.add(right([entry(DownloadStatus.downloading)]));
    await settle();
    folder.add(right([entry(DownloadStatus.notDownloaded)]));
    await settle();
    expect(state().error, const DocumentsFailure(DocumentsReason.io));
    verifyNever(() => repo.preview(any()));
  });

  test('entrée disparue pendant l\'attente → repos sans erreur', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.notDownloaded));
    folder.add(right([entry(DownloadStatus.downloading)]));
    await settle();
    folder.add(right(const []));
    await settle();
    expect(state(), const AsyncData<void>(null));
    verifyNever(() => repo.preview(any()));
  });

  test(
    'rafraîchissement pendant le téléchargement : on continue d\'attendre',
    () async {
      final second = StreamController<Either<Failure, List<DocumentEntry>>>();
      addTearDown(() => unawaited(second.close()));
      var watchCalls = 0;
      when(() => repo.watch('Ordonnances')).thenAnswer((_) {
        watchCalls++;
        return watchCalls == 1 ? folder.stream : second.stream;
      });
      when(() => repo.download(path)).thenAnswer((_) async => right(null));
      when(() => repo.preview(path)).thenAnswer((_) async => right(null));

      await controller().open(entry(DownloadStatus.notDownloaded));
      folder.add(right([entry(DownloadStatus.downloading, progress: 0.4)]));
      await settle();

      container.invalidate(documentsFolderProvider('Ordonnances'));
      await container.pump();
      second.add(right([entry(DownloadStatus.notDownloaded)]));
      await settle();
      expect(state().isLoading, isTrue);
      verifyNever(() => repo.preview(any()));

      second.add(right([entry(DownloadStatus.downloaded)]));
      await settle();
      verify(() => repo.preview(path)).called(1);
      expect(state(), const AsyncData<void>(null));
    },
  );

  test('échec du download → erreur, sans attente', () async {
    when(() => repo.download(path)).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.accessDenied)),
    );
    await controller().open(entry(DownloadStatus.notDownloaded));
    expect(state().error, const DocumentsFailure(DocumentsReason.accessDenied));
  });

  test('aperçu refusé (cancelled) après téléchargement → repos', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    when(() => repo.preview(path)).thenAnswer(
      (_) async => left(const DocumentsFailure(DocumentsReason.cancelled)),
    );
    await controller().open(entry(DownloadStatus.notDownloaded));
    folder.add(right([entry(DownloadStatus.downloaded)]));
    await settle();
    expect(state(), const AsyncData<void>(null));
  });

  test('io sur l\'aperçu direct passe en erreur', () async {
    when(
      () => repo.preview(path),
    ).thenAnswer((_) async => left(const DocumentsFailure(DocumentsReason.io)));
    await controller().open(entry(DownloadStatus.downloaded));
    expect(state().error, const DocumentsFailure(DocumentsReason.io));
  });

  test('déjà téléchargé au premier examen : un seul aperçu', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    when(() => repo.preview(path)).thenAnswer((_) async => right(null));
    // Le dossier est déjà observé et dit « téléchargé » avant la fin de
    // download().
    container.listen(documentsFolderProvider('Ordonnances'), (_, _) {});
    folder.add(right([entry(DownloadStatus.downloaded)]));
    await settle();

    await controller().open(entry(DownloadStatus.notDownloaded));
    await settle();
    verify(() => repo.preview(path)).called(1);

    folder.add(right([entry(DownloadStatus.downloaded)]));
    await settle();
    verifyNever(() => repo.preview(path));
    expect(state(), const AsyncData<void>(null));
  });

  test(
    'contrôleur détruit pendant le download : ni exception ni écoute',
    () async {
      // Conteneur dédié : l'écoute du setUp garderait le contrôleur en vie.
      final isolated = ProviderContainer(
        overrides: [documentsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(isolated.dispose);
      final download = Completer<Either<Failure, void>>();
      when(() => repo.download(path)).thenAnswer((_) => download.future);
      final subscription = isolated.listen(
        documentsPreviewControllerProvider(path),
        (_, _) {},
      );
      final opening = isolated
          .read(documentsPreviewControllerProvider(path).notifier)
          .open(entry(DownloadStatus.notDownloaded));
      subscription.close();
      await settle();
      download.complete(right(null));
      await opening;
      verifyNever(() => repo.watch(any()));
    },
  );

  test('erreur du flux pendant l\'attente : on continue d\'attendre', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.notDownloaded));
    folder.add(left(const DocumentsFailure(DocumentsReason.io)));
    await settle();
    expect(state().isLoading, isTrue);
    verifyNever(() => repo.preview(any()));
  });

  test('open est ignoré pendant qu\'un open est en vol', () async {
    when(() => repo.download(path)).thenAnswer((_) async => right(null));
    await controller().open(entry(DownloadStatus.notDownloaded));
    await controller().open(entry(DownloadStatus.notDownloaded));
    verify(() => repo.download(path)).called(1);
  });
}
