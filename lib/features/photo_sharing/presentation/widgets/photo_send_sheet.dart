import 'dart:io';

import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/photo_labels.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_send_controller.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ouvre la feuille d'envoi ; `true` si l'envoi a été lancé (les photos sont
/// alors effacées par le contrôleur).
Future<bool> showPhotoSendSheet(
  BuildContext context, {
  required BroadcastList list,
  required List<String> photoPaths,
}) async {
  final started = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PhotoSendSheet(list: list, photoPaths: photoPaths),
  );
  return started ?? false;
}

/// Vignettes, texte facultatif commun à toute la liste et bouton d'envoi.
class PhotoSendSheet extends ConsumerStatefulWidget {
  const PhotoSendSheet({
    super.key,
    required this.list,
    required this.photoPaths,
  });

  final BroadcastList list;
  final List<String> photoPaths;

  @override
  ConsumerState<PhotoSendSheet> createState() => _PhotoSendSheetState();
}

class _PhotoSendSheetState extends ConsumerState<PhotoSendSheet> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref
        .read(photoSendControllerProvider.notifier)
        .send(
          list: widget.list,
          photoPaths: widget.photoPaths,
          body: _message.text,
        );
    if (!mounted) return;
    final text = switch (ref.read(photoSendControllerProvider)) {
      AsyncData(value: final report?) => sendReportLabel(report, s),
      AsyncError(:final error) => failureMessage(error, s),
      _ => null,
    };
    navigator.pop(true);
    if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Garde le contrôleur autoDispose vivant pendant l'await de send.
    final busy = ref.watch(photoSendControllerProvider).isLoading;
    final count = widget.list.recipients.length;
    // Pas de fermeture par le fond pendant l'envoi.
    return PopScope(
      canPop: !busy,
      child: Padding(
        padding:
            AppSpacing.md.all +
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: AppSpacing.md.value,
            children: [
              Text(
                widget.list.name,
                style: Theme.of(context).coletteTextStyles.heading2,
              ),
              _Thumbnails(photoPaths: widget.photoPaths),
              TextField(
                controller: _message,
                minLines: 1,
                maxLines: 4,
                textCapitalization: .sentences,
                decoration: InputDecoration(labelText: s.photosMessageLabel),
              ),
              FilledButton(
                onPressed: busy || count == 0 ? null : _send,
                child: busy
                    ? SizedBox.square(
                        dimension: AppSize.xs.value,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.xxs.value,
                        ),
                      )
                    : Text(s.photosSendTo(count)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bande horizontale de vignettes carrées.
class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.photoPaths});

  final List<String> photoPaths;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSize.massive.value,
    child: ListView.separated(
      scrollDirection: .horizontal,
      itemCount: photoPaths.length,
      separatorBuilder: (_, _) => AppSpacing.sm.horizontalSpace,
      itemBuilder: (context, index) => ClipRRect(
        borderRadius: AppRadius.md.circular,
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(
            File(photoPaths[index]),
            fit: .cover,
            // Décodée à la taille affichée, pas en pleine résolution.
            cacheHeight:
                (AppSize.massive.value * MediaQuery.devicePixelRatioOf(context))
                    .round(),
            errorBuilder: (context, _, _) => ColoredBox(
              color: context.appColor(AppColors.border),
              child: Icon(
                Icons.image_outlined,
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
