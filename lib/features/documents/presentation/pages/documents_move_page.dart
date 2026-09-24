import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/use_cases/document_names.dart';
import 'package:colette/features/documents/domain/use_cases/parent_path.dart';
import 'package:colette/features/documents/presentation/providers/documents_manage_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/features/documents/presentation/widgets/document_name_dialog.dart';
import 'package:colette/features/documents/presentation/widgets/documents_manage_error.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choix du dossier de destination de [entry], en naviguant dans les
/// sous-dossiers depuis la racine. Se ferme avec le chemin choisi.
class DocumentsMovePage extends ConsumerStatefulWidget {
  const DocumentsMovePage({super.key, required this.entry});

  final DocumentEntry entry;

  @override
  ConsumerState<DocumentsMovePage> createState() => _DocumentsMovePageState();
}

class _DocumentsMovePageState extends ConsumerState<DocumentsMovePage> {
  /// Dossier parcouru, relatif à la racine (état de navigation, pas métier).
  String _path = '';

  void _open(String path) => setState(() => _path = path);

  Future<void> _createFolder() async {
    final s = S.of(context);
    final name = await showDocumentNameDialog(
      context,
      title: s.documentsNewFolderTitle,
      confirmLabel: s.actionCreate,
    );
    if (name == null || !mounted) return;
    await ref
        .read(documentsManageControllerProvider(_path).notifier)
        .createFolder(name);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final path = _path;
    final creating = ref
        .watch(documentsManageControllerProvider(path))
        .isLoading;
    ref.listen(documentsManageControllerProvider(path), (_, next) {
      if (next case AsyncError(:final error)) {
        showDocumentsManageError(context, ref, error, path);
      }
    });
    final title = switch (path) {
      '' =>
        ref.watch(documentsRootProvider).value?.name ?? s.documentsCardTitle,
      _ => path.split('/').last,
    };
    return PopScope(
      canPop: path.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _open(parentPath(path));
      },
      child: Scaffold(
        appBar: AppBar(
          leading: path.isEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: s.actionCancel,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : BackButton(onPressed: () => _open(parentPath(path))),
          title: Text(title, maxLines: 1, overflow: .ellipsis),
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: s.documentsActionNewFolder,
              onPressed: creating ? null : _createFolder,
            ),
          ],
        ),
        body: _FolderList(
          path: path,
          movedPath: widget.entry.path,
          onOpen: _open,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: AppSpacing.md.all,
            child: FilledButton(
              onPressed:
                  canMoveInto(source: widget.entry.path, destination: path)
                  ? () => Navigator.of(context).pop(path)
                  : null,
              child: Text(s.documentsMoveHere),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sous-dossiers de [path], sans l'élément déplacé [movedPath].
class _FolderList extends ConsumerWidget {
  const _FolderList({
    required this.path,
    required this.movedPath,
    required this.onOpen,
  });

  final String path;
  final String movedPath;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    return switch (ref.watch(documentsFolderProvider(path))) {
      AsyncError(:final error) => EmptyState(
        icon: Icons.error_outline,
        message: failureMessage(error, s),
      ),
      AsyncValue(:final value?, hasValue: true) => switch ([
        for (final e in value)
          if (e.isDirectory && e.path != movedPath) e,
      ]) {
        [] => EmptyState(
          icon: Icons.folder_open_outlined,
          message: s.documentsMoveNoSubfolder,
        ),
        final folders => ListView.builder(
          itemCount: folders.length,
          itemBuilder: (_, index) => ListTile(
            leading: Icon(
              Icons.folder_outlined,
              color: context.appColor(AppColors.primary),
            ),
            title: Text(folders[index].name, maxLines: 1, overflow: .ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpen(folders[index].path),
          ),
        ),
      },
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
