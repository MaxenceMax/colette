import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/presentation/providers/documents_delete_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Glissement vers la gauche sur une ligne de fichier : confirmation puis
/// suppression. La ligne ne se retire pas d'elle-même, c'est le flux du
/// dossier qui la fera disparaître.
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
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.documentsDeleteTitle),
        content: Text(s.documentsDeleteBody(entry.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              s.actionDelete,
              style: Theme.of(dialogContext).coletteTextStyles.bodyMedium
                  .copyWith(color: dialogContext.appColor(AppColors.error)),
            ),
          ),
        ],
      ),
    );
    // La ligne a pu être démontée pendant la boîte de dialogue (fichier
    // supprimé par l'autre parent, accès perdu) : ne plus toucher à `ref`.
    if (confirmed != true || !context.mounted) return false;
    await ref
        .read(documentsDeleteControllerProvider(folderPath).notifier)
        .delete(entry.path);
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await, et bloque un
    // second glissement pendant une suppression.
    final deleting = ref
        .watch(documentsDeleteControllerProvider(folderPath))
        .isLoading;
    return Dismissible(
      key: ValueKey(entry.path),
      direction: deleting ? .none : .endToStart,
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
