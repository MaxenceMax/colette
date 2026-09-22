import 'package:colette/core/result/failure.dart';
import 'package:colette/core/result/no_retry.dart';
import 'package:colette/features/documents/domain/entities/document_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:fpdart/fpdart.dart';
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

  /// Ouvre le sélecteur iOS. `right(true)` si un dossier a été choisi,
  /// `right(false)` si annulé (ou si un build/pick est déjà en vol),
  /// `left(failure)` sinon. En cas d'échec ou d'annulation, l'état précédent
  /// est restauré.
  Future<Either<Failure, bool>> pick() async {
    // Un `build` initial (ou un `pick` précédent) encore en vol écraserait
    // l'état posé ici avec son propre résultat une fois résolu.
    if (state.isLoading) return right(false);
    final previous = state;
    state = const AsyncLoading();
    final result = await ref.read(documentsRepositoryProvider).pickRootFolder();
    return result.fold(
      (failure) {
        state = previous;
        return switch (failure) {
          DocumentsFailure(reason: DocumentsReason.cancelled) => right(false),
          _ => left(failure),
        };
      },
      (root) {
        state = AsyncData(root);
        ref.invalidate(documentsFolderProvider);
        return right(true);
      },
    );
  }

  /// Oublie le dossier : Colette ne l'affiche plus, rien n'est supprimé.
  Future<Either<Failure, void>> forget() async {
    // Un `build` initial (ou un `pick`) encore en vol écraserait l'état posé
    // ici avec son propre résultat une fois résolu.
    if (state.isLoading) return right(null);
    final previous = state;
    final result = await ref
        .read(documentsRepositoryProvider)
        .forgetRootFolder();
    return result.fold(
      (failure) {
        state = previous;
        return left(failure);
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(documentsFolderProvider);
        return right(null);
      },
    );
  }
}
