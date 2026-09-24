import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Réaction à l'échec d'une opération sur [folderPath] : accès perdu →
/// relance du flux (qui affichera la vue dédiée), sinon SnackBar. Ne fait
/// rien si la route de [context] n'est pas au premier plan, pour qu'une
/// seule page affiche l'erreur.
void showDocumentsManageError(
  BuildContext context,
  WidgetRef ref,
  Object error,
  String folderPath,
) {
  if (ModalRoute.of(context)?.isCurrent == false) return;
  final s = S.of(context);
  final message = switch (error) {
    DocumentsFailure(
      reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
    ) =>
      null,
    DocumentsFailure(reason: DocumentsReason.cancelled) => null,
    // failureMessage() mappe `io` vers le message de lecture.
    DocumentsFailure(reason: DocumentsReason.io) => s.documentsErrorManage,
    _ => failureMessage(error, s),
  };
  if (message == null) {
    ref.invalidate(documentsFolderProvider(folderPath));
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
