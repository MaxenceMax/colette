import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/documents/data/native_documents_repository.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/repositories/documents_repository.dart';
import 'package:colette/features/documents/domain/use_cases/sort_document_entries.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_providers.g.dart';

/// Sans état : `keepAlive` car consommé par `DocumentsRoot` (keepAlive).
@Riverpod(keepAlive: true)
DocumentsRepository documentsRepository(Ref ref) =>
    const NativeDocumentsRepository(
      MethodChannel(NativeDocumentsRepository.channelName),
    );

/// Contenu trié d'un dossier, en direct, [path] relatif à la racine (`''` =
/// racine). Chaque liste reçue est triée ; un `Left` est relancé pour que
/// l'UI le reçoive en `AsyncError`. `retry` désactivé : une
/// `DocumentsFailure` doit remonter immédiatement.
@Riverpod(retry: noRetry)
Stream<List<DocumentEntry>> documentsFolder(Ref ref, String path) => ref
    .watch(documentsRepositoryProvider)
    .watch(path)
    .map(
      (result) => result.fold((failure) => throw failure, sortDocumentEntries),
    );
