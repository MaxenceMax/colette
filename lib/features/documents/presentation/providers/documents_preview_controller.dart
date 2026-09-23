import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/domain/use_cases/parent_path.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_preview_controller.g.dart';

/// Ouverture d'un fichier, une instance par chemin : chaque ligne suit la
/// sienne. Un fichier non téléchargé est d'abord téléchargé ; l'aperçu
/// s'ouvre seul dès que le flux du dossier le dit téléchargé.
@riverpod
class DocumentsPreviewController extends _$DocumentsPreviewController {
  ProviderSubscription<AsyncValue<List<DocumentEntry>>>? _waiting;

  @override
  FutureOr<void> build(String path) {
    ref.onDispose(_stopWaiting);
  }

  /// Aperçu direct si [entry] est téléchargée, sinon téléchargement puis
  /// aperçu automatique. Ignoré si une ouverture est déjà en vol.
  Future<void> open(DocumentEntry entry) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    if (entry.downloadStatus == DownloadStatus.downloaded) {
      return _preview();
    }
    final started = await ref.read(documentsRepositoryProvider).download(path);
    // La ligne a pu être démontée pendant l'await (page quittée, défilement).
    if (!ref.mounted) return;
    switch (started) {
      case Left(:final value):
        state = AsyncError(value, StackTrace.current);
      case Right():
        _waitForDownload();
    }
  }

  /// Suit le dossier parent jusqu'à ce que l'entrée soit téléchargée
  /// (→ aperçu), que le téléchargement retombe (→ `io`) ou que l'entrée
  /// disparaisse (→ repos, rien à montrer).
  void _waitForDownload() {
    final folder = documentsFolderProvider(parentPath(path));
    var seenDownloading = false;
    var settled = false;
    _stopWaiting();

    void handle(AsyncValue<List<DocumentEntry>> next) {
      if (settled) return;
      if (next.isLoading) {
        // Rafraîchissement ou invalidation : le flux natif est reconstruit
        // et sa première liste précède sa requête de métadonnées, donc un
        // placeholder y est `notDownloaded` sans que le téléchargement ait
        // échoué. On repart de zéro plutôt que de conclure à un échec.
        seenDownloading = false;
        return;
      }
      final entries = next.value;
      if (entries == null) return;
      final current = entries.where((e) => e.path == path).firstOrNull;
      switch (current?.downloadStatus) {
        case DownloadStatus.downloaded:
          settled = true;
          _stopWaiting();
          unawaited(_preview());
        case DownloadStatus.downloading:
          seenDownloading = true;
        case DownloadStatus.notDownloaded when !seenDownloading:
          // iCloud n'a pas encore pris le téléchargement en compte.
          break;
        case DownloadStatus.notDownloaded:
          settled = true;
          _stopWaiting();
          state = AsyncError(
            const DocumentsFailure(DocumentsReason.io),
            StackTrace.current,
          );
        case null:
          // Fichier supprimé entre-temps (ici ou sur l'autre iPhone).
          settled = true;
          _stopWaiting();
          state = const AsyncData(null);
      }
    }

    _waiting = ref.listen(folder, (_, next) => handle(next));
    // Valeur courante, évaluée après l'abonnement pour que `_stopWaiting`
    // ferme bien la souscription si l'issue est immédiate (tuile périmée :
    // le fichier est déjà là).
    handle(ref.read(folder));
  }

  void _stopWaiting() {
    _waiting?.close();
    _waiting = null;
  }

  /// Ouvre Quick Look ; une annulation (ou un refus pour verrou pris) n'est
  /// pas une erreur.
  Future<void> _preview() async {
    final result = await ref.read(documentsRepositoryProvider).preview(path);
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => switch (failure) {
        DocumentsFailure(reason: DocumentsReason.cancelled) => const AsyncData(
          null,
        ),
        _ => AsyncError(failure, StackTrace.current),
      },
      (_) => const AsyncData(null),
    );
  }
}
