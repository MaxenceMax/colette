import 'dart:async';

import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_preview_controller.g.dart';

/// Aperçu d'un fichier, une instance par chemin : chaque ligne suit la sienne.
@riverpod
class DocumentsPreviewController extends _$DocumentsPreviewController {
  @override
  FutureOr<void> build(String path) {}

  /// Ouvre l'aperçu Quick Look du fichier ; une annulation n'est pas une erreur.
  Future<void> preview() async {
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).preview(path);
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
