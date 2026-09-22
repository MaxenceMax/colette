import 'package:colette/features/documents/data/native_documents_repository.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/domain/use_cases/sort_document_entries.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_providers.g.dart';

/// Désactive les tentatives automatiques de Riverpod : une [DocumentsFailure]
/// doit remonter immédiatement, pas déclencher des relances silencieuses.
Duration? _noRetry(int retryCount, Object error) => null;

/// Sans état : `keepAlive` car consommé par [DocumentsRoot] (keepAlive).
@Riverpod(keepAlive: true)
DocumentsRepository documentsRepository(Ref ref) =>
    const NativeDocumentsRepository(
      MethodChannel(NativeDocumentsRepository.channelName),
    );

/// Contenu trié d'un dossier, [path] relatif à la racine (`''` = racine).
/// `retry` désactivé : une [DocumentsFailure] doit remonter immédiatement,
/// pas déclencher des tentatives silencieuses en arrière-plan.
@Riverpod(retry: _noRetry)
Future<List<DocumentEntry>> documentsFolder(Ref ref, String path) async {
  final result = await ref.watch(documentsRepositoryProvider).list(path);
  return result.fold((failure) => throw failure, sortDocumentEntries);
}
