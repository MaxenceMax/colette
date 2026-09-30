import 'package:colette/core/result/failure.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/presentation/providers/broadcast_lists.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/list_name_dialog.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Ouvre l'édition de la liste [listId].
Future<void> showBroadcastListEditor(BuildContext context, String listId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BroadcastListEditorSheet(listId: listId),
    );

/// Affiche la failure d'une modification, s'il y en a une.
void _showFailure(
  ScaffoldMessengerState messenger,
  S s,
  Either<Failure, void> result,
) {
  if (result case Left(:final value)) {
    messenger.showSnackBar(SnackBar(content: Text(failureMessage(value, s))));
  }
}

/// Édition d'une liste : nom, personnes (glisser pour retirer), ajout depuis
/// les contacts, suppression de la liste.
class BroadcastListEditorSheet extends ConsumerWidget {
  const BroadcastListEditorSheet({super.key, required this.listId});

  final String listId;

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    BroadcastList list,
  ) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = await showListNameDialog(
      context,
      title: s.photosRenameList,
      confirmLabel: s.actionSave,
      initialName: list.name,
    );
    if (name == null || !context.mounted) return;
    final result = await ref
        .read(broadcastListsProvider.notifier)
        .rename(list.id, name);
    _showFailure(messenger, s, result);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(broadcastListsProvider.notifier)
        .addFromContacts(listId);
    _showFailure(messenger, s, result);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    BroadcastList list,
  ) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.photosDeleteListTitle),
        content: Text(s.photosDeleteListBody(list.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              s.actionDelete,
              style: Theme.of(dialogContext).coletteTextStyles.bodyMedium
                  .copyWith(color: dialogContext.appColor(AppColors.error)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(broadcastListsProvider.notifier)
        .delete(list.id);
    _showFailure(messenger, s, result);
    if (result.isRight()) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(broadcastListsProvider).value ?? const [];
    final list = lists.where((l) => l.id == listId).firstOrNull;
    if (list == null) return const SizedBox.shrink();
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final error = context.appColor(AppColors.error);
    return Padding(
      padding: AppSpacing.md.all,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(list.name, style: styles.heading2)),
              IconButton(
                tooltip: s.photosRenameList,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _rename(context, ref, list),
              ),
            ],
          ),
          Text(
            s.photosRecipientCount(list.recipients.length),
            style: styles.small.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          AppSpacing.sm.verticalSpace,
          Flexible(child: _Recipients(list: list)),
          TextButton.icon(
            onPressed: () => _add(context, ref),
            icon: const Icon(Icons.person_add_alt_outlined),
            label: Text(s.photosAddRecipient),
          ),
          TextButton.icon(
            onPressed: () => _delete(context, ref, list),
            icon: Icon(Icons.delete_outline, color: error),
            label: Text(
              s.photosDeleteList,
              style: styles.bodyMedium.copyWith(color: error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Personnes de la liste ; un glissement vers la gauche retire la personne.
/// La ligne disparaît avec la mise à jour de l'état, jamais d'elle-même.
class _Recipients extends ConsumerWidget {
  const _Recipients({required this.list});

  final BroadcastList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final secondary = context.appColor(AppColors.textSecondary);
    if (list.recipients.isEmpty) {
      return Padding(
        padding: AppSpacing.md.vertical,
        child: Text(
          s.photosNoRecipients,
          style: styles.body.copyWith(color: secondary),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.recipients.length,
      itemBuilder: (context, index) {
        final recipient = list.recipients[index];
        return Dismissible(
          key: ValueKey(recipient.phone),
          direction: .endToStart,
          confirmDismiss: (_) async {
            final messenger = ScaffoldMessenger.of(context);
            final result = await ref
                .read(broadcastListsProvider.notifier)
                .removeRecipient(list.id, recipient.phone);
            _showFailure(messenger, s, result);
            return false;
          },
          background: Container(
            alignment: .centerRight,
            padding: AppSpacing.md.horizontal,
            color: context.appColor(AppColors.error),
            child: Icon(
              Icons.delete_outline,
              color: context.appColor(AppColors.onPrimary),
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline, color: secondary),
            title: Text(recipient.name, style: styles.body),
            subtitle: Text(
              recipient.phone,
              style: styles.small.copyWith(color: secondary),
            ),
          ),
        );
      },
    );
  }
}
