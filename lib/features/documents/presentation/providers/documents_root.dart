import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_root.g.dart';

/// Dossier racine choisi sur cet iPhone ; `null` tant qu'aucun n'est choisi.
@Riverpod(keepAlive: true, retry: noRetry)
class DocumentsRoot extends _$DocumentsRoot {
  @override
  Future<DocumentRoot?> build() async {
    final result = await ref.watch(documentsRepositoryProvider).rootFolder();
    return result.fold((failure) => throw failure, (root) => root);
  }

  /// Ouvre le sélecteur iOS. Renvoie `true` si un dossier a été choisi.
  Future<bool> pick() async {
    // Un `build` initial (ou un `pick` précédent) encore en vol écraserait
    // l'état posé ici avec son propre résultat une fois résolu.
    if (state.isLoading) return false;
    final previous = state;
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).pickRootFolder();
    return result.fold(
      (failure) {
        state = switch (failure) {
          DocumentsFailure(reason: DocumentsReason.cancelled) => previous,
          _ => AsyncError(failure, StackTrace.current),
        };
        return false;
      },
      (root) {
        state = AsyncData(root);
        ref.invalidate(documentsFolderProvider);
        return true;
      },
    );
  }

  /// Oublie le dossier : Colette ne l'affiche plus, rien n'est supprimé.
  Future<void> forget() async {
    final result = await ref
        .read(documentsRepositoryProvider)
        .forgetRootFolder();
    state = result.fold((failure) => AsyncError(failure, StackTrace.current), (
      _,
    ) {
      ref.invalidate(documentsFolderProvider);
      return const AsyncData(null);
    });
  }
}
