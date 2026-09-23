import 'dart:async';

import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_open_in_files_controller.g.dart';

/// Ouverture de l'app Fichiers sur le dossier [path].
@riverpod
class DocumentsOpenInFilesController extends _$DocumentsOpenInFilesController {
  @override
  FutureOr<void> build(String path) {}

  /// Demande à iOS d'ouvrir Fichiers sur le dossier. Ignoré si déjà en vol.
  Future<void> open() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await ref
        .read(documentsRepositoryProvider)
        .openInFiles(path);
    // Le bouton a pu être démonté pendant l'await.
    if (!ref.mounted) return;
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}
