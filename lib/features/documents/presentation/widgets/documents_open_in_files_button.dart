import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/presentation/providers/documents_open_in_files_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Action de la barre de titre : ouvre l'app Fichiers sur le dossier [path].
class DocumentsOpenInFilesButton extends ConsumerWidget {
  const DocumentsOpenInFilesButton({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final controller = documentsOpenInFilesControllerProvider(path);
    // Garde le contrôleur autoDispose vivant pendant l'await de open().
    final opening = ref.watch(controller).isLoading;
    ref.listen(controller, (_, next) {
      if (next case AsyncError(:final error)) {
        switch (error) {
          case DocumentsFailure(
            reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
          ):
            ref.invalidate(documentsFolderProvider(path));
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.documentsErrorOpenInFiles)),
            );
        }
      }
    });
    return IconButton(
      tooltip: s.documentsOpenInFiles,
      icon: const Icon(Icons.folder_open_outlined),
      onPressed: opening ? null : () => ref.read(controller.notifier).open(),
    );
  }
}
