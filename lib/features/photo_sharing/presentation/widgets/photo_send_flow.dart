import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/photo_source.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photo_send_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choix de la source, prise ou choix des photos, puis feuille d'envoi à
/// [list]. Le `build` appelant doit surveiller `photoCaptureControllerProvider`
/// (erreurs de capture affichées par son `ref.listen`).
Future<void> startPhotoSend(
  BuildContext context,
  WidgetRef ref,
  BroadcastList list,
) async {
  // Lu avant les await : le pont reste utilisable même si la page est démontée.
  final system = ref.read(photoSharingSystemProvider);
  final source = await _chooseSource(context);
  if (source == null || !context.mounted) return;
  final paths = await ref
      .read(photoCaptureControllerProvider.notifier)
      .capture(source);
  if (paths.isEmpty) return;
  if (!context.mounted) {
    await system.discardPhotos(paths);
    return;
  }
  final started = await showPhotoSendSheet(
    context,
    list: list,
    photoPaths: paths,
  );
  if (!started) await system.discardPhotos(paths);
}

Future<PhotoSource?> _chooseSource(BuildContext context) {
  final s = S.of(context);
  return showModalBottomSheet<PhotoSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: AppSpacing.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: .min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(s.photosTakePhoto),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(s.photosPickFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}
