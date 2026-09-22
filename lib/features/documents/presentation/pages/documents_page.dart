import 'dart:developer' as developer;

import 'package:colette/core/result/failure.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/features/documents/presentation/providers/documents_root.dart';
import 'package:colette/features/documents/presentation/widgets/document_entry_tile.dart';
import 'package:colette/features/documents/presentation/widgets/documents_lost_access_view.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (ref.watch(documentsFolderProvider(path))) {
        AsyncData(value: final entries) when entries.isEmpty => EmptyState(
          icon: Icons.folder_open_outlined,
          message: s.documentsEmptyFolder,
        ),
        AsyncData(value: final entries) => _EntriesList(
          entries: entries,
          folderPath: path,
        ),
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
        _ => const Center(child: CircularProgressIndicator()),
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
