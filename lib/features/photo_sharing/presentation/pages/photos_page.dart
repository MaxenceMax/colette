import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/photo_labels.dart';
import 'package:colette/features/photo_sharing/presentation/providers/broadcast_lists.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_capture_controller.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/broadcast_list_editor_sheet.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/list_name_dialog.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photo_send_flow.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:colette/shared/ui/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Listes de diffusion de cet iPhone ; un appui envoie des photos à une liste.
class PhotosPage extends ConsumerWidget {
  const PhotosPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = await showListNameDialog(
      context,
      title: s.photosListNameTitle,
      confirmLabel: s.actionCreate,
    );
    if (name == null || !context.mounted) return;
    final created = await ref
        .read(broadcastListsProvider.notifier)
        .create(name);
    if (!context.mounted) return;
    switch (created) {
      case Left(:final value):
        messenger.showSnackBar(
          SnackBar(content: Text(failureMessage(value, s))),
        );
      case Right(:final value):
        await showBroadcastListEditor(context, value);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    // Garde le contrôleur autoDispose vivant pendant la capture des photos.
    ref.watch(photoCaptureControllerProvider);
    ref.listen(photoCaptureControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage(error, s))));
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(s.photosPageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(s.photosNewList),
      ),
      body: switch (ref.watch(broadcastListsProvider)) {
        AsyncData(:final value) when value.isEmpty => EmptyState(
          icon: Icons.photo_library_outlined,
          message: s.photosEmptyBody,
        ),
        AsyncData(:final value) => _Lists(lists: value),
        AsyncError(:final error) => EmptyState(
          icon: Icons.error_outline,
          message: failureMessage(error, s),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// En-tête « dernier envoi » puis une carte par liste.
class _Lists extends ConsumerWidget {
  const _Lists({required this.lists});

  final List<BroadcastList> lists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final now = ref.watch(currentMinuteProvider);
    final lastSentAt = ref.watch(lastPhotoSentAtProvider).value;
    return ListView.builder(
      // En bas, la hauteur du bouton flottant étendu et sa marge : la dernière
      // carte n'est jamais masquée.
      padding:
          AppSpacing.md.all +
          EdgeInsets.only(bottom: AppSize.xxl.value + AppSpacing.md.value),
      itemCount: lists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: AppSpacing.md.bottom,
            child: Text(
              lastSentLabel(lastSentAt, now: now, s: s),
              style: Theme.of(context).coletteTextStyles.small
                  .copyWith(color: context.appColor(AppColors.textSecondary)),
            ),
          );
        }
        return Padding(
          padding: AppSpacing.sm.bottom,
          child: _ListCard(list: lists[index - 1]),
        );
      },
    );
  }
}

/// Carte d'une liste : appui pour envoyer (ou éditer si vide), bouton d'édition.
class _ListCard extends ConsumerWidget {
  const _ListCard({required this.list});

  final BroadcastList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    return ColetteCardSurface(
      onTap: () => list.recipients.isEmpty
          ? showBroadcastListEditor(context, list.id)
          : startPhotoSend(context, ref, list),
      child: Row(
        spacing: AppSpacing.sm.value,
        children: [
          Icon(
            Icons.group_outlined,
            color: context.appColor(AppColors.primary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(list.name, style: styles.bodyMedium),
                Text(
                  s.photosRecipientCount(list.recipients.length),
                  style: styles.small.copyWith(color: secondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: s.photosEditList,
            icon: Icon(Icons.edit_outlined, color: secondary),
            onPressed: () => showBroadcastListEditor(context, list.id),
          ),
        ],
      ),
    );
  }
}
