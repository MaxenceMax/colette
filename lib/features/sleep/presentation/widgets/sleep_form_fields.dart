import 'package:colette/core/dates/time_format.dart';
import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/core/theme/design_tokens.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/ui/widgets/date_field.dart';
import 'package:flutter/material.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// « 14h32 » le jour même, sinon « lun. 21 sept., 14h32 ».
String _formatFor(DateTime time, DateTime now) =>
    _isSameDay(time, now) ? formatHourMinute(time) : formatDayAndTime(time);

/// Champs de début et de fin, empilés pour rester lisibles en Dynamic Type.
class SleepDatesSection extends StatelessWidget {
  const SleepDatesSection({
    super.key,
    required this.startAt,
    required this.endAt,
    required this.now,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime startAt;
  final DateTime? endAt;
  final DateTime now;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        DateField(
          label: s.fieldStartAt,
          value: _formatFor(startAt, now),
          onTap: onPickStart,
        ),
        AppSpacing.sm.verticalSpace,
        DateField(
          label: s.fieldEndAt,
          value: switch (endAt) {
            null => s.sleepOngoing,
            final end => _formatFor(end, now),
          },
          onTap: onPickEnd,
        ),
      ],
    );
  }
}

/// Bouton Enregistrer, et Supprimer en édition.
class SleepActionsSection extends StatelessWidget {
  const SleepActionsSection({
    super.key,
    required this.isEditing,
    required this.isLoading,
    required this.onSave,
    required this.onDelete,
  });

  final bool isEditing;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      children: [
        FilledButton(
          onPressed: isLoading ? null : onSave,
          child: Text(s.actionSave),
        ),
        if (isEditing) ...[
          AppSpacing.sm.verticalSpace,
          TextButton(
            onPressed: isLoading ? null : onDelete,
            style: TextButton.styleFrom(
              foregroundColor: context.appColor(AppColors.error),
            ),
            child: Text(s.actionDelete),
          ),
        ],
      ],
    );
  }
}
