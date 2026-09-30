import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_reminder.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/colette_card_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

/// Interrupteur du rappel photo quotidien, propre à cet iPhone.
class PhotoReminderSwitch extends ConsumerWidget {
  const PhotoReminderSwitch({super.key});

  Future<void> _set(BuildContext context, WidgetRef ref, bool enabled) async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(photoReminderEnabledProvider.notifier)
        .set(enabled);
    if (result case Left(:final value)) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(value, s))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final enabled = ref.watch(photoReminderEnabledProvider).value ?? true;
    return ColetteCardSurface(
      padding: AppSpacing.sm.all,
      child: SwitchListTile(
        contentPadding: AppSpacing.sm.horizontal,
        title: Text(s.photoReminderSetting, style: styles.body),
        subtitle: Text(
          s.photoReminderSettingSubtitle,
          style: styles.small.copyWith(
            color: context.appColor(AppColors.textSecondary),
          ),
        ),
        value: enabled,
        onChanged: (value) => _set(context, ref, value),
      ),
    );
  }
}
