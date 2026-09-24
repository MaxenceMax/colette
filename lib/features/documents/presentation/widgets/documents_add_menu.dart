import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/documents/presentation/providers/documents_manage_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_write_controller.dart';
import 'package:colette/features/documents/presentation/widgets/document_name_dialog.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton « + » : scanner, importer ou créer un dossier dans [folderPath].
class DocumentsAddButton extends ConsumerWidget {
  const DocumentsAddButton({super.key, required this.folderPath});

  final String folderPath;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final controller = ref.read(
      documentsWriteControllerProvider(folderPath).notifier,
    );
    final action = await showModalBottomSheet<_AddAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: AppSpacing.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: .min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text(s.documentsActionScan),
                onTap: () => Navigator.of(sheetContext).pop(_AddAction.scan),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(s.documentsActionImport),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AddAction.importFile),
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: Text(s.documentsActionNewFolder),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AddAction.newFolder),
              ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case _AddAction.scan:
        await controller.scan();
      case _AddAction.importFile:
        await controller.importFile();
      case _AddAction.newFolder:
        if (!context.mounted) return;
        final name = await showDocumentNameDialog(
          context,
          title: s.documentsNewFolderTitle,
          confirmLabel: s.actionCreate,
        );
        if (name == null) return;
        await ref
            .read(documentsManageControllerProvider(folderPath).notifier)
            .createFolder(name);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde les contrôleurs autoDispose vivants pendant l'await de l'action.
    final writing =
        ref.watch(documentsWriteControllerProvider(folderPath)).isLoading ||
        ref.watch(documentsManageControllerProvider(folderPath)).isLoading;
    return FloatingActionButton(
      onPressed: writing ? null : () => _open(context, ref),
      child: writing
          ? SizedBox.square(
              dimension: AppSize.sm.value,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacing.xxs.value,
                color: context.appColor(AppColors.onPrimary),
              ),
            )
          : const Icon(Icons.add),
    );
  }
}

enum _AddAction { scan, importFile, newFolder }
