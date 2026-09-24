import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Confirmation de suppression d'un fichier ou d'un dossier et de son contenu.
Future<bool> confirmDocumentDelete(
  BuildContext context,
  DocumentEntry entry,
) async {
  final s = S.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        entry.isDirectory
            ? s.documentsDeleteFolderTitle
            : s.documentsDeleteTitle,
      ),
      content: Text(
        entry.isDirectory
            ? s.documentsDeleteFolderBody(entry.name)
            : s.documentsDeleteBody(entry.name),
      ),
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
  return confirmed ?? false;
}
