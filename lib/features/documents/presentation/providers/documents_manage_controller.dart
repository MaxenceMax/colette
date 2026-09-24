import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/domain/use_cases/document_names.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_manage_controller.g.dart';

/// Création de dossier, renommage, déplacement et suppression dans
/// [folderPath]. Famille par dossier : la page racine et une sous-page
/// poussée observent chacune leur instance. Pas d'invalidation après un
/// succès : Swift reliste les flux des dossiers touchés.
@riverpod
class DocumentsManageController extends _$DocumentsManageController {
  @override
  FutureOr<void> build(String folderPath) {}

  /// Crée le sous-dossier [rawName] dans [folderPath].
  Future<void> createFolder(String rawName) => _run(
    (repo) => validateEntryName(rawName).match(
      (failure) async => left(failure),
      (name) => repo.createFolder(folderPath: folderPath, name: name),
    ),
  );

  /// Renomme [entry] ; pour un fichier, [rawName] est le nom sans
  /// l'extension, qui est conservée.
  Future<void> rename(DocumentEntry entry, String rawName) => _run(
    (repo) => validateEntryName(rawName)
        .match((failure) async => left(failure), (name) {
          final extension = entry.isDirectory
              ? ''
              : splitExtension(entry.name).$2;
          final newName = '$name$extension';
          if (newName == entry.name) return Future.value(right(newName));
          return repo.rename(path: entry.path, newName: newName);
        }),
  );

  /// Déplace [entry] dans [destination] ; sans effet si c'est interdit.
  Future<void> move(DocumentEntry entry, String destination) => _run((repo) {
    if (!canMoveInto(source: entry.path, destination: destination)) {
      return Future.value(right(entry.name));
    }
    return repo.move(path: entry.path, destinationFolderPath: destination);
  });

  /// Supprime le fichier ou le dossier [path].
  Future<void> delete(String path) =>
      _run((repo) async => (await repo.delete(path)).map((_) => path));

  Future<void> _run(
    Future<Either<Failure, String>> Function(DocumentsRepository repo) action,
  ) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await action(ref.read(documentsRepositoryProvider));
    // Le widget appelant a pu être démonté pendant l'await.
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
