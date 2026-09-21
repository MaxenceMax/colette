import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/core/theme/text_styles.dart';
import 'package:colette/features/dashboard/domain/entities/care_task.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/care_type_ui.dart';
import 'package:flutter/material.dart';

/// Ligne « à faire » : icône, libellé, état ; tap = enregistrer le soin.
class CareTaskRow extends StatelessWidget {
  const CareTaskRow({super.key, required this.task, required this.onTap});

  final CareTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final styles = Theme.of(context).coletteTextStyles;
    final done = task.isDone;
    final accent = context.appColor(task.type.color);
    final muted = context.appColor(AppColors.textSecondary);
    return Material(
      color: context.appColor(
        done ? AppColors.pageBackground : AppColors.primaryContainer,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md.circular,
        side: done
            ? BorderSide(color: context.appColor(AppColors.border))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            spacing: AppSpacing.sm.value,
            children: [
              Icon(task.type.icon, color: done ? muted : accent),
              Expanded(
                child: Text(
                  task.type.label(s),
                  style: styles.bodyMedium.copyWith(
                    color: done ? muted : context.appColor(AppColors.onSurface),
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (task.target > 1)
                Text(
                  '${task.done}/${task.target}',
                  style: styles.small.copyWith(color: muted),
                ),
              if ((done, task.lastDoneAt) case (true, final at?))
                Text(
                  s.doneAt(formatHourMinute(at)),
                  style: styles.small.copyWith(
                    color: context.appColor(AppColors.success),
                  ),
                ),
              Icon(
                done
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                color: done
                    ? context.appColor(AppColors.success)
                    : context.appColor(AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
