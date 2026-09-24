import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/presentation/providers/documents_manage_controller.dart';
import 'package:colette/features/documents/presentation/widgets/document_delete_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Glissement vers la gauche sur une ligne : confirmation puis suppression
/// du fichier ou du dossier. La ligne ne se retire pas d'elle-même, c'est le
/// flux du dossier qui la fera disparaître.
class DocumentDeleteDismissible extends ConsumerWidget {
  const DocumentDeleteDismissible({
    super.key,
    required this.entry,
    required this.folderPath,
    required this.child,
  });

  final DocumentEntry entry;
  final String folderPath;
  final Widget child;

  Future<bool> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDocumentDelete(context, entry);
    // La ligne a pu être démontée pendant la boîte de dialogue (fichier
    // supprimé par l'autre parent, accès perdu) : ne plus toucher à `ref`.
    if (!confirmed || !context.mounted) return false;
    await ref
        .read(documentsManageControllerProvider(folderPath).notifier)
        .delete(entry.path);
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await, et bloque un
    // second glissement pendant une opération.
    final busy = ref
        .watch(documentsManageControllerProvider(folderPath))
        .isLoading;
    return Dismissible(
      key: ValueKey(entry.path),
      direction: busy ? .none : .endToStart,
      confirmDismiss: (_) => _confirm(context, ref),
      background: Container(
        alignment: .centerRight,
        padding: AppSpacing.md.horizontal,
        color: context.appColor(AppColors.error),
        child: Icon(
          Icons.delete_outline,
          color: context.appColor(AppColors.onPrimary),
        ),
      ),
      child: child,
    );
  }
}
