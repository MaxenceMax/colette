import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/food_labels.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_overview_providers.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/diversification/presentation/widgets/tasting_form_sheet.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dégustations d'un aliment : tap pour modifier, balayage pour supprimer.
class TastingHistorySliver extends ConsumerWidget {
  const TastingHistorySliver({super.key, required this.food});

  final Food food;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tastings = ref.watch(tastingsForFoodProvider(food.id));
    if (tastings.isEmpty) {
      return SliverToBoxAdapter(
        child: Text(
          S.of(context).foodDetailNoTasting,
          style: Theme.of(context).coletteTextStyles.body
              .copyWith(color: context.appColor(AppColors.textSecondary)),
        ),
      );
    }
    return SliverList.builder(
      itemCount: tastings.length,
      itemBuilder: (context, index) =>
          _TastingTile(food: food, tasting: tastings[index]),
    );
  }
}

class _TastingTile extends ConsumerWidget {
  const _TastingTile({required this.food, required this.tasting});

  final Food food;
  final Tasting tasting;

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // Capturés avant tout `await`, cf. `_DeleteFoodButton._delete`.
    final messenger = ScaffoldMessenger.of(context);
    final s = S.of(context);
    final controller = ref.read(tastingFormControllerProvider.notifier);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(s.tastingDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final failure = await controller.delete(tasting.id);
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(failureMessage(failure, s))),
      );
    }
    return failure == null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final details = [
      if (tasting.liking case final liking?) liking.label(s),
      if (tasting.hadReaction) s.tastingReactionShort,
      ?tasting.note,
    ].join(' · ');
    return Dismissible(
      key: ValueKey(tasting.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref),
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
        leading: Icon(
          tasting.hadReaction
              ? Icons.warning_amber
              : tasting.liking?.icon ?? Icons.restaurant_outlined,
          color: context.appColor(
            tasting.hadReaction ? AppColors.warning : AppColors.textSecondary,
          ),
        ),
        title: Text(formatDayAndTime(tasting.at)),
        subtitle: details.isEmpty ? null : Text(details),
        onTap: () =>
            showTastingFormSheet(context, food: food, tasting: tasting),
      ),
    );
  }
}
