import 'dart:async';

import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_delete_controller.g.dart';

/// Suppression d'un fichier de [folderPath]. Famille par dossier : la page
/// racine et une sous-page poussée observent chacune leur instance.
@riverpod
class DocumentsDeleteController extends _$DocumentsDeleteController {
  @override
  FutureOr<void> build(String folderPath) {}

  /// Supprime le fichier [path]. Pas d'invalidation : le flux natif renvoie
  /// la liste sans lui.
  Future<void> delete(String path) async {
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).delete(path);
    // Le widget appelant a pu être démonté pendant l'await.
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
