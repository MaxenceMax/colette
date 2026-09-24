import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/presentation/providers/documents_manage_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/features/documents/presentation/providers/documents_write_controller.dart';
import 'package:colette/features/documents/presentation/widgets/document_entry_tile.dart';
import 'package:colette/features/documents/presentation/widgets/documents_add_menu.dart';
import 'package:colette/features/documents/presentation/widgets/documents_lost_access_view.dart';
import 'package:colette/features/documents/presentation/widgets/documents_manage_error.dart';
import 'package:colette/features/documents/presentation/widgets/documents_open_in_files_button.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste d'un dossier du dossier iCloud partagé, [path] relatif à la racine.
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key, this.path = ''});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final rootName = ref.watch(documentsRootProvider).value?.name;
    final title = switch (path) {
      '' => rootName ?? s.documentsCardTitle,
      _ => path.split('/').last,
    };
    ref.listen(documentsWriteControllerProvider(path), (_, next) {
      if (next case AsyncError(:final error)) {
        switch (error) {
          case DocumentsFailure(
            reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
          ):
            ref.invalidate(documentsFolderProvider(path));
          case DocumentsFailure(reason: DocumentsReason.cancelled):
            break;
          case DocumentsFailure(reason: DocumentsReason.io):
            // failureMessage() mappe désormais `io` vers un message neutre
            // (documentsErrorIo, utilisé pour la lecture) ; l'écriture a son
            // propre message.
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(s.documentsErrorWrite)));
          default:
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
        }
      }
    });
    ref.listen(documentsManageControllerProvider(path), (_, next) {
      if (next case AsyncError(:final error)) {
        showDocumentsManageError(context, ref, error, path);
      }
    });
    final folder = ref.watch(documentsFolderProvider(path));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (folder.hasValue && !folder.hasError)
            DocumentsOpenInFilesButton(path: path),
        ],
      ),
      body: switch (folder) {
        AsyncError(
          error: DocumentsFailure(
            reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
          ),
        ) =>
          const DocumentsLostAccessView(),
        AsyncError(:final error) => EmptyState(
          icon: Icons.error_outline,
          message: failureMessage(error, s),
        ),
        // `hasValue` capte aussi un rechargement (AsyncLoading avec
        // previousData) : la liste reste affichée pendant le rafraîchissement
        // ou après une écriture, plutôt que de basculer sur le spinner.
        AsyncValue(:final value, hasValue: true)
            when value != null && value.isEmpty =>
          EmptyState(
            icon: Icons.folder_open_outlined,
            message: s.documentsEmptyFolder,
          ),
        AsyncValue(:final value, hasValue: true) when value != null =>
          _EntriesList(entries: value, folderPath: path),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: switch (folder) {
        AsyncError() => null,
        final f when f.hasValue => DocumentsAddButton(folderPath: path),
        _ => null,
      },
    );
  }
}

/// Liste des entrées avec tirer-pour-rafraîchir.
class _EntriesList extends ConsumerWidget {
  const _EntriesList({required this.entries, required this.folderPath});

  final List<DocumentEntry> entries;
  final String folderPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      // L'erreur est déjà affichée par le parent via ref.watch ; ne pas la
      // laisser fuir.
      try {
        final refreshed = ref.refresh(
          documentsFolderProvider(folderPath).future,
        );
        await refreshed;
      } on Object catch (error, stackTrace) {
        developer.log(
          'Rafraîchissement documents',
          name: 'colette',
          error: error,
          stackTrace: stackTrace,
        );
      }
    },
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (_, index) =>
          DocumentEntryTile(entry: entries[index], folderPath: folderPath),
    ),
  );
}
