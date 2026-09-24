import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/use_cases/document_names.dart';
import 'package:colette/features/documents/presentation/pages/documents_move_page.dart';
import 'package:colette/features/documents/presentation/providers/documents_manage_controller.dart';
import 'package:colette/features/documents/presentation/widgets/document_delete_confirm.dart';
import 'package:colette/features/documents/presentation/widgets/document_name_dialog.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Appui long sur une ligne : renommer, déplacer ou supprimer [entry].
/// Le widget appelant doit `watch` `documentsManageControllerProvider(folderPath)`.
Future<void> showDocumentEntryActions(
  BuildContext context,
  WidgetRef ref, {
  required DocumentEntry entry,
  required String folderPath,
}) async {
  final s = S.of(context);
  final action = await showModalBottomSheet<_EntryAction>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: AppSpacing.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: .min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(s.documentsActionRename),
              onTap: () => Navigator.of(sheetContext).pop(_EntryAction.rename),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: Text(s.documentsActionMove),
              onTap: () => Navigator.of(sheetContext).pop(_EntryAction.move),
            ),
            ListTile(
              iconColor: sheetContext.appColor(AppColors.error),
              textColor: sheetContext.appColor(AppColors.error),
              leading: const Icon(Icons.delete_outline),
              title: Text(s.actionDelete),
              onTap: () => Navigator.of(sheetContext).pop(_EntryAction.delete),
            ),
          ],
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final controller = ref.read(
    documentsManageControllerProvider(folderPath).notifier,
  );
  switch (action) {
    case _EntryAction.rename:
      final (base, extension) = entry.isDirectory
          ? (entry.name, '')
          : splitExtension(entry.name);
      final name = await showDocumentNameDialog(
        context,
        title: s.documentsRenameTitle,
        confirmLabel: s.actionSave,
        initialName: base,
        suffix: extension,
      );
      if (name != null) await controller.rename(entry, name);
    case _EntryAction.move:
      final destination = await Navigator.of(context, rootNavigator: true)
          .push<String>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => DocumentsMovePage(entry: entry),
            ),
          );
      if (destination != null) await controller.move(entry, destination);
    case _EntryAction.delete:
      if (await confirmDocumentDelete(context, entry)) {
        await controller.delete(entry.path);
      }
  }
}

enum _EntryAction { rename, move, delete }
