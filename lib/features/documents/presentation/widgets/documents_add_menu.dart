import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/documents/presentation/providers/documents_write_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bouton « + » : scanner ou importer dans [folderPath].
class DocumentsAddButton extends ConsumerWidget {
  const DocumentsAddButton({super.key, required this.folderPath});

  final String folderPath;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final controller = ref.read(documentsWriteControllerProvider.notifier);
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
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case _AddAction.scan:
        await controller.scan(folderPath);
      case _AddAction.importFile:
        await controller.importFile(folderPath);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await de l'action.
    final writing = ref.watch(documentsWriteControllerProvider).isLoading;
    return FloatingActionButton(
      onPressed: writing ? null : () => _open(context, ref),
      child: writing
          ? SizedBox.square(
              dimension: AppSize.sm.value,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacing.xxs.value,
              ),
            )
          : const Icon(Icons.add),
    );
  }
}

enum _AddAction { scan, importFile }
