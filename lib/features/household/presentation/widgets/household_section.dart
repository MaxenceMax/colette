import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Code du foyer à partager et sortie du foyer.
class HouseholdSection extends ConsumerWidget {
  const HouseholdSection({super.key, required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    final s = S.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.copied)));
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.leaveHouseholdTitle),
        content: Text(s.leaveHouseholdBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.settingsLeaveHousehold),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(leaveHouseholdControllerProvider.notifier).leave();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garde le contrôleur autoDispose vivant pendant l'await de leave().
    final leaving = ref.watch(leaveHouseholdControllerProvider).isLoading;
    final deviceLabel = ref.watch(currentDeviceProvider).value?.label;
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    return ColetteCardSurface(
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.sm.value,
        children: [
          Text(
            s.settingsHouseholdCode,
            style: styles.label.copyWith(
              color: context.appColor(AppColors.textSecondary),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: styles.numberMedium.copyWith(
                    color: context.appColor(AppColors.primary),
                    letterSpacing: AppSpacing.xxs.value,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_outlined),
                label: Text(s.actionCopy),
              ),
            ],
          ),
          if (deviceLabel != null)
            Text(
              '${s.fieldDeviceLabel} : $deviceLabel',
              style: styles.body.copyWith(
                color: context.appColor(AppColors.textSecondary),
              ),
            ),
          const Divider(),
          TextButton.icon(
            onPressed: leaving ? null : () => _leave(context, ref),
            icon: Icon(Icons.logout, color: context.appColor(AppColors.error)),
            label: Text(
              s.settingsLeaveHousehold,
              style: styles.bodyMedium.copyWith(
                color: context.appColor(AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
