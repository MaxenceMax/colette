import 'package:colette/app/router/app_router.dart';
import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/entities/document_entry.dart';
import 'package:colette/features/documents/domain/entities/download_status.dart';
import 'package:colette/features/documents/presentation/providers/documents_preview_controller.dart';
import 'package:colette/features/documents/presentation/providers/documents_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Ligne d'un dossier ou d'un fichier ; tap : navigation ou aperçu.
class DocumentEntryTile extends ConsumerWidget {
  const DocumentEntryTile({
    super.key,
    required this.entry,
    required this.folderPath,
  });

  final DocumentEntry entry;

  /// Dossier contenant [entry], pour invalider sa liste en cas d'accès perdu.
  final String folderPath;

  IconData get _icon {
    if (entry.isDirectory) return Icons.folder_outlined;
    final ext = entry.name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'jpg' || 'jpeg' || 'png' || 'heic' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  void _onPreviewError(BuildContext context, WidgetRef ref, Object error) {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (error) {
      // Défense en profondeur : le contrôleur mappe déjà cancelled sur AsyncData.
      case DocumentsFailure(reason: DocumentsReason.cancelled):
        return;
      case DocumentsFailure(reason: DocumentsReason.io):
        messenger.showSnackBar(
          SnackBar(content: Text(s.documentsErrorNotDownloaded)),
        );
      case DocumentsFailure(
        reason: DocumentsReason.noFolder || DocumentsReason.accessDenied,
      ):
        ref.invalidate(documentsFolderProvider(folderPath));
      default:
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(error, s))),
        );
    }
  }

  Widget? _trailing(BuildContext context, bool previewing) {
    if (entry.isDirectory) return const Icon(Icons.chevron_right);
    final downloading = entry.downloadStatus == DownloadStatus.downloading;
    if (previewing || downloading) {
      return SizedBox.square(
        dimension: AppSize.sm.value,
        child: CircularProgressIndicator(
          strokeWidth: AppSpacing.xxs.value,
          value: downloading ? entry.downloadProgress : null,
        ),
      );
    }
    if (entry.downloadStatus == DownloadStatus.notDownloaded) {
      return Icon(
        Icons.cloud_download_outlined,
        color: context.appColor(AppColors.textSecondary),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = documentsPreviewControllerProvider(entry.path);
    // Garde le contrôleur autoDispose vivant pendant l'await de open().
    final previewing = ref.watch(controller).isLoading;
    ref.listen(controller, (_, next) {
      if (next case AsyncError(:final error)) {
        _onPreviewError(context, ref, error);
      }
    });
    return ListTile(
      leading: Icon(_icon, color: context.appColor(AppColors.primary)),
      title: Text(entry.name, maxLines: 1, overflow: .ellipsis),
      subtitle: entry.isDirectory
          ? null
          : Text(formatShortDate(entry.modifiedAt)),
      trailing: _trailing(context, previewing),
      onTap: switch (entry.isDirectory) {
        true => () => context.push(AppRoutes.documentsLocation(entry.path)),
        false when previewing => null,
        false => () => ref.read(controller.notifier).open(entry),
      },
    );
  }
}
